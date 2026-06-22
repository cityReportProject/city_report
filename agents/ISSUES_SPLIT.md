# Issues do Projeto (Frontend + Backend) — Aplicativo de Reportes Urbanos

> Cada história de usuário (US01–US23) dividida em issues de **frontend (SwiftUI)** e **backend (API)**.
> Histórias puramente locais (perfil no dispositivo) não têm backend e estão marcadas como _frontend-only_.
> Para criar tudo automaticamente, execute `bash create_issues_split.sh` com o GitHub CLI.

---

## Convenção de divisão

| Camada | Responsabilidade |
|---|---|
| **Frontend (FE)** | Telas SwiftUI, ViewModels, navegação, validação de UI, formatação, integração com MapKit/CoreLocation, consumo da API |
| **Backend (BE)** | Endpoints REST, persistência, regras de negócio, geração de protocolo, contagem de votos, envio de push |

---

## Labels adicionais

Além das labels já existentes, criar:

| Label | Cor | Descrição |
|---|---|---|
| `area/frontend` | `#378ADD` | Tarefa de frontend (SwiftUI) |
| `area/backend` | `#1D9E75` | Tarefa de backend (API) |

---

## Resumo da divisão

| US | Frontend | Backend |
|---|---|---|
| US01 Localização GPS | ✅ FE | — (local) |
| US02 Localização manual | ✅ FE | — (local) |
| US03 Descrição | ✅ FE | — |
| US04 Categoria | ✅ FE | — |
| US05 Urgência | ✅ FE | — |
| US06 Confirmação de envio | ✅ FE | ✅ BE (criar reporte + protocolo) |
| US07 Mapa de reportes | ✅ FE | ✅ BE (listar reportes) |
| US08 Detalhes do reporte | ✅ FE | ✅ BE (obter reporte por id) |
| US09 Filtro por categoria | ✅ FE | — (filtro client-side) |
| US10 Filtro por status | ✅ FE | — (filtro client-side) |
| US11 Reportes próximos | ✅ FE | ✅ BE (busca por raio/geo) |
| US12 Votar | ✅ FE | ✅ BE (registrar/remover voto) |
| US13 Score de credibilidade | ✅ FE | ✅ BE (expor contagem) |
| US14 Destaque por credibilidade | ✅ FE | — (client-side) |
| US15 Painel prefeitura | ✅ FE | ✅ BE (listar abertos) |
| US16 Resolver reporte | ✅ FE | ✅ BE (atualizar status + push) |
| US17 Filtro urgência (pref.) | ✅ FE | — (client-side) |
| US18 Filtro categoria (pref.) | ✅ FE | — (client-side) |
| US19 Localização (pref.) | ✅ FE | — |
| US20 Push ao resolver | ✅ FE | ✅ BE (enviar push) |
| US21 Preferências de notificação | ✅ FE | — (local) |
| US22 Histórico de reportes | ✅ FE | ✅ BE (listar por dispositivo) |
| US23 Editar perfil | ✅ FE | — (local) |

**Total:** 23 issues de frontend + 11 issues de backend = **34 issues**

---

## E1 — Criação de Reporte

### [US01-FE] Reporte com localização por GPS — Frontend
**Labels:** `user-story` `epic/criação` `role/cidadao` `area/frontend` `sprint/1`

**Tarefas**
- [ ] Solicitar permissão de localização via `CLLocationManager` na primeira utilização
- [ ] Ativar GPS e capturar a localização atual ao abrir o formulário
- [ ] Exibir pin no mapa (`Map` do MapKit) na localização detectada
- [ ] Permitir ajuste manual do pin após detecção
- [ ] Tratar GPS indisponível com mensagem de erro e fallback para seleção manual (US02)

> Sem backend: a localização é capturada no dispositivo e só é enviada junto ao reporte (US06-BE).

---

### [US02-FE] Definir localização manual no mapa — Frontend
**Labels:** `user-story` `epic/criação` `role/cidadao` `area/frontend` `sprint/1`

**Tarefas**
- [ ] Mapa interativo com pin arrastável
- [ ] Campo de busca de endereço com autocompletar (`MKLocalSearchCompleter`)
- [ ] Geocodificação reversa do pin para exibir o endereço (`CLGeocoder`)
- [ ] Confirmar localização antes de prosseguir

> Sem backend: geocodificação usa serviços nativos da Apple.

---

### [US03-FE] Adicionar descrição ao reporte — Frontend
**Labels:** `user-story` `epic/criação` `role/cidadao` `area/frontend` `sprint/1`

