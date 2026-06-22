#!/usr/bin/env bash
# create_issues_split.sh
# Cria as 34 issues do projeto (frontend + backend) via GitHub CLI (gh).
#
# Pré-requisitos:
#   brew install gh && gh auth login
#
# Uso (dentro da pasta do repositório):
#   bash create_issues_split.sh

set -e

echo "🏷️  Criando labels..."
gh label create "user-story"        --color "E24B4A" --description "Issue de história de usuário"      --force
gh label create "area/frontend"     --color "378ADD" --description "Tarefa de frontend (SwiftUI)"      --force
gh label create "area/backend"      --color "1D9E75" --description "Tarefa de backend (API)"           --force
gh label create "epic/criação"      --color "0F6E56" --description "E1 — Criação de Reporte"           --force
gh label create "epic/mapa"         --color "534AB7" --description "E2 — Mapa e Visualização"          --force
gh label create "epic/credibilidade" --color "993C1D" --description "E3 — Credibilidade e Votação"     --force
gh label create "epic/gestao"       --color "BA7517" --description "E4 — Gestão da Prefeitura"         --force
gh label create "epic/notificacoes" --color "993556" --description "E5 — Notificações"                 --force
gh label create "epic/perfil"       --color "5F5E5A" --description "E6 — Perfil do Usuário"            --force
gh label create "role/cidadao"      --color "185FA5" --description "Perfil: Cidadão"                   --force
gh label create "role/funcionario"  --color "3B6D11" --description "Perfil: Funcionário"              --force
gh label create "sprint/1"          --color "D3D1C7" --description "Sprint 1"                          --force
gh label create "sprint/2"          --color "B4B2A9" --description "Sprint 2"                          --force
gh label create "sprint/3"          --color "888780" --description "Sprint 3"                          --force
echo "✅ Labels criadas."

echo "📋 Criando milestones..."
gh api repos/:owner/:repo/milestones --method POST -f title="Sprint 1" -f description="E1 + E2 base" || true
gh api repos/:owner/:repo/milestones --method POST -f title="Sprint 2" -f description="E2 filtros + E3 + E4 core" || true
gh api repos/:owner/:repo/milestones --method POST -f title="Sprint 3" -f description="E4 filtros + E5 + E6" || true
echo "✅ Milestones criadas."

echo "🐛 Criando issues..."

# ─── E1 — Criação de Reporte ────────────────────────────────────────────────

gh issue create --title "[US01-FE] Localização por GPS — Frontend" \
  --label "user-story,epic/criação,role/cidadao,area/frontend,sprint/1" --milestone "Sprint 1" \
  --body "## 📱 Frontend (SwiftUI)
