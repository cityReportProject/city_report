# Services Swift ↔ Node-RED — não é uma API REST

A UI (SwiftUI) nunca fala HTTP diretamente. Ela chama métodos de `ReportService`,
`UserProfileService` e `VoteRegistryService`. Esses services é que conversam com o
Node-RED — e fazem isso com **chamadas estilo RPC** (um endpoint por ação, verbo no
path), não com rotas REST por recurso (`/reports/:id`, `PUT/PATCH` semânticos, etc.).
Quem decide regra de negócio (incrementar voto, marcar resolvido) é o app — o
Node-RED só persiste o objeto `Report`/`UserProfileRecord` que recebe.

Todos os endpoints recebem e retornam `application/json` com datas em **ISO 8601**.

---

## ReportService

| Método Swift | Ação | Chamada real no Node-RED |
|---|---|---|
| `fetchAll() -> [Report]` | Lista todos os reportes | `GET /getreports` |
| `create(_:) -> Report` | Cria reporte | `POST /postreport` — corpo: `Report` |
| `update(_:) -> Report` | Atualiza reporte (qualquer campo) | `PUT /putreport` — corpo: `Report` |
| `delete(id:)` | Remove reporte | `DELETE /deletereport` — corpo: `{ "id": "uuid" }` |
| `vote(report:) -> Report` | `voteCount += 1` | reaproveita `PUT /putreport` |
| `removeVote(report:) -> Report` | `voteCount -= 1` (mín. 0) | reaproveita `PUT /putreport` |
| `resolve(report:comment:) -> Report` | `status = .resolved`, preenche `resolvedAt`/`resolutionComment` | reaproveita `PUT /putreport` |

> `vote`, `removeVote` e `resolve` **não têm endpoint próprio**. O app monta o `Report`
> já modificado em memória e envia inteiro por `PUT /putreport` — não crie
> `/reports/:id/vote` nem `/reports/:id/resolve` no Node-RED, eles não são chamados.

### Exemplo de objeto Report (JSON)

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "protocolNumber": "2024-00042",
  "createdAt": "2024-06-01T10:30:00Z",
  "description": "Buraco na calçada",
  "category": "Pavimentação",
  "urgency": "Alta",
  "status": "Aberto",
  "location": {
    "latitude": -5.0892,
    "longitude": -42.8016,
    "address": "Rua Exemplo, 123, Teresina-PI"
  },
  "voteCount": 3,
  "resolvedAt": null,
  "resolutionComment": null
}
```

---

## UserProfileService

Como não há autenticação, o dispositivo é identificado por `deviceID`
(`UIDevice.identifierForVendor`), embutido no payload — por isso o DTO trafegado
não é `UserProfile` puro, é `UserProfileRecord` (`UserProfile` + `deviceID`).

| Método Swift | Ação | Chamada real no Node-RED |
|---|---|---|
| `fetchAll() -> [UserProfileRecord]` | Lista todos os perfis | `GET /getuser` |
| `fetchMine() -> UserProfile?` | Filtra `fetchAll()` pelo `deviceID` local | sem chamada própria — reaproveita `GET /getuser` |
| `create(_:) -> UserProfileRecord` | Cria perfil | `POST /postuser` — corpo: `UserProfileRecord` |
| `update(_:) -> UserProfileRecord` | Atualiza perfil | `PUT /putuser` — corpo: `UserProfileRecord` |
| `delete()` | Remove perfil do dispositivo atual | `DELETE /deleteuser` — corpo: `{ "deviceID": "..." }` |

> Não existe filtro por `deviceID` no Node-RED (`GET /profiles/:deviceID`) — o app
> sempre busca a lista inteira (`/getuser`) e filtra localmente em `fetchMine()`.

### Exemplo de objeto UserProfileRecord (JSON)

```json
{
  "deviceID": "3F2504E0-4F89-41D3-9A0C-0305E82C3301",
  "name": "João Silva",
  "email": "joao@email.com",
  "pushNotificationsEnabled": true
}
```

---

## VoteRegistryService

100% local (não chama o Node-RED diretamente). Guarda em `UserDefaults` os IDs de
reportes já votados pelo dispositivo (`hasVoted`, `vote`, `removeVote`) e só então
delega a `ReportService.vote()`/`removeVote()`. Se a chamada de rede falhar, desfaz
o registro local (rollback) — por isso o voto nunca fica "preso" em estado
inconsistente entre o dispositivo e o Node-RED.

---

## Dicas de configuração no Node-RED

Configure 8 flows, um por endpoint — todos recebem o objeto inteiro (`Report` ou
`UserProfileRecord`), nunca um path param:

1. Use um nó **HTTP In** para cada endpoint (`/getreports`, `/postreport`,
   `/putreport`, `/deletereport`, `/getuser`, `/postuser`, `/putuser`, `/deleteuser`).
2. Conecte a um nó **Function** para tratar a lógica (ex: localizar pelo `id`/`deviceID` recebido no corpo).
3. Use **node-red-contrib-sqlite** ou **node-red-node-mongodb** como banco de dados.
4. Termine com um nó **HTTP Response** configurando `msg.statusCode` e `msg.payload`.
5. Para DELETE, defina `msg.statusCode = 204` e `msg.payload = ""`.

### Sugestão de flow para PUT /putreport

```
[HTTP In] → [Function: localiza pelo "id" do corpo e substitui o registro inteiro] → [Database] → [HTTP Response com Report atualizado]
```

Como `vote`, `removeVote` e `resolve` reaproveitam este mesmo flow (o app já manda o
`Report` com `voteCount`/`status` modificados), não é preciso lógica extra aqui —
o Node-RED só persiste o que recebeu.

---

## Configuração do baseURL no Swift

Edite `APIClient.swift`:

```swift
static let baseURL = "http://SEU_IP:1880"
```

Substitua `SEU_IP` pelo IP da máquina rodando o Node-RED na mesma rede do dispositivo.
Para produção, use HTTPS e configure o certificado adequadamente.
