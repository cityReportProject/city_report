# Plano: telas restantes do app de reportes urbanos

> Documento de planejamento técnico. Atualizado em 25/06/2026.

## Contexto

O time já está em desenvolvimento incremental do app: as telas de Mapa Principal, filtros, "Próximos a Você", destaque de credibilidade e Perfil expandido (estatísticas, Meus Reportes, modo noturno) já foram implementadas e estão commitadas/pushadas em `dev` (commit `f279b07`). Este plano cobre o que falta para fechar o conjunto completo de telas descrito nos protótipos (`prototipo_base/`) e nas 23 histórias de usuário (`agents/WIKI.md`).

## Já implementado (sem ação necessária)

| Tela/Componente | Arquivo |
|---|---|
| Mapa Principal (pins, filtros, dock, legenda) | `mobile/mobile/screens/MapScreenView.swift` |
| Detalhe rápido / votar / compartilhar | `mobile/mobile/screens/ReportQuickLookView.swift` |
| Próximos a Você (ordenado por distância) | `mobile/mobile/screens/NearbyReportsView.swift` |
| Perfil (estatísticas, Meus Reportes, modo noturno) | `mobile/mobile/screens/ProfileView.swift` |
| Lista simples, Detalhe completo (editar/resolver/excluir), Criar, Editar | ainda dentro de `mobile/mobile/ContentView.swift` |
| Models/Services existentes reaproveitáveis | `Report`, `ReportLocation`, `ReportCategory`, `UrgencyLevel`, `ReportStatus`, `UserProfile`, `VoteRegistry`, `MyReportsRegistry` (Models/); `ReportService`, `UserProfileService`, `VoteRegistryService`, `MyReportsRegistryService` (services/) |

## Trabalho planejado

### 1. LocationManager + GPS real (bloco principal)

Hoje há 3 placeholders explícitos: o botão de localização do mapa só reseta a câmera (`MapScreenView.swift:140-142`), "Próximos a Você" usa o centróide dos próprios reportes como referência de distância (`NearbyReportsView.swift:30-35`, comentado no código), e `CreateReportView` (dentro de `ContentView.swift:305-386`) captura latitude/longitude via `TextField` manual.

**Novo arquivo `mobile/mobile/services/LocationManager.swift`** — `@MainActor final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate`, singleton (`static let shared`), publica `currentLocation: CLLocationCoordinate2D?` e `authorizationStatus`. Delegate methods `nonisolated` saltando para `Task { @MainActor in }` (padrão correto de concorrência para o SDK atual). Usa `requestLocation()` (uma leitura, não tracking contínuo) — suficiente para "centralizar mapa" e "ordenar por proximidade".

**Passo manual bloqueante (não pode ser feito por edição de texto):** o projeto usa `GENERATE_INFOPLIST_FILE = YES` sem Info.plist físico — a chave `NSLocationWhenInUseUsageDescription` precisa ser adicionada via **Xcode → target mobile → aba Info → Custom iOS Target Properties → "Privacy - Location When In Use Usage Description"**. Sem isso, qualquer chamada a `requestWhenInUseAuthorization()` mata o processo. Fazer isso pela UI do Xcode evita editar o `.pbxproj` manualmente em duas seções (Debug/Release) e arriscar corromper a sintaxe.

**Conectar nos 3 pontos (mudança mínima em cada):**
- `MapScreenView.swift`: botão de localização chama `locationManager.requestLocation()`; um `.onChange(of: locationManager.currentLocation)` move a câmera via `MKCoordinateRegion` quando o valor chega.
- `NearbyReportsView.swift`: `referenceCoordinate` passa a tentar `locationManager.currentLocation` primeiro, caindo para o centróide existente se `nil` (preserva a robustez já implementada, só acrescenta uma camada acima).
- `CreateReportView`: substitui os `TextField` de lat/lng por um novo componente `mobile/mobile/screens/LocationPickerView.swift` (mapa + pin fixo no centro + arraste o mapa pra ajustar + geocoding reverso via `CLGeocoder` pro endereço). Vale extrair como componente próprio (não inline) porque já há reuso concreto à vista — `EditReportView` hoje só edita endereço como texto, e editar localização de um reporte existente é extensão natural depois.

**Fallback se a permissão for negada:** nenhuma tela trava — `currentLocation` é opcional, cada tela já tem (ou ganha) um caminho sem GPS (mapa fica no estado atual, "Próximos" usa centróide, formulário mantém a coordenada-base inicial pro usuário ajustar manualmente arrastando o mapa). Sem tela de erro dedicada, consistente com o padrão já usado pra erros de rede no projeto.