**Tarefas**
- [ ] `TextField`/`TextEditor` com limite de 10–500 caracteres
- [ ] Contador de caracteres restantes
- [ ] Validação de campo obrigatório
- [ ] Foco automático e abertura do teclado

---

### [US04-FE] Selecionar categoria do problema — Frontend
**Labels:** `user-story` `epic/criação` `role/cidadao` `area/frontend` `sprint/1`

**Tarefas**
- [ ] Picker/grid de categorias a partir de `ReportCategory.allCases`
- [ ] Ícone SF Symbol por categoria (`category.icon`)
- [ ] Seleção única e obrigatória

---

### [US05-FE] Definir nível de urgência — Frontend
**Labels:** `user-story` `epic/criação` `role/cidadao` `area/frontend` `sprint/1`

**Tarefas**
- [ ] Seletor de urgência (`UrgencyLevel.allCases`) com cores
- [ ] Exibir dica (`urgency.hint`) por nível
- [ ] Seleção obrigatória; refletir cor no pin

---

### [US06-FE] Confirmação de envio do reporte — Frontend
**Labels:** `user-story` `epic/criação` `role/cidadao` `area/frontend` `sprint/1`

**Tarefas**
- [ ] Chamar endpoint de criação (US06-BE) e tratar resposta
- [ ] Tela de confirmação com número de protocolo retornado
- [ ] Resumo (categoria, urgência, endereço)
- [ ] Botão "Ver no mapa"; novo pin aparece imediatamente
- [ ] Tratar erro de rede com opção de tentar novamente

**Depende de:** US06-BE

---

### [US06-BE] Criar reporte e gerar protocolo — Backend
**Labels:** `user-story` `epic/criação` `area/backend` `sprint/1`

**Tarefas**
- [ ] `POST /reports` recebendo descrição, categoria, urgência e localização
- [ ] Validar payload (campos obrigatórios, tamanho da descrição)
- [ ] Gerar número de protocolo único
- [ ] Persistir reporte com status `Aberto` e `voteCount = 0`
- [ ] Retornar o reporte criado (com `id` e `protocolNumber`)

**Contrato:** `Report` (Codable)

---

## E2 — Mapa e Visualização

### [US07-FE] Visualizar reportes no mapa — Frontend
**Labels:** `user-story` `epic/mapa` `role/cidadao` `area/frontend` `sprint/1`

**Tarefas**
- [ ] Consumir US07-BE e renderizar pins no `Map`
- [ ] Cor do pin por urgência; ícone por categoria
- [ ] Exibir apenas status `Aberto` por padrão
- [ ] Centralizar na localização atual ao abrir

**Depende de:** US07-BE

---

### [US07-BE] Listar reportes — Backend
**Labels:** `user-story` `epic/mapa` `area/backend` `sprint/1`

**Tarefas**
- [ ] `GET /reports` retornando todos os reportes ativos
- [ ] Suportar parâmetro opcional de status
- [ ] Paginação ou bounding-box para performance (opcional no MVP)

**Contrato:** `[Report]`

---

### [US08-FE] Ver detalhes de um reporte — Frontend
**Labels:** `user-story` `epic/mapa` `role/cidadao` `area/frontend` `sprint/1`

**Tarefas**
- [ ] Card de detalhes ao tocar no pin
- [ ] Exibir categoria, urgência, descrição, data e status
- [ ] Exibir score de credibilidade e total de votos
- [ ] Botão de voto (integra com US12-FE)

**Depende de:** US08-BE

---

### [US08-BE] Obter reporte por id — Backend
**Labels:** `user-story` `epic/mapa` `area/backend` `sprint/1`

**Tarefas**
- [ ] `GET /reports/{id}` retornando o reporte completo
- [ ] Incluir `voteCount` atualizado
- [ ] Retornar 404 quando não encontrado

**Contrato:** `Report`

---

### [US09-FE] Filtrar reportes por categoria — Frontend
**Labels:** `user-story` `epic/mapa` `role/cidadao` `area/frontend` `sprint/2`

**Tarefas**
- [ ] Menu de filtro com seleção múltipla de categorias
- [ ] Filtro aplicado client-side sobre a lista carregada
- [ ] Indicador de filtro ativo e botão de limpar

> Sem backend: filtragem feita no cliente sobre os dados de US07.

---

### [US10-FE] Filtrar reportes por status — Frontend
**Labels:** `user-story` `epic/mapa` `role/cidadao` `area/frontend` `sprint/2`

**Tarefas**
- [ ] Toggle Abertos / Resolvidos / Todos
- [ ] Padrão: apenas abertos
- [ ] Visual diferenciado para resolvidos