- [ ] Solicitar permissão de localização via \`CLLocationManager\`
- [ ] Capturar localização atual ao abrir o formulário
- [ ] Exibir pin no \`Map\` na localização detectada
- [ ] Permitir ajuste manual do pin
- [ ] Fallback para seleção manual se GPS indisponível"

gh issue create --title "[US02-FE] Localização manual no mapa — Frontend" \
  --label "user-story,epic/criação,role/cidadao,area/frontend,sprint/1" --milestone "Sprint 1" \
  --body "## 📱 Frontend (SwiftUI)
- [ ] Mapa interativo com pin arrastável
- [ ] Busca de endereço com \`MKLocalSearchCompleter\`
- [ ] Geocodificação reversa com \`CLGeocoder\`
- [ ] Confirmar localização antes de prosseguir"

gh issue create --title "[US03-FE] Descrição do reporte — Frontend" \
  --label "user-story,epic/criação,role/cidadao,area/frontend,sprint/1" --milestone "Sprint 1" \
  --body "## 📱 Frontend (SwiftUI)
- [ ] \`TextEditor\` com limite de 10–500 caracteres
- [ ] Contador de caracteres restantes
- [ ] Validação de campo obrigatório
- [ ] Foco automático e abertura do teclado"

gh issue create --title "[US04-FE] Selecionar categoria — Frontend" \
  --label "user-story,epic/criação,role/cidadao,area/frontend,sprint/1" --milestone "Sprint 1" \
  --body "## 📱 Frontend (SwiftUI)
- [ ] Grid de categorias a partir de \`ReportCategory.allCases\`
- [ ] Ícone SF Symbol por categoria
- [ ] Seleção única e obrigatória"

gh issue create --title "[US05-FE] Definir urgência — Frontend" \
  --label "user-story,epic/criação,role/cidadao,area/frontend,sprint/1" --milestone "Sprint 1" \
  --body "## 📱 Frontend (SwiftUI)
- [ ] Seletor de \`UrgencyLevel.allCases\` com cores
- [ ] Exibir dica (\`urgency.hint\`) por nível
- [ ] Seleção obrigatória; refletir cor no pin"

gh issue create --title "[US06-FE] Confirmação de envio — Frontend" \
  --label "user-story,epic/criação,role/cidadao,area/frontend,sprint/1" --milestone "Sprint 1" \
  --body "## 📱 Frontend (SwiftUI)
- [ ] Chamar \`POST /reports\` (US06-BE) e tratar resposta
- [ ] Tela de confirmação com número de protocolo
- [ ] Resumo (categoria, urgência, endereço)
- [ ] Botão \"Ver no mapa\"; novo pin imediato
- [ ] Tratar erro de rede com retry

🔗 Depende de US06-BE"

gh issue create --title "[US06-BE] Criar reporte e gerar protocolo — Backend" \
  --label "user-story,epic/criação,area/backend,sprint/1" --milestone "Sprint 1" \
  --body "## 🗄️ Backend (API)
- [ ] \`POST /reports\` (descrição, categoria, urgência, localização)
- [ ] Validar payload
- [ ] Gerar número de protocolo único
- [ ] Persistir com status \`Aberto\` e \`voteCount = 0\`
- [ ] Retornar reporte criado

**Contrato:** \`Report\` (Codable)"

# ─── E2 — Mapa e Visualização ───────────────────────────────────────────────

gh issue create --title "[US07-FE] Mapa de reportes — Frontend" \
  --label "user-story,epic/mapa,role/cidadao,area/frontend,sprint/1" --milestone "Sprint 1" \
  --body "## 📱 Frontend (SwiftUI)
- [ ] Consumir \`GET /reports\` (US07-BE) e renderizar pins
- [ ] Cor do pin por urgência; ícone por categoria
- [ ] Exibir apenas \`Aberto\` por padrão
- [ ] Centralizar na localização atual

🔗 Depende de US07-BE"

gh issue create --title "[US07-BE] Listar reportes — Backend" \
  --label "user-story,epic/mapa,area/backend,sprint/1" --milestone "Sprint 1" \
  --body "## 🗄️ Backend (API)
- [ ] \`GET /reports\` com todos os reportes ativos
- [ ] Parâmetro opcional de status
- [ ] Bounding-box/paginação (opcional no MVP)

**Contrato:** \`[Report]\`"

gh issue create --title "[US08-FE] Detalhes do reporte — Frontend" \
  --label "user-story,epic/mapa,role/cidadao,area/frontend,sprint/1" --milestone "Sprint 1" \
  --body "## 📱 Frontend (SwiftUI)
- [ ] Card de detalhes ao tocar no pin
- [ ] Categoria, urgência, descrição, data e status
- [ ] Score de credibilidade e total de votos
- [ ] Botão de voto (US12-FE)

🔗 Depende de US08-BE"

gh issue create --title "[US08-BE] Obter reporte por id — Backend" \
  --label "user-story,epic/mapa,area/backend,sprint/1" --milestone "Sprint 1" \
  --body "## 🗄️ Backend (API)
- [ ] \`GET /reports/{id}\` com reporte completo
- [ ] Incluir \`voteCount\` atualizado
- [ ] 404 quando não encontrado

**Contrato:** \`Report\`"

gh issue create --title "[US09-FE] Filtro por categoria — Frontend" \
  --label "user-story,epic/mapa,role/cidadao,area/frontend,sprint/2" --milestone "Sprint 2" \
  --body "## 📱 Frontend (SwiftUI)
- [ ] Menu de filtro com seleção múltipla
- [ ] Filtragem client-side sobre a lista carregada
- [ ] Indicador de filtro ativo e botão limpar"

gh issue create --title "[US10-FE] Filtro por status — Frontend" \
  --label "user-story,epic/mapa,role/cidadao,area/frontend,sprint/2" --milestone "Sprint 2" \
  --body "## 📱 Frontend (SwiftUI)
- [ ] Toggle Abertos / Resolvidos / Todos
- [ ] Padrão: apenas abertos
- [ ] Visual diferenciado para resolvidos"

gh issue create --title "[US11-FE] Reportes próximos — Frontend" \
  --label "user-story,epic/mapa,role/cidadao,area/frontend,sprint/2" --milestone "Sprint 2" \
  --body "## 📱 Frontend (SwiftUI)
- [ ] Lista ordenada por distância
- [ ] Item com categoria, urgência, distância e data
- [ ] Toque centraliza o mapa e abre detalhes
- [ ] Controle de raio (padrão 5 km)

🔗 Depende de US11-BE"

gh issue create --title "[US11-BE] Buscar reportes por proximidade — Backend" \
  --label "user-story,epic/mapa,area/backend,sprint/2" --milestone "Sprint 2" \
  --body "## 🗄️ Backend (API)
- [ ] \`GET /reports/nearby?lat=&lng=&radius=\`
- [ ] Calcular distância e ordenar por proximidade
- [ ] Validar coordenadas e raio

**Contrato:** \`[Report]\`"

# ─── E3 — Credibilidade e Votação ───────────────────────────────────────────

gh issue create --title "[US12-FE] Votar em um reporte — Frontend" \
  --label "user-story,epic/credibilidade,role/cidadao,area/frontend,sprint/2" --milestone "Sprint 2" \
  --body "## 📱 Frontend (SwiftUI)
- [ ] Botão \"Confirmo esse problema\" no card
- [ ] Controle local via \`VoteRegistry\` (1 voto/dispositivo)
- [ ] Chamar US12-BE para incrementar/decrementar
- [ ] Atualizar contagem na hora; permitir desfazer

🔗 Depende de US08-FE, US12-BE"

gh issue create --title "[US12-BE] Registrar e remover voto — Backend" \
  --label "user-story,epic/credibilidade,area/backend,sprint/2" --milestone "Sprint 2" \
  --body "## 🗄️ Backend (API)
- [ ] \`POST /reports/{id}/vote\` incrementa
- [ ] \`DELETE /reports/{id}/vote\` decrementa
- [ ] Receber \`deviceId\` para evitar voto duplicado
- [ ] Retornar \`voteCount\` atualizado

**Contrato:** \`{ voteCount: Int }\`"

gh issue create --title "[US13-FE] Score de credibilidade — Frontend" \
  --label "user-story,epic/credibilidade,role/cidadao,area/frontend,sprint/2" --milestone "Sprint 2" \
  --body "## 📱 Frontend (SwiftUI)
- [ ] Exibir número de votos no card e no mapa
- [ ] Barra de progresso proporcional
- [ ] Destaque para \`isHighCredibility\` (> 10 votos)

🔗 Depende de US08-FE, US12-FE"

gh issue create --title "[US13-BE] Expor contagem de votos — Backend" \
  --label "user-story,epic/credibilidade,area/backend,sprint/2" --milestone "Sprint 2" \
  --body "## 🗄️ Backend (API)
- [ ] Garantir \`voteCount\` em \`GET /reports\` e \`GET /reports/{id}\`
- [ ] Validar consistência da contagem

> Pode ser fechada junto a US07-BE/US08-BE se já exposto."

gh issue create --title "[US14-FE] Destaque por credibilidade no mapa — Frontend" \
  --label "user-story,epic/credibilidade,role/cidadao,area/frontend,sprint/2" --milestone "Sprint 2" \
  --body "## 📱 Frontend (SwiftUI)
- [ ] Pins de alta credibilidade diferenciados
- [ ] Filtro opcional \"acima de N votos\"
- [ ] Ordenação por credibilidade na lista de próximos"

# ─── E4 — Gestão (Prefeitura) ───────────────────────────────────────────────

gh issue create --title "[US15-FE] Painel de reportes abertos — Frontend" \
  --label "user-story,epic/gestao,role/funcionario,area/frontend,sprint/2" --milestone "Sprint 2" \
  --body "## 📱 Frontend (SwiftUI)
- [ ] Painel (lista + mapa) consumindo US15-BE
- [ ] Ordenação por urgência (alta primeiro)
- [ ] Item com categoria, urgência, data, credibilidade, endereço
- [ ] Contador total de abertos

🔗 Depende de US15-BE"

gh issue create --title "[US15-BE] Listar reportes abertos (gestão) — Backend" \
  --label "user-story,epic/gestao,area/backend,sprint/2" --milestone "Sprint 2" \
  --body "## 🗄️ Backend (API)
- [ ] \`GET /reports?status=open\` ordenável por urgência
- [ ] Retornar total de abertos
- [ ] Pode reutilizar US07-BE com parâmetros

**Contrato:** \`[Report]\`"

gh issue create --title "[US16-FE] Marcar como resolvido — Frontend" \
  --label "user-story,epic/gestao,role/funcionario,area/frontend,sprint/2" --milestone "Sprint 2" \
  --body "## 📱 Frontend (SwiftUI)
- [ ] Botão \"Marcar como resolvido\" nos detalhes
- [ ] Campo opcional de comentário
- [ ] Diálogo de confirmação
- [ ] Atualizar status na UI em tempo real

🔗 Depende de US16-BE"

gh issue create --title "[US16-BE] Resolver reporte e disparar push — Backend" \
  --label "user-story,epic/gestao,area/backend,sprint/2" --milestone "Sprint 2" \
  --body "## 🗄️ Backend (API)
- [ ] \`PATCH /reports/{id}\` status → \`Resolvido\`
- [ ] Persistir \`resolvedAt\` e \`resolutionComment\`
- [ ] Acionar push ao criador (US20-BE)
- [ ] Retornar reporte atualizado

**Contrato:** \`Report\`
🔗 Depende de US20-BE"

gh issue create --title "[US17-FE] Filtro por urgência (prefeitura) — Frontend" \
  --label "user-story,epic/gestao,role/funcionario,area/frontend,sprint/3" --milestone "Sprint 3" \
  --body "## 📱 Frontend (SwiftUI)
- [ ] Filtro por urgência (seleção múltipla)
- [ ] Contagem por nível
- [ ] Indicador de filtro ativo"

gh issue create --title "[US18-FE] Filtro por categoria (prefeitura) — Frontend" \
  --label "user-story,epic/gestao,role/funcionario,area/frontend,sprint/3" --milestone "Sprint 3" \
  --body "## 📱 Frontend (SwiftUI)
- [ ] Filtro por categoria (seleção múltipla)
- [ ] Combinável com filtro de urgência
- [ ] Atualização em tempo real"

gh issue create --title "[US19-FE] Localização do reporte (prefeitura) — Frontend" \
  --label "user-story,epic/gestao,role/funcionario,area/frontend,sprint/3" --milestone "Sprint 3" \
  --body "## 📱 Frontend (SwiftUI)
- [ ] Pin na localização ao abrir detalhes
- [ ] Endereço completo abaixo do mapa
- [ ] Botão \"Abrir no Apple Maps\"
- [ ] Exibir coordenadas (lat/lng)"

# ─── E5 — Notificações ──────────────────────────────────────────────────────

gh issue create --title "[US20-FE] Push ao resolver — Frontend" \
  --label "user-story,epic/notificacoes,role/cidadao,area/frontend,sprint/3" --milestone "Sprint 3" \
  --body "## 📱 Frontend (SwiftUI)
- [ ] Solicitar permissão de notificação no onboarding
- [ ] Registrar device token e enviar ao backend
- [ ] Tap na notificação abre o reporte (deep link)

🔗 Depende de US20-BE"

gh issue create --title "[US20-BE] Enviar push ao criador — Backend" \
  --label "user-story,epic/notificacoes,area/backend,sprint/3" --milestone "Sprint 3" \
  --body "## 🗄️ Backend (API)
- [ ] Registrar device token por reporte/dispositivo
- [ ] Integração com APNs
- [ ] Enviar push ao resolver (via US16-BE) com protocolo e categoria
- [ ] Payload com deep link"

gh issue create --title "[US21-FE] Preferências de notificação — Frontend" \
  --label "user-story,epic/notificacoes,role/cidadao,area/frontend,sprint/3" --milestone "Sprint 3" \
  --body "## 📱 Frontend (SwiftUI)
- [ ] Toggle on/off no perfil, persistido em \`UserProfile\`
- [ ] Refletir mudança imediatamente
- [ ] Respeitar preferência ao agendar notificações

> Preferência local ao dispositivo (sem backend)."

# ─── E6 — Perfil ────────────────────────────────────────────────────────────

gh issue create --title "[US22-FE] Histórico de reportes — Frontend" \
  --label "user-story,epic/perfil,role/cidadao,area/frontend,sprint/3" --milestone "Sprint 3" \
  --body "## 📱 Frontend (SwiftUI)
- [ ] Lista de reportes do dispositivo (data desc)
- [ ] Status por item; protocolo visível
- [ ] Toque abre detalhes completos

🔗 Depende de US22-BE"

gh issue create --title "[US22-BE] Listar reportes por dispositivo — Backend" \
  --label "user-story,epic/perfil,area/backend,sprint/3" --milestone "Sprint 3" \
  --body "## 🗄️ Backend (API)
- [ ] \`GET /reports?deviceId=\`
- [ ] Ordenar por data de criação (desc)
- [ ] Associar \`deviceId\` na criação (US06-BE)

**Contrato:** \`[Report]\`"

gh issue create --title "[US23-FE] Editar perfil — Frontend" \
  --label "user-story,epic/perfil,role/cidadao,area/frontend,sprint/3" --milestone "Sprint 3" \
  --body "## 📱 Frontend (SwiftUI)
- [ ] Campos nome e e-mail, persistidos em \`UserProfile\`
- [ ] Validação de formato em tempo real (\`isEmailValid\`)
- [ ] Mensagem de confirmação ao salvar

> Perfil local ao dispositivo (sem backend)."

echo ""
echo "✅ 34 issues criadas (23 frontend + 11 backend)!"