**Ordem de implementação:** (1) permissão no Xcode, (2) `LocationManager.swift`, (3) `NearbyReportsView` (mudança mais isolada/fácil de validar), (4) `MapScreenView`, (5) `LocationPickerView` + `CreateReportView` (mais trabalhoso, por último).

### 2. Tela de Confirmação (gap encontrado, não estava na lista de tarefas anterior)

US06 exige uma tela de confirmação com número de protocolo, resumo (categoria/urgência/endereço) e botão "Ver no mapa" — isso existe no protótipo (`Mapa Principal.dc.html`, tela "Confirmação") mas **não existe no código**: hoje `CreateReportView.save()` só chama `onCreated(created)` e `dismiss()` direto, sem mostrar nada.

**Novo arquivo `mobile/mobile/screens/ReportConfirmationView.swift`** — tela simples: ícone de sucesso, "Reporte enviado!", card com protocolo + badges de categoria/urgência + endereço, botão "Ver no mapa".

Em `CreateReportView`: trocar `dismiss()` por `@State private var createdReport: Report?` setado após o `create()` ter sucesso; o `body` passa a renderizar condicionalmente `ReportConfirmationView(report:onDone:)` em vez do `Form` quando `createdReport != nil`. O botão "Ver no mapa" chama `dismiss()` (o app já mostra o mapa por trás, já que `CreateReportView` é apresentada como sheet sobre ele).

### 3. Notificações (tela + preferências locais)

Sem backend de push (US20-BE não existe), então o escopo aqui é: solicitar permissão de `UNUserNotificationCenter` e construir uma tela de histórico **com dados reais, não fabricados** — em vez de inventar notificações falsas, a lista deriva dos reportes do próprio dispositivo (`MyReportsRegistryService.isMine`) que estão com `status == .resolved`, framed como "seu reporte foi resolvido". Isso é honesto sobre a limitação: o usuário só vê isso ao abrir o app, não recebe push real em background — esse limite deve ficar explícito no código (comentário) quando implementado.

Novo arquivo `mobile/mobile/screens/NotificationsView.swift`.

### 4. Papel funcionário / painel de gestão (E4) — decisão de produto pendente

Nenhum protótipo mostra como diferenciar cidadão de funcionário, e o app não tem autenticação. Antes de implementar, o time precisa decidir o mecanismo — opções possíveis: (a) toggle local "modo funcionário" no Perfil só pra demonstração, (b) lista fixa de deviceIDs autorizados, ou (c) deixar de fora do MVP.

### 5. Cleanup opcional: mover telas restantes para `screens/`

`ReportsListView`, `ReportRowView`, `ReportDetailView`, `CreateReportView`, `EditReportView`, `UrgencyBadge`, `StatusBadge` ainda moram em `ContentView.swift`, enquanto `screens/` foi estabelecida como a pasta padrão. Vale aproveitar o momento em que `CreateReportView` for reescrita (item 1) pra já extraí-la pra `screens/CreateReportView.swift`, e mover as demais depois, sem pressa — é reorganização mecânica de baixo risco, não bloqueia nada.

## Arquivos críticos

- `mobile/mobile/services/LocationManager.swift` (novo)
- `mobile/mobile/screens/LocationPickerView.swift` (novo)
- `mobile/mobile/screens/ReportConfirmationView.swift` (novo)
- `mobile/mobile/screens/NotificationsView.swift` (novo)
- `mobile/mobile/screens/MapScreenView.swift` (editar botão de localização)
- `mobile/mobile/screens/NearbyReportsView.swift` (editar `referenceCoordinate`)
- `mobile/mobile/ContentView.swift` (editar `CreateReportView`)
- `mobile.xcodeproj/project.pbxproj` (build setting de permissão — via Xcode UI, não edição direta)

## Verificação

Cada incremento precisa ser aberto e testado no Xcode antes do próximo (nenhuma máquina Windows/WSL do time consegue compilar isso — precisa de um Mac com Xcode). Pontos específicos a testar manualmente: prompt de permissão de localização aparece na primeira execução; botão de localização no mapa centraliza de verdade; "Próximos a Você" reordena quando a localização real chega; criar um reporte mostra a tela de Confirmação com protocolo correto; negar a permissão de localização não trava nenhuma das 3 telas.