> Sem backend: filtragem client-side (ou reutiliza parâmetro de US07-BE).

---

### [US11-FE] Lista de reportes próximos — Frontend
**Labels:** `user-story` `epic/mapa` `role/cidadao` `area/frontend` `sprint/2`

**Tarefas**
- [ ] Lista ordenada por distância (calculada com a localização do usuário)
- [ ] Item com categoria, urgência, distância e data
- [ ] Toque centraliza o mapa e abre detalhes
- [ ] Controle de raio (padrão 5 km)

**Depende de:** US11-BE

---

### [US11-BE] Buscar reportes por proximidade — Backend
**Labels:** `user-story` `epic/mapa` `area/backend` `sprint/2`

**Tarefas**
- [ ] `GET /reports/nearby?lat=&lng=&radius=` com filtro geográfico
- [ ] Calcular distância e retornar ordenado por proximidade
- [ ] Validar coordenadas e raio

**Contrato:** `[Report]` (opcionalmente com campo de distância)

---

## E3 — Credibilidade e Votação

### [US12-FE] Votar em um reporte — Frontend
**Labels:** `user-story` `epic/credibilidade` `role/cidadao` `area/frontend` `sprint/2`

**Tarefas**
- [ ] Botão "Confirmo esse problema" no card
- [ ] Controle local via `VoteRegistry` (um voto por dispositivo)
- [ ] Chamar US12-BE para incrementar/decrementar
- [ ] Atualizar contagem imediatamente; permitir desfazer

**Depende de:** US08-FE, US12-BE

---

### [US12-BE] Registrar e remover voto — Backend
**Labels:** `user-story` `epic/credibilidade` `area/backend` `sprint/2`

**Tarefas**
- [ ] `POST /reports/{id}/vote` incrementa `voteCount`
- [ ] `DELETE /reports/{id}/vote` decrementa `voteCount`
- [ ] Receber identificador de dispositivo para evitar voto duplicado no servidor
- [ ] Retornar `voteCount` atualizado

**Contrato:** `{ voteCount: Int }`

---

### [US13-FE] Ver score de credibilidade — Frontend
**Labels:** `user-story` `epic/credibilidade` `role/cidadao` `area/frontend` `sprint/2`

**Tarefas**
- [ ] Exibir número de votos no card e no mapa
- [ ] Barra de progresso proporcional
- [ ] Destaque visual para `isHighCredibility` (> 10 votos)

**Depende de:** US08-FE, US12-FE

---

### [US13-BE] Expor contagem de votos — Backend
**Labels:** `user-story` `epic/credibilidade` `area/backend` `sprint/2`

**Tarefas**
- [ ] Garantir `voteCount` presente nas respostas de `GET /reports` e `GET /reports/{id}`
- [ ] (Já coberto por US07-BE/US08-BE; esta issue valida consistência da contagem)

> Pode ser fechada como parte de US07-BE/US08-BE se a contagem já estiver exposta.

---

### [US14-FE] Destaque por credibilidade no mapa — Frontend
**Labels:** `user-story` `epic/credibilidade` `role/cidadao` `area/frontend` `sprint/2`

**Tarefas**
- [ ] Pins de alta credibilidade com tamanho/ícone diferenciado
- [ ] Filtro opcional "apenas acima de N votos"
- [ ] Ordenação por credibilidade na lista de próximos

> Sem backend: usa `voteCount` já disponível nos dados.

---

## E4 — Gestão de Reportes (Prefeitura)

### [US15-FE] Painel de reportes abertos — Frontend
**Labels:** `user-story` `epic/gestao` `role/funcionario` `area/frontend` `sprint/2`

**Tarefas**
- [ ] Tela de painel (lista + mapa) consumindo US15-BE
- [ ] Ordenação por urgência (alta primeiro)
- [ ] Item com categoria, urgência, data, credibilidade e endereço
- [ ] Contador total de abertos

**Depende de:** US15-BE

---

### [US15-BE] Listar reportes abertos (gestão) — Backend
**Labels:** `user-story` `epic/gestao` `area/backend` `sprint/2`

**Tarefas**
- [ ] `GET /reports?status=open` ordenável por urgência
- [ ] Retornar total de reportes abertos
- [ ] (Pode reutilizar US07-BE com parâmetros)

**Contrato:** `[Report]`

---

### [US16-FE] Marcar reporte como resolvido — Frontend
**Labels:** `user-story` `epic/gestao` `role/funcionario` `area/frontend` `sprint/2`

