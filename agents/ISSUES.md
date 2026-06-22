# Issues do Projeto — Aplicativo de Reportes Urbanos

> 23 issues mapeadas a partir das histórias de usuário (US01–US23).
> Para criar todas automaticamente, execute `bash create_issues.sh` com o GitHub CLI instalado.

---

## Labels necessárias

Criar antes de importar as issues:

| Label | Cor | Descrição |
|---|---|---|
| `epic/criação` | `#0F6E56` | E1 — Criação de Reporte |
| `epic/mapa` | `#534AB7` | E2 — Mapa e Visualização |
| `epic/credibilidade` | `#993C1D` | E3 — Credibilidade e Votação |
| `epic/gestao` | `#BA7517` | E4 — Gestão da Prefeitura |
| `epic/notificacoes` | `#993556` | E5 — Notificações |
| `epic/perfil` | `#5F5E5A` | E6 — Perfil do Usuário |
| `role/cidadao` | `#185FA5` | Perfil: Cidadão |
| `role/funcionario` | `#3B6D11` | Perfil: Funcionário da Prefeitura |
| `user-story` | `#E24B4A` | Issue originada de história de usuário |
| `sprint/1` | `#D3D1C7` | Sprint 1 |
| `sprint/2` | `#B4B2A9` | Sprint 2 |
| `sprint/3` | `#888780` | Sprint 3 |

---

## Sugestão de Sprints

| Sprint | Épicos | Issues |
|---|---|---|
| Sprint 1 | E1 + E2 base | US01–US08 |
| Sprint 2 | E2 filtros + E3 + E4 core | US09–US16 |
| Sprint 3 | E4 filtros + E5 + E6 | US17–US23 |

---

## E1 — Criação de Reporte

---

### [US01] Reporte com localização por GPS

**Labels:** `user-story` `epic/criação` `role/cidadao` `sprint/1`

**História de usuário**
> Como cidadão, quero que minha localização seja detectada automaticamente ao criar um reporte, para facilitar o preenchimento do local do problema.

**Critérios de aceite**
- [ ] GPS ativado automaticamente ao abrir o formulário de reporte
- [ ] Permissão de localização solicitada na primeira utilização
- [ ] Pin no mapa exibindo a localização atual
- [ ] Possibilidade de ajustar o pin manualmente após a detecção automática
- [ ] Mensagem de erro exibida se GPS indisponível, com fallback para seleção manual

**Modelos envolvidos:** `Report`, `ReportLocation`

---

### [US02] Definir localização manual no mapa

**Labels:** `user-story` `epic/criação` `role/cidadao` `sprint/1`

**História de usuário**
> Como cidadão, quero definir a localização do problema manualmente no mapa, para casos em que o GPS não está disponível ou o problema está em outro local.

**Critérios de aceite**
- [ ] Mapa interativo para arrastar e soltar o pin
- [ ] Campo de busca de endereço com autocompletar
- [ ] Endereço correspondente ao pin exibido abaixo do mapa
- [ ] Confirmação da localização antes de prosseguir ao próximo passo

**Modelos envolvidos:** `Report`, `ReportLocation`
**Depende de:** US01

---

### [US03] Adicionar descrição ao reporte

**Labels:** `user-story` `epic/criação` `role/cidadao` `sprint/1`

**História de usuário**
> Como cidadão, quero adicionar uma descrição textual ao meu reporte, para fornecer mais detalhes sobre o problema.

**Critérios de aceite**
- [ ] Campo de texto livre com mínimo de 10 e máximo de 500 caracteres
- [ ] Contador de caracteres restantes visível abaixo do campo
- [ ] Campo obrigatório — não é possível enviar sem preenchimento
- [ ] Teclado abre automaticamente ao focar no campo

**Modelos envolvidos:** `Report`

---

### [US04] Selecionar categoria do problema

**Labels:** `user-story` `epic/criação` `role/cidadao` `sprint/1`

**História de usuário**
> Como cidadão, quero classificar meu reporte em uma categoria, para que a prefeitura possa encaminhar ao setor correto.

**Critérios de aceite**
- [ ] Categorias disponíveis: Pavimentação, Iluminação, Esgoto, Abastecimento de Água, Coleta de Lixo, Meio Ambiente, Outros
- [ ] Ícone visual para cada categoria
- [ ] Seleção obrigatória — não é possível enviar sem categoria
- [ ] Apenas uma categoria selecionada por reporte

