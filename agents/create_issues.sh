#!/usr/bin/env bash
# create_issues.sh
# Cria todas as 23 issues do projeto via GitHub CLI (gh).
#
# Pré-requisitos:
#   brew install gh
#   gh auth login
#
# Uso:
#   bash create_issues.sh
#
# As labels e milestones são criadas automaticamente antes das issues.

set -e

echo "🏷️  Criando labels..."

gh label create "user-story"       --color "E24B4A" --description "Issue originada de história de usuário" --force
gh label create "epic/criação"     --color "0F6E56" --description "E1 — Criação de Reporte"                --force
gh label create "epic/mapa"        --color "534AB7" --description "E2 — Mapa e Visualização"               --force
gh label create "epic/credibilidade" --color "993C1D" --description "E3 — Credibilidade e Votação"         --force
gh label create "epic/gestao"      --color "BA7517" --description "E4 — Gestão da Prefeitura"              --force
gh label create "epic/notificacoes" --color "993556" --description "E5 — Notificações"                     --force
gh label create "epic/perfil"      --color "5F5E5A" --description "E6 — Perfil do Usuário"                 --force
gh label create "role/cidadao"     --color "185FA5" --description "Perfil: Cidadão"                        --force
gh label create "role/funcionario" --color "3B6D11" --description "Perfil: Funcionário da Prefeitura"      --force
gh label create "sprint/1"         --color "D3D1C7" --description "Sprint 1"                               --force
gh label create "sprint/2"         --color "B4B2A9" --description "Sprint 2"                               --force
gh label create "sprint/3"         --color "888780" --description "Sprint 3"                               --force

echo "✅ Labels criadas."
echo ""
echo "📋 Criando milestones..."

gh api repos/:owner/:repo/milestones --method POST -f title="Sprint 1" -f description="E1 + E2 base (US01–US08)" || true
gh api repos/:owner/:repo/milestones --method POST -f title="Sprint 2" -f description="E2 filtros + E3 + E4 core (US09–US16)" || true
gh api repos/:owner/:repo/milestones --method POST -f title="Sprint 3" -f description="E4 filtros + E5 + E6 (US17–US23)" || true

echo "✅ Milestones criadas."
echo ""
echo "🐛 Criando issues..."

# ─── E1 — Criação de Reporte ────────────────────────────────────────────────

gh issue create \
  --title "[US01] Reporte com localização por GPS" \
  --label "user-story,epic/criação,role/cidadao,sprint/1" \
  --milestone "Sprint 1" \
  --body "## 📖 História de Usuário
> Como cidadão, quero que minha localização seja detectada automaticamente ao criar um reporte, para facilitar o preenchimento do local do problema.

## ✅ Critérios de Aceite
- [ ] GPS ativado automaticamente ao abrir o formulário de reporte
- [ ] Permissão de localização solicitada na primeira utilização
- [ ] Pin no mapa exibindo a localização atual
- [ ] Possibilidade de ajustar o pin manualmente após a detecção automática
- [ ] Mensagem de erro exibida se GPS indisponível, com fallback para seleção manual