**Tarefas**
- [ ] Botão "Marcar como resolvido" nos detalhes
- [ ] Campo opcional de comentário de resolução
- [ ] Diálogo de confirmação
- [ ] Atualizar status na UI em tempo real

**Depende de:** US16-BE

---

### [US16-BE] Resolver reporte e disparar push — Backend
**Labels:** `user-story` `epic/gestao` `area/backend` `sprint/2`

**Tarefas**
- [ ] `PATCH /reports/{id}` alterando status para `Resolvido`
- [ ] Persistir `resolvedAt` e `resolutionComment`
- [ ] Acionar envio de push ao criador (integra com US20-BE)
- [ ] Retornar reporte atualizado

**Contrato:** `Report`
**Depende de:** US20-BE

---

### [US17-FE] Filtrar reportes por urgência (prefeitura) — Frontend
**Labels:** `user-story` `epic/gestao` `role/funcionario` `area/frontend` `sprint/3`

**Tarefas**
- [ ] Filtro por urgência (seleção múltipla)
- [ ] Contagem por nível
- [ ] Indicador de filtro ativo

> Sem backend: filtragem client-side sobre o painel.

---

### [US18-FE] Filtrar reportes por categoria (prefeitura) — Frontend
**Labels:** `user-story` `epic/gestao` `role/funcionario` `area/frontend` `sprint/3`

**Tarefas**
- [ ] Filtro por categoria (seleção múltipla)
- [ ] Combinável com filtro de urgência
- [ ] Atualização em tempo real

> Sem backend: filtragem client-side.

---

### [US19-FE] Ver localização do reporte no mapa (prefeitura) — Frontend
**Labels:** `user-story` `epic/gestao` `role/funcionario` `area/frontend` `sprint/3`

**Tarefas**
- [ ] Pin na localização ao abrir detalhes
- [ ] Endereço completo abaixo do mapa
- [ ] Botão "Abrir no Apple Maps"
- [ ] Exibir coordenadas (lat/lng)

> Sem backend: usa dados de localização já presentes no reporte.

---

## E5 — Notificações

### [US20-FE] Push notification ao resolver reporte — Frontend
**Labels:** `user-story` `epic/notificacoes` `role/cidadao` `area/frontend` `sprint/3`

**Tarefas**
- [ ] Solicitar permissão de notificação no onboarding
- [ ] Registrar device token e enviar ao backend
- [ ] Tratar tap na notificação abrindo o reporte (deep link)

**Depende de:** US20-BE

---

### [US20-BE] Enviar push ao criador — Backend
**Labels:** `user-story` `epic/notificacoes` `area/backend` `sprint/3`

**Tarefas**
- [ ] Endpoint para registrar device token por reporte/dispositivo
- [ ] Integração com APNs
- [ ] Enviar push ao resolver (acionado por US16-BE), com protocolo e categoria
- [ ] Payload com deep link para o reporte

---

### [US21-FE] Gerenciar preferências de notificação — Frontend
**Labels:** `user-story` `epic/notificacoes` `role/cidadao` `area/frontend` `sprint/3`

**Tarefas**
- [ ] Toggle on/off na tela de perfil, persistido em `UserProfile`
- [ ] Refletir mudança imediatamente
- [ ] Respeitar preferência ao registrar/agendar notificações

> Sem backend: preferência é local ao dispositivo.

---

## E6 — Perfil do Usuário

### [US22-FE] Histórico de reportes — Frontend
**Labels:** `user-story` `epic/perfil` `role/cidadao` `area/frontend` `sprint/3`

**Tarefas**
- [ ] Lista de reportes do dispositivo (ordem por data, mais recente primeiro)
- [ ] Status por item; número de protocolo visível
- [ ] Toque abre os detalhes completos

**Depende de:** US22-BE

---

### [US22-BE] Listar reportes por dispositivo — Backend
**Labels:** `user-story` `epic/perfil` `area/backend` `sprint/3`

**Tarefas**
- [ ] `GET /reports?deviceId=` retornando reportes criados pelo dispositivo
- [ ] Ordenar por data de criação (desc)
- [ ] Associar `deviceId` na criação (US06-BE)

**Contrato:** `[Report]`

---

### [US23-FE] Editar perfil — Frontend
**Labels:** `user-story` `epic/perfil` `role/cidadao` `area/frontend` `sprint/3`

**Tarefas**
- [ ] Campos editáveis: nome e e-mail, persistidos em `UserProfile`
- [ ] Validação de formato em tempo real (`isEmailValid`)
- [ ] Mensagem de confirmação ao salvar

> Sem backend: perfil é local ao dispositivo.