**Modelos envolvidos:** `Report`, `ReportCategory`

---

### [US05] Definir nível de urgência

**Labels:** `user-story` `epic/criação` `role/cidadao` `sprint/1`

**História de usuário**
> Como cidadão, quero indicar o nível de urgência do problema reportado, para ajudar a priorizar situações de risco.

**Critérios de aceite**
- [ ] Três níveis disponíveis: Baixa (verde), Média (amarelo), Alta (vermelho)
- [ ] Descrição de quando usar cada nível exibida como dica
- [ ] Seleção obrigatória antes do envio
- [ ] Nível selecionado refletido na cor do pin no mapa após a criação

**Modelos envolvidos:** `Report`, `UrgencyLevel`

---

### [US06] Confirmação de envio do reporte

**Labels:** `user-story` `epic/criação` `role/cidadao` `sprint/1`

**História de usuário**
> Como cidadão, quero receber uma confirmação após enviar um reporte, para saber que meu registro foi realizado com sucesso.

**Critérios de aceite**
- [ ] Tela de confirmação exibe número de protocolo único gerado
- [ ] Resumo com categoria, urgência e endereço do reporte
- [ ] Botão "Ver no mapa" disponível na tela de confirmação
- [ ] Reporte aparece imediatamente no mapa público

**Modelos envolvidos:** `Report`
**Depende de:** US01, US03, US04, US05

---

## E2 — Mapa e Visualização

---

### [US07] Visualizar reportes no mapa

**Labels:** `user-story` `epic/mapa` `role/cidadao` `sprint/1`

**História de usuário**
> Como cidadão, quero visualizar todos os reportes ativos no mapa, para ter uma visão geral dos problemas na minha cidade.

**Critérios de aceite**
- [ ] Mapa exibe pins para cada reporte com status "Aberto"
- [ ] Cor do pin indica urgência: verde (baixa), amarelo (média), vermelho (alta)
- [ ] Ícone do pin indica a categoria do problema
- [ ] Mapa centralizado na localização atual do usuário ao abrir

**Modelos envolvidos:** `Report`, `ReportLocation`, `UrgencyLevel`, `ReportCategory`

---

### [US08] Ver detalhes de um reporte

**Labels:** `user-story` `epic/mapa` `role/cidadao` `sprint/1`

**História de usuário**
> Como cidadão, quero ver os detalhes de um reporte ao tocar no pin do mapa, para entender o problema reportado.

**Critérios de aceite**
- [ ] Card com categoria, urgência, descrição completa e data de abertura
- [ ] Status atual (Aberto ou Resolvido) exibido com destaque visual
- [ ] Score de credibilidade e número total de votos visíveis
- [ ] Botão para votar no reporte acessível no card

**Modelos envolvidos:** `Report`, `ReportCategory`, `UrgencyLevel`, `ReportStatus`
**Depende de:** US07

---

### [US09] Filtrar reportes por categoria

**Labels:** `user-story` `epic/mapa` `role/cidadao` `sprint/2`

**História de usuário**
> Como cidadão, quero filtrar os reportes no mapa por categoria, para focar nos tipos de problema que me interessam.

**Critérios de aceite**
- [ ] Menu de filtro acessível diretamente na tela do mapa
- [ ] Seleção múltipla de categorias permitida
- [ ] Pins atualizados imediatamente ao aplicar o filtro
- [ ] Indicador visual mostrando que um filtro está ativo
- [ ] Botão para limpar todos os filtros

**Modelos envolvidos:** `ReportCategory`
**Depende de:** US07

---

### [US10] Filtrar reportes por status

**Labels:** `user-story` `epic/mapa` `role/cidadao` `sprint/2`

**História de usuário**
> Como cidadão, quero filtrar os reportes por status, para ver o que já foi resolvido ou ainda está pendente.

**Critérios de aceite**
- [ ] Toggle entre "Abertos", "Resolvidos" e "Todos"
- [ ] Padrão de exibição: apenas reportes abertos
- [ ] Pins de reportes resolvidos com visual diferente (cinza ou ícone de check)

**Modelos envolvidos:** `ReportStatus`
**Depende de:** US07

---

### [US11] Lista de reportes próximos