## 🗂️ Modelos envolvidos
\`Report\`, \`ReportLocation\`"

gh issue create \
  --title "[US02] Definir localização manual no mapa" \
  --label "user-story,epic/criação,role/cidadao,sprint/1" \
  --milestone "Sprint 1" \
  --body "## 📖 História de Usuário
> Como cidadão, quero definir a localização do problema manualmente no mapa, para casos em que o GPS não está disponível ou o problema está em outro local.

## ✅ Critérios de Aceite
- [ ] Mapa interativo para arrastar e soltar o pin
- [ ] Campo de busca de endereço com autocompletar
- [ ] Endereço correspondente ao pin exibido abaixo do mapa
- [ ] Confirmação da localização antes de prosseguir ao próximo passo

## 🗂️ Modelos envolvidos
\`Report\`, \`ReportLocation\`

## 🔗 Depende de
#1"

gh issue create \
  --title "[US03] Adicionar descrição ao reporte" \
  --label "user-story,epic/criação,role/cidadao,sprint/1" \
  --milestone "Sprint 1" \
  --body "## 📖 História de Usuário
> Como cidadão, quero adicionar uma descrição textual ao meu reporte, para fornecer mais detalhes sobre o problema.

## ✅ Critérios de Aceite
- [ ] Campo de texto livre com mínimo de 10 e máximo de 500 caracteres
- [ ] Contador de caracteres restantes visível abaixo do campo
- [ ] Campo obrigatório — não é possível enviar sem preenchimento
- [ ] Teclado abre automaticamente ao focar no campo

## 🗂️ Modelos envolvidos
\`Report\`"

gh issue create \
  --title "[US04] Selecionar categoria do problema" \
  --label "user-story,epic/criação,role/cidadao,sprint/1" \
  --milestone "Sprint 1" \
  --body "## 📖 História de Usuário
> Como cidadão, quero classificar meu reporte em uma categoria, para que a prefeitura possa encaminhar ao setor correto.

## ✅ Critérios de Aceite
- [ ] Categorias disponíveis: Pavimentação, Iluminação, Esgoto, Abastecimento de Água, Coleta de Lixo, Meio Ambiente, Outros
- [ ] Ícone visual para cada categoria
- [ ] Seleção obrigatória — não é possível enviar sem categoria
- [ ] Apenas uma categoria selecionada por reporte

## 🗂️ Modelos envolvidos
\`Report\`, \`ReportCategory\`"

gh issue create \
  --title "[US05] Definir nível de urgência" \
  --label "user-story,epic/criação,role/cidadao,sprint/1" \
  --milestone "Sprint 1" \
  --body "## 📖 História de Usuário
> Como cidadão, quero indicar o nível de urgência do problema reportado, para ajudar a priorizar situações de risco.

## ✅ Critérios de Aceite
- [ ] Três níveis disponíveis: Baixa (verde), Média (amarelo), Alta (vermelho)
- [ ] Descrição de quando usar cada nível exibida como dica
- [ ] Seleção obrigatória antes do envio
- [ ] Nível selecionado refletido na cor do pin no mapa após a criação

## 🗂️ Modelos envolvidos
\`Report\`, \`UrgencyLevel\`"

gh issue create \
  --title "[US06] Confirmação de envio do reporte" \
  --label "user-story,epic/criação,role/cidadao,sprint/1" \
  --milestone "Sprint 1" \
  --body "## 📖 História de Usuário
> Como cidadão, quero receber uma confirmação após enviar um reporte, para saber que meu registro foi realizado com sucesso.

## ✅ Critérios de Aceite
- [ ] Tela de confirmação exibe número de protocolo único gerado
- [ ] Resumo com categoria, urgência e endereço do reporte
- [ ] Botão \"Ver no mapa\" disponível na tela de confirmação
- [ ] Reporte aparece imediatamente no mapa público

## 🗂️ Modelos envolvidos
\`Report\`

## 🔗 Depende de
#1 #3 #4 #5"

# ─── E2 — Mapa e Visualização ───────────────────────────────────────────────

gh issue create \
  --title "[US07] Visualizar reportes no mapa" \
  --label "user-story,epic/mapa,role/cidadao,sprint/1" \
  --milestone "Sprint 1" \
  --body "## 📖 História de Usuário
> Como cidadão, quero visualizar todos os reportes ativos no mapa, para ter uma visão geral dos problemas na minha cidade.

## ✅ Critérios de Aceite
- [ ] Mapa exibe pins para cada reporte com status \"Aberto\"
- [ ] Cor do pin indica urgência: verde (baixa), amarelo (média), vermelho (alta)
- [ ] Ícone do pin indica a categoria do problema
- [ ] Mapa centralizado na localização atual do usuário ao abrir

## 🗂️ Modelos envolvidos
\`Report\`, \`ReportLocation\`, \`UrgencyLevel\`, \`ReportCategory\`"

gh issue create \
  --title "[US08] Ver detalhes de um reporte" \
  --label "user-story,epic/mapa,role/cidadao,sprint/1" \
  --milestone "Sprint 1" \
  --body "## 📖 História de Usuário
> Como cidadão, quero ver os detalhes de um reporte ao tocar no pin do mapa, para entender o problema reportado.

## ✅ Critérios de Aceite
- [ ] Card com categoria, urgência, descrição completa e data de abertura
- [ ] Status atual (Aberto ou Resolvido) exibido com destaque visual
- [ ] Score de credibilidade e número total de votos visíveis
- [ ] Botão para votar no reporte acessível no card

## 🗂️ Modelos envolvidos
\`Report\`, \`ReportCategory\`, \`UrgencyLevel\`, \`ReportStatus\`

## 🔗 Depende de
#7"

gh issue create \
  --title "[US09] Filtrar reportes por categoria" \
  --label "user-story,epic/mapa,role/cidadao,sprint/2" \
  --milestone "Sprint 2" \
  --body "## 📖 História de Usuário
> Como cidadão, quero filtrar os reportes no mapa por categoria, para focar nos tipos de problema que me interessam.

## ✅ Critérios de Aceite
- [ ] Menu de filtro acessível diretamente na tela do mapa
- [ ] Seleção múltipla de categorias permitida
- [ ] Pins atualizados imediatamente ao aplicar o filtro
- [ ] Indicador visual mostrando que um filtro está ativo
- [ ] Botão para limpar todos os filtros

## 🗂️ Modelos envolvidos
\`ReportCategory\`

## 🔗 Depende de
#7"

gh issue create \
  --title "[US10] Filtrar reportes por status" \
  --label "user-story,epic/mapa,role/cidadao,sprint/2" \
  --milestone "Sprint 2" \
  --body "## 📖 História de Usuário
> Como cidadão, quero filtrar os reportes por status, para ver o que já foi resolvido ou ainda está pendente.

## ✅ Critérios de Aceite
- [ ] Toggle entre \"Abertos\", \"Resolvidos\" e \"Todos\"
- [ ] Padrão de exibição: apenas reportes abertos
- [ ] Pins de reportes resolvidos com visual diferente (cinza ou ícone de check)

## 🗂️ Modelos envolvidos
\`ReportStatus\`

## 🔗 Depende de
#7"

gh issue create \
  --title "[US11] Lista de reportes próximos" \
  --label "user-story,epic/mapa,role/cidadao,sprint/2" \
  --milestone "Sprint 2" \
  --body "## 📖 História de Usuário
> Como cidadão, quero ver uma lista dos reportes próximos a mim, para acompanhar os problemas na minha vizinhança.

## ✅ Critérios de Aceite
- [ ] Lista ordenada por distância do usuário
- [ ] Cada item exibe: categoria, urgência, distância e data de abertura
- [ ] Toque no item centraliza o mapa e abre os detalhes do reporte
- [ ] Raio padrão de 5 km, com opção de ajuste pelo usuário

## 🗂️ Modelos envolvidos
\`Report\`, \`ReportLocation\`

## 🔗 Depende de
#7"

# ─── E3 — Credibilidade e Votação ───────────────────────────────────────────

gh issue create \
  --title "[US12] Votar em um reporte" \
  --label "user-story,epic/credibilidade,role/cidadao,sprint/2" \
  --milestone "Sprint 2" \
  --body "## 📖 História de Usuário
> Como cidadão, quero votar em um reporte confirmando que o problema é real, para ajudar a validar reportes legítimos e evitar trotes.

## ✅ Critérios de Aceite
- [ ] Botão \"Confirmo esse problema\" no card de detalhes do reporte
- [ ] Cada dispositivo pode votar uma única vez por reporte
- [ ] Contagem de votos atualizada imediatamente após o voto
- [ ] Possibilidade de remover o voto ao tocar novamente no botão

## 🗂️ Modelos envolvidos
\`VoteRegistry\`, \`Report\`

## 🔗 Depende de
#8"

gh issue create \
  --title "[US13] Ver score de credibilidade" \
  --label "user-story,epic/credibilidade,role/cidadao,sprint/2" \
  --milestone "Sprint 2" \
  --body "## 📖 História de Usuário
> Como cidadão, quero ver o score de credibilidade de um reporte, para saber o quanto a comunidade validou aquele problema.

## ✅ Critérios de Aceite
- [ ] Score exibido como número de votos no card do reporte
- [ ] Barra de progresso visual proporcional ao número de votos
- [ ] Distinção visual para reportes com alta credibilidade (acima de 10 votos)
- [ ] Score visível tanto no mapa quanto na tela de detalhes

## 🗂️ Modelos envolvidos
\`Report\`

## 🔗 Depende de
#8 #12"

gh issue create \
  --title "[US14] Destaque por credibilidade no mapa" \
  --label "user-story,epic/credibilidade,role/cidadao,sprint/2" \
  --milestone "Sprint 2" \
  --body "## 📖 História de Usuário
> Como cidadão, quero ver reportes com maior credibilidade destacados no mapa, para identificar rapidamente os problemas mais confirmados pela comunidade.

## ✅ Critérios de Aceite
- [ ] Pins de alta credibilidade com tamanho ou ícone diferenciado
- [ ] Filtro opcional para exibir apenas reportes acima de N votos
- [ ] Ordenação por credibilidade disponível na lista de reportes próximos

## 🗂️ Modelos envolvidos
\`Report\`

## 🔗 Depende de
#7 #13"

# ─── E4 — Gestão de Reportes (Prefeitura) ───────────────────────────────────

gh issue create \
  --title "[US15] Painel de reportes abertos" \
  --label "user-story,epic/gestao,role/funcionario,sprint/2" \
  --milestone "Sprint 2" \
  --body "## 📖 História de Usuário
> Como funcionário da prefeitura, quero ver um painel com todos os reportes abertos, para gerenciar as demandas da cidade.

## ✅ Critérios de Aceite
- [ ] Lista de reportes ordenados por urgência (padrão: alta primeiro)
- [ ] Alternância entre visualização em lista e mapa
- [ ] Cada item exibe: categoria, urgência, data, credibilidade e endereço
- [ ] Contador total de reportes abertos visível no topo do painel

## 🗂️ Modelos envolvidos
\`Report\`, \`ReportStatus\`, \`UrgencyLevel\`"

gh issue create \
  --title "[US16] Marcar reporte como resolvido" \
  --label "user-story,epic/gestao,role/funcionario,sprint/2" \
  --milestone "Sprint 2" \
  --body "## 📖 História de Usuário
> Como funcionário da prefeitura, quero marcar um reporte como resolvido, para atualizar o status e notificar o cidadão.

## ✅ Critérios de Aceite
- [ ] Botão \"Marcar como resolvido\" na tela de detalhes do reporte
- [ ] Campo opcional para comentário sobre a resolução
- [ ] Diálogo de confirmação antes de concluir a ação
- [ ] Status atualizado para \"Resolvido\" em tempo real no mapa público
- [ ] Push notification enviada automaticamente ao criador do reporte

## 🗂️ Modelos envolvidos
\`Report\`, \`ReportStatus\`

## 🔗 Depende de
#15 #20"

gh issue create \
  --title "[US17] Filtrar reportes por urgência" \
  --label "user-story,epic/gestao,role/funcionario,sprint/3" \
  --milestone "Sprint 3" \
  --body "## 📖 História de Usuário
> Como funcionário da prefeitura, quero filtrar reportes por nível de urgência, para priorizar os casos mais críticos.

## ✅ Critérios de Aceite
- [ ] Filtro por: Alta, Média e Baixa urgência
- [ ] Seleção múltipla permitida
- [ ] Contagem de reportes por nível de urgência visível no filtro
- [ ] Filtro ativo indicado visualmente no painel

## 🗂️ Modelos envolvidos
\`UrgencyLevel\`

## 🔗 Depende de
#15"

gh issue create \
  --title "[US18] Filtrar reportes por categoria (prefeitura)" \
  --label "user-story,epic/gestao,role/funcionario,sprint/3" \
  --milestone "Sprint 3" \
  --body "## 📖 História de Usuário
> Como funcionário da prefeitura, quero filtrar reportes pela categoria do problema, para encaminhar ao setor responsável.

## ✅ Critérios de Aceite
- [ ] Filtro pelas mesmas categorias disponíveis para cidadãos
- [ ] Seleção múltipla de categorias
- [ ] Lista atualizada em tempo real ao aplicar ou remover filtros
- [ ] Combinável com filtro de urgência simultaneamente

## 🗂️ Modelos envolvidos
\`ReportCategory\`

## 🔗 Depende de
#15 #17"

gh issue create \
  --title "[US19] Ver localização do reporte no mapa" \
  --label "user-story,epic/gestao,role/funcionario,sprint/3" \
  --milestone "Sprint 3" \
  --body "## 📖 História de Usuário
> Como funcionário da prefeitura, quero ver a localização exata de um reporte no mapa, para facilitar o deslocamento da equipe de campo.

## ✅ Critérios de Aceite
- [ ] Mapa com pin na localização do reporte ao abrir os detalhes
- [ ] Endereço completo exibido abaixo do mapa
- [ ] Botão \"Abrir no Apple Maps\" para navegação
- [ ] Coordenadas GPS (latitude e longitude) disponíveis nos detalhes

## 🗂️ Modelos envolvidos
\`ReportLocation\`

## 🔗 Depende de
#15"

# ─── E5 — Notificações ──────────────────────────────────────────────────────

gh issue create \
  --title "[US20] Push notification ao resolver reporte" \
  --label "user-story,epic/notificacoes,role/cidadao,sprint/3" \
  --milestone "Sprint 3" \
  --body "## 📖 História de Usuário
> Como cidadão, quero receber uma notificação push quando meu reporte for marcado como resolvido, para acompanhar o andamento sem precisar abrir o app.

## ✅ Critérios de Aceite
- [ ] Notificação enviada no momento em que o funcionário marca o reporte como resolvido
- [ ] Texto indica o número de protocolo e a categoria do reporte resolvido
- [ ] Toque na notificação abre diretamente o reporte no app
- [ ] Permissão de notificação solicitada durante o onboarding do app

## 🗂️ Modelos envolvidos
\`UserProfile\`"

gh issue create \
  --title "[US21] Gerenciar preferências de notificação" \
  --label "user-story,epic/notificacoes,role/cidadao,sprint/3" \
  --milestone "Sprint 3" \
  --body "## 📖 História de Usuário
> Como cidadão, quero configurar minhas preferências de notificação, para controlar quando sou notificado.

## ✅ Critérios de Aceite
- [ ] Toggle para ativar ou desativar push notifications na tela de perfil
- [ ] Mudança de preferência refletida imediatamente
- [ ] Desativar notificações não afeta o histórico de atualizações de status no app

## 🗂️ Modelos envolvidos
\`UserProfile\`

## 🔗 Depende de
#20"

# ─── E6 — Perfil do Usuário ─────────────────────────────────────────────────

gh issue create \
  --title "[US22] Histórico de reportes" \
  --label "user-story,epic/perfil,role/cidadao,sprint/3" \
  --milestone "Sprint 3" \
  --body "## 📖 História de Usuário
> Como cidadão, quero ver o histórico de todos os reportes que fiz, para acompanhar o status de cada um.

## ✅ Critérios de Aceite
- [ ] Lista de reportes do dispositivo, ordenados por data (mais recente primeiro)
- [ ] Status de cada reporte exibido (Aberto ou Resolvido)
- [ ] Número do protocolo visível em cada item da lista
- [ ] Toque no item abre a tela de detalhes completos do reporte

## 🗂️ Modelos envolvidos
\`Report\`"

gh issue create \
  --title "[US23] Editar perfil" \
  --label "user-story,epic/perfil,role/cidadao,sprint/3" \
  --milestone "Sprint 3" \
  --body "## 📖 História de Usuário
> Como cidadão, quero editar minhas informações de perfil, para manter meus dados atualizados.

## ✅ Critérios de Aceite
- [ ] Campos editáveis: nome e e-mail
- [ ] Validações de formato aplicadas em tempo real
- [ ] Mensagem de confirmação exibida ao salvar com sucesso

## 🗂️ Modelos envolvidos
\`UserProfile\`"

echo ""
echo "✅ 23 issues criadas com sucesso!"
