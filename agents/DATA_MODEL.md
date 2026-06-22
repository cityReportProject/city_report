# Modelagem de Dados — Aplicativo de Reportes Urbanos

> Documento de referência técnica gerado a partir das histórias de usuário (US01–US23).
> Time: 4 membros · Turma02-14 · Atualizado em 22/06/2026

---

## Sumário

- [Visão Geral](#visão-geral)
- [Diagrama de Entidades](#diagrama-de-entidades)
- [Entidades](#entidades)
  - [Report](#report)
  - [ReportLocation](#reportlocation)
  - [UserProfile](#userprofile)
  - [VoteRegistry](#voteregistry)
- [Enumerações](#enumerações)
  - [ReportCategory](#reportcategory)
  - [UrgencyLevel](#urgencylevel)
  - [ReportStatus](#reportstatus)
- [Protocolos adotados](#protocolos-adotados)
- [Decisões de design](#decisões-de-design)
- [Estrutura de arquivos](#estrutura-de-arquivos)

---

## Visão Geral

O modelo de dados é composto por **4 structs** e **3 enums**, todos em Swift puro (`import Foundation`), sem dependência de frameworks de UI.

| Tipo | Nome | Papel |
|---|---|---|
| `struct` | `Report` | Entidade central — reporte de problema urbano |
| `struct` | `ReportLocation` | Localização GPS embutida no reporte |
| `struct` | `UserProfile` | Perfil local do cidadão (persistido no dispositivo) |
| `struct` | `VoteRegistry` | Registro local de votos por dispositivo |
| `enum` | `ReportCategory` | Categoria do problema (7 valores) |
| `enum` | `UrgencyLevel` | Nível de urgência (3 valores, ordenável) |
| `enum` | `ReportStatus` | Status do reporte (2 valores) |

---

## Diagrama de Entidades

```
┌─────────────────────────────────────────────┐
│                   Report                    │
│─────────────────────────────────────────────│
│ id              : UUID            (PK)      │
│ protocolNumber  : String                    │
│ createdAt       : Date                      │
│ description     : String                    │
│ category        : ReportCategory  ──────┐   │
│ urgency         : UrgencyLevel    ────┐ │   │
│ status          : ReportStatus    ──┐ │ │   │
│ location        : ReportLocation  ──────────┤
│ voteCount       : Int                 │ │   │
│ resolvedAt      : Date?               │ │   │
│ resolutionComment : String?           │ │   │
└───────────────────────────────────────┼─┼───┘
                                        │ │
     ┌──────────────────────────────────┘ │
     │  ┌──────────────────────────────────┘
     │  │
     ▼  ▼
┌──────────────┐  ┌──────────────────┐  ┌──────────────────────┐
│ ReportStatus │  │  UrgencyLevel    │  │    ReportCategory    │
│──────────────│  │──────────────────│  │──────────────────────│
│ open         │  │ low < medium     │  │ pavement             │
│ resolved     │  │        < high    │  │ lighting             │
└──────────────┘  └──────────────────┘  │ sewage               │
                                        │ waterSupply          │
┌──────────────────────┐                │ wasteCollection      │
│    ReportLocation    │                │ environment          │
│──────────────────────│                │ other                │
│ latitude  : Double   │                └──────────────────────┘
│ longitude : Double   │
│ address   : String   │
└──────────────────────┘

┌──────────────────────┐     ┌──────────────────────┐
│     UserProfile      │     │    VoteRegistry       │
│──────────────────────│     │──────────────────────│
│ name      : String   │     │ votedReportIDs        │
│ email     : String   │     │   : Set<UUID>         │
│ pushNotif : Bool     │     └──────────────────────┘
└──────────────────────┘       (local, não sincronizado)
   (local, não sincronizado)
```

---

## Entidades

### Report

**Arquivo:** `Models/Report.swift`
**Protocolos:** `Identifiable`, `Codable`, `Hashable`
**Histórias:** US01–US06 (criação), US07–US11 (mapa), US12–US14 (credibilidade), US15–US19 (gestão)

| Propriedade | Tipo | Mutável | Descrição |
|---|---|---|---|
| `id` | `UUID` | `let` | Identificador único |
| `protocolNumber` | `String` | `let` | Número exibido na confirmação (US06) |
| `createdAt` | `Date` | `let` | Data de abertura, imutável |
| `description` | `String` | `var` | Texto do problema (US03) |
| `category` | `ReportCategory` | `var` | Categoria do problema (US04) |
| `urgency` | `UrgencyLevel` | `var` | Nível de urgência (US05) |
| `status` | `ReportStatus` | `var` | Aberto ou Resolvido (US10, US16) |
| `location` | `ReportLocation` | `var` | Localização GPS ou manual (US01, US02) |
| `voteCount` | `Int` | `var` | Contagem de votos de credibilidade (US12) |
| `resolvedAt` | `Date?` | `var` | Data de resolução (US16) |
| `resolutionComment` | `String?` | `var` | Comentário do funcionário (US16) |

**Helpers computados:**

| Propriedade | Retorno | Descrição |
|---|---|---|
| `isHighCredibility` | `Bool` | `voteCount >= 10` — destaque no mapa (US13) |
| `isResolved` | `Bool` | `status == .resolved` |

---

### ReportLocation

**Arquivo:** `Models/ReportLocation.swift`
**Protocolos:** `Codable`, `Hashable`
**Histórias:** US01 (GPS automático), US02 (localização manual)

Tipo embutido em `Report` — não existe de forma independente na API.

| Propriedade | Tipo | Descrição |
|---|---|---|
| `latitude` | `Double` | Coordenada geográfica |
| `longitude` | `Double` | Coordenada geográfica |
| `address` | `String` | Endereço legível exibido na UI (US02) |

---

### UserProfile

**Arquivo:** `Models/UserProfile.swift`
**Protocolos:** `Codable`, `Hashable`
**Histórias:** US21 (notificações), US22 (histórico), US23 (editar perfil)
**Persistência:** local no dispositivo (UserDefaults ou arquivo JSON) — **não sincronizado com API**

| Propriedade | Tipo | Padrão | Descrição |
|---|---|---|---|
| `name` | `String` | `""` | Nome do cidadão (US23) |
| `email` | `String` | `""` | E-mail do cidadão (US23) |
| `pushNotificationsEnabled` | `Bool` | `true` | Preferência de notificação (US21) |

**Helper computado:**

| Propriedade | Retorno | Descrição |
|---|---|---|
| `isEmailValid` | `Bool` | Valida formato via regex (US23) |

---

### VoteRegistry

**Arquivo:** `Models/VoteRegistry.swift`
**Protocolos:** `Codable`
**Histórias:** US12 (votar uma vez por dispositivo)
**Persistência:** local no dispositivo — **não sincronizado com API**

Sem autenticação, o controle de voto único é feito por dispositivo.
`VoteRegistry` é mantido separado de `Report` para não misturar estado local com dados de rede.

| Propriedade | Tipo | Descrição |
|---|---|---|
| `votedReportIDs` | `Set<UUID>` | IDs dos reportes em que o dispositivo votou |

**Métodos:**

| Método | Retorno | Descrição |
|---|---|---|
| `hasVoted(on:)` | `Bool` | Verifica se já votou neste reporte |
| `vote(on:)` | `Bool` | Registra voto; retorna `false` se já votou |
| `removeVote(on:)` | `Void` | Remove voto (desfazer) |

---

## Enumerações

### ReportCategory

**Arquivo:** `Models/ReportCategory.swift`
**Protocolos:** `String`, `Codable`, `CaseIterable`, `Hashable`
**Histórias:** US04, US09, US18

| Case | RawValue | Icon (SF Symbols) |
|---|---|---|
| `pavement` | `"Pavimentação"` | `road.lanes` |
| `lighting` | `"Iluminação"` | `lightbulb` |
| `sewage` | `"Esgoto"` | `drop.triangle` |
| `waterSupply` | `"Abastecimento de Água"` | `drop` |
| `wasteCollection` | `"Coleta de Lixo"` | `trash` |
| `environment` | `"Meio Ambiente"` | `leaf` |
| `other` | `"Outros"` | `exclamationmark.circle` |

---

### UrgencyLevel

**Arquivo:** `Models/UrgencyLevel.swift`
**Protocolos:** `String`, `Codable`, `CaseIterable`, `Hashable`, `Comparable`
**Histórias:** US05, US08, US10, US17

Implementa `Comparable` para permitir ordenação direta:
```swift
reports.sorted { $0.urgency > $1.urgency } // alta → média → baixa
```

| Case | RawValue | Ordem | Color Asset | Hint |
|---|---|---|---|---|
| `low` | `"Baixa"` | 0 | `UrgencyLow` | Sem risco imediato |
| `medium` | `"Média"` | 1 | `UrgencyMedium` | Pode agravar ou afetar muitas pessoas |
| `high` | `"Alta"` | 2 | `UrgencyHigh` | Risco imediato à segurança pública |

> **Assets necessários:** adicionar 3 Color Sets no `Assets.xcassets`:
> `UrgencyLow` (verde), `UrgencyMedium` (amarelo), `UrgencyHigh` (vermelho).

---

### ReportStatus

**Arquivo:** `Models/ReportStatus.swift`
**Protocolos:** `String`, `Codable`, `CaseIterable`, `Hashable`
**Histórias:** US10, US13, US16

| Case | RawValue | Icon (SF Symbols) |
|---|---|---|
| `open` | `"Aberto"` | `clock` |
| `resolved` | `"Resolvido"` | `checkmark.circle` |

---

## Protocolos adotados

| Protocolo | Tipos | Justificativa |
|---|---|---|
| `Identifiable` | `Report` | Usado em `List` / `ForEach` no SwiftUI |
| `Codable` | Todos | Serialização JSON para API e persistência local |
| `Hashable` | Todos exceto `VoteRegistry` | Permite uso em `Set`, `NavigationPath` e diffs |
| `CaseIterable` | Todos os enums | Pickers de categoria, urgência, filtros |
| `Comparable` | `UrgencyLevel` | Ordenação direta no painel da prefeitura (US17) |

---

## Decisões de design

### Structs, não classes
Todos os modelos são `struct`. Sem herança e sem necessidade de referência compartilhada, `struct` é mais seguro, previsível e performático no contexto de SwiftUI + Codable.

### Sem import SwiftUI nos modelos
Cores e assets são referenciados pelo nome (`colorName: String`, `icon: String`). Isso mantém a camada de dados independente de UI e facilita testes unitários sem precisar de um host SwiftUI.

### ReportLocation embutida, não referenciada por ID
A localização não existe fora do contexto de um reporte. Modelá-la como struct embutida evita uma tabela/endpoint extra e simplifica o Codable.

### VoteRegistry separado de Report
O estado de "já votei neste reporte" é local ao dispositivo e nunca vai para a API. Misturá-lo em `Report` contaminaria o modelo de rede com estado local. A separação torna o `Report` um DTO limpo.

### UserProfile local
Sem autenticação, não há servidor que persista o perfil. O `UserProfile` é armazenado localmente e reflete apenas as preferências deste dispositivo.

### protocolNumber como String
O número de protocolo pode ter formatação específica (ex: `"2026-00042"`) e não é usado em cálculos. `String` evita conversões desnecessárias e é Codable diretamente.

---

## Estrutura de arquivos

```
mobile/
└── mobile/
    └── Models/
        ├── Report.swift
        ├── ReportLocation.swift
        ├── ReportCategory.swift
        ├── UrgencyLevel.swift
        ├── ReportStatus.swift
        ├── UserProfile.swift
        └── VoteRegistry.swift
```