**Labels:** `user-story` `epic/mapa` `role/cidadao` `sprint/2`

**História de usuário**
> Como cidadão, quero ver uma lista dos reportes próximos a mim, para acompanhar os problemas na minha vizinhança.

**Critérios de aceite**
- [ ] Lista ordenada por distância do usuário
- [ ] Cada item exibe: categoria, urgência, distância e data de abertura
- [ ] Toque no item centraliza o mapa e abre os detalhes do reporte
- [ ] Raio padrão de 5 km, com opção de ajuste pelo usuário

**Modelos envolvidos:** `Report`, `ReportLocation`
**Depende de:** US07

---

## E3 — Credibilidade e Votação

---

### [US12] Votar em um reporte

**Labels:** `user-story` `epic/credibilidade` `role/cidadao` `sprint/2`

**História de usuário**
> Como cidadão, quero votar em um reporte confirmando que o problema é real, para ajudar a validar reportes legítimos e evitar trotes.

**Critérios de aceite**
- [ ] Botão "Confirmo esse problema" no card de detalhes do reporte
- [ ] Cada dispositivo pode votar uma única vez por reporte
- [ ] Contagem de votos atualizada imediatamente após o voto
- [ ] Possibilidade de remover o voto ao tocar novamente no botão

**Modelos envolvidos:** `VoteRegistry`, `Report`
**Depende de:** US08

---

### [US13] Ver score de credibilidade

**Labels:** `user-story` `epic/credibilidade` `role/cidadao` `sprint/2`

**História de usuário**
> Como cidadão, quero ver o score de credibilidade de um reporte, para saber o quanto a comunidade validou aquele problema.

**Critérios de aceite**
- [ ] Score exibido como número de votos no card do reporte
- [ ] Barra de progresso visual proporcional ao número de votos
- [ ] Distinção visual para reportes com alta credibilidade (acima de 10 votos)
- [ ] Score visível tanto no mapa quanto na tela de detalhes

**Modelos envolvidos:** `Report`
**Depende de:** US08, US12

---

### [US14] Destaque por credibilidade no mapa

**Labels:** `user-story` `epic/credibilidade` `role/cidadao` `sprint/2`

**História de usuário**
> Como cidadão, quero ver reportes com maior credibilidade destacados no mapa, para identificar rapidamente os problemas mais confirmados pela comunidade.

**Critérios de aceite**
- [ ] Pins de alta credibilidade com tamanho ou ícone diferenciado
- [ ] Filtro opcional para exibir apenas reportes acima de N votos
- [ ] Ordenação por credibilidade disponível na lista de reportes próximos

**Modelos envolvidos:** `Report`
**Depende de:** US07, US13

---

## E4 — Gestão de Reportes (Prefeitura)

---

### [US15] Painel de reportes abertos

**Labels:** `user-story` `epic/gestao` `role/funcionario` `sprint/2`

**História de usuário**
> Como funcionário da prefeitura, quero ver um painel com todos os reportes abertos, para gerenciar as demandas da cidade.

**Critérios de aceite**
- [ ] Lista de reportes ordenados por urgência (padrão: alta primeiro)
- [ ] Alternância entre visualização em lista e mapa
- [ ] Cada item exibe: categoria, urgência, data, credibilidade e endereço
- [ ] Contador total de reportes abertos visível no topo do painel

**Modelos envolvidos:** `Report`, `ReportStatus`, `UrgencyLevel`

---

### [US16] Marcar reporte como resolvido

**Labels:** `user-story` `epic/gestao` `role/funcionario` `sprint/2`

**História de usuário**
> Como funcionário da prefeitura, quero marcar um reporte como resolvido, para atualizar o status e notificar o cidadão.

**Critérios de aceite**
- [ ] Botão "Marcar como resolvido" na tela de detalhes do reporte
- [ ] Campo opcional para comentário sobre a resolução
- [ ] Diálogo de confirmação antes de concluir a ação
- [ ] Status atualizado para "Resolvido" em tempo real no mapa público
- [ ] Push notification enviada automaticamente ao criador do reporte

**Modelos envolvidos:** `Report`, `ReportStatus`
**Depende de:** US15, US20

---

### [US17] Filtrar reportes por urgência

**Labels:** `user-story` `epic/gestao` `role/funcionario` `sprint/3`

**História de usuário**
> Como funcionário da prefeitura, quero filtrar reportes por nível de urgência, para priorizar os casos mais críticos.

**Critérios de aceite**
- [ ] Filtro por: Alta, Média e Baixa urgência
- [ ] Seleção múltipla permitida
- [ ] Contagem de reportes por nível de urgência visível no filtro
- [ ] Filtro ativo indicado visualmente no painel

**Modelos envolvidos:** `UrgencyLevel`
**Depende de:** US15

---

### [US18] Filtrar reportes por categoria (prefeitura)

**Labels:** `user-story` `epic/gestao` `role/funcionario` `sprint/3`

**História de usuário**
> Como funcionário da prefeitura, quero filtrar reportes pela categoria do problema, para encaminhar ao setor responsável.

**Critérios de aceite**
- [ ] Filtro pelas mesmas categorias disponíveis para cidadãos
- [ ] Seleção múltipla de categorias
- [ ] Lista atualizada em tempo real ao aplicar ou remover filtros
- [ ] Combinável com filtro de urgência simultaneamente

**Modelos envolvidos:** `ReportCategory`
**Depende de:** US15, US17

---

### [US19] Ver localização do reporte no mapa

**Labels:** `user-story` `epic/gestao` `role/funcionario` `sprint/3`

**História de usuário**
> Como funcionário da prefeitura, quero ver a localização exata de um reporte no mapa, para facilitar o deslocamento da equipe de campo.

**Critérios de aceite**
- [ ] Mapa com pin na localização do reporte ao abrir os detalhes
- [ ] Endereço completo exibido abaixo do mapa
- [ ] Botão "Abrir no Apple Maps" para navegação
- [ ] Coordenadas GPS (latitude e longitude) disponíveis nos detalhes

**Modelos envolvidos:** `ReportLocation`
**Depende de:** US15

---

## E5 — Notificações

---

### [US20] Push notification ao resolver reporte

**Labels:** `user-story` `epic/notificacoes` `role/cidadao` `sprint/3`

**História de usuário**
> Como cidadão, quero receber uma notificação push quando meu reporte for marcado como resolvido, para acompanhar o andamento sem precisar abrir o app.

**Critérios de aceite**
- [ ] Notificação enviada no momento em que o funcionário marca o reporte como resolvido
- [ ] Texto indica o número de protocolo e a categoria do reporte resolvido
- [ ] Toque na notificação abre diretamente o reporte no app
- [ ] Permissão de notificação solicitada durante o onboarding do app

**Modelos envolvidos:** `UserProfile`

---

### [US21] Gerenciar preferências de notificação

**Labels:** `user-story` `epic/notificacoes` `role/cidadao` `sprint/3`

**História de usuário**
> Como cidadão, quero configurar minhas preferências de notificação, para controlar quando sou notificado.

**Critérios de aceite**
- [ ] Toggle para ativar ou desativar push notifications na tela de perfil
- [ ] Mudança de preferência refletida imediatamente
- [ ] Desativar notificações não afeta o histórico de atualizações de status no app

**Modelos envolvidos:** `UserProfile`
**Depende de:** US20

---

## E6 — Perfil do Usuário

---

### [US22] Histórico de reportes

**Labels:** `user-story` `epic/perfil` `role/cidadao` `sprint/3`

**História de usuário**
> Como cidadão, quero ver o histórico de todos os reportes que fiz, para acompanhar o status de cada um.

**Critérios de aceite**
- [ ] Lista de reportes do dispositivo, ordenados por data (mais recente primeiro)
- [ ] Status de cada reporte exibido (Aberto ou Resolvido)
- [ ] Número do protocolo visível em cada item da lista
- [ ] Toque no item abre a tela de detalhes completos do reporte

**Modelos envolvidos:** `Report`

---

### [US23] Editar perfil

**Labels:** `user-story` `epic/perfil` `role/cidadao` `sprint/3`

**História de usuário**
> Como cidadão, quero editar minhas informações de perfil, para manter meus dados atualizados.

**Critérios de aceite**
- [ ] Campos editáveis: nome e e-mail
- [ ] Validações de formato aplicadas em tempo real
- [ ] Mensagem de confirmação exibida ao salvar com sucesso

**Modelos envolvidos:** `UserProfile`
