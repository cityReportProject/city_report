# Node-RED — Endpoints esperados pelo app Swift

Configure os flows abaixo no seu Node-RED para que os services Swift funcionem corretamente.
Todos retornam e recebem `application/json` com datas em formato **ISO 8601**.

---

## Reports

| Método | Path | Descrição |
|--------|------|-----------|
| GET | `/reports` | Lista todos os reportes. Aceita query params opcionais: `?category=Esgoto&urgency=Alta&status=Aberto` |
| GET | `/reports/:id` | Retorna um reporte pelo UUID |
| POST | `/reports` | Cria novo reporte. Corpo: objeto `Report` completo |
| PUT | `/reports/:id` | Atualiza reporte. Corpo: objeto `Report` completo |
| DELETE | `/reports/:id` | Remove reporte. Resposta: 204 sem corpo |
| POST | `/reports/:id/vote` | Incrementa `voteCount` em 1. Retorna o `Report` atualizado |
| DELETE | `/reports/:id/vote` | Decrementa `voteCount` em 1. Retorna o `Report` atualizado |
| PUT | `/reports/:id/resolve` | Marca como resolvido. Corpo: `{ "resolvedAt": "...", "resolutionComment": "..." }` |

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

## User Profiles

| Método | Path | Descrição |
|--------|------|-----------|
| GET | `/profiles/:deviceID` | Retorna o perfil do dispositivo |
| PUT | `/profiles/:deviceID` | Cria ou substitui o perfil. Corpo: objeto `UserProfile` |
| DELETE | `/profiles/:deviceID` | Remove o perfil. Resposta: 204 sem corpo |

### Exemplo de objeto UserProfile (JSON)

```json
{
  "name": "João Silva",
  "email": "joao@email.com",
  "pushNotificationsEnabled": true
}
```

---

## Dicas de configuração no Node-RED

1. Use um nó **HTTP In** para cada endpoint.
2. Conecte a um nó **Function** para tratar lógica (filtros, validação de ID).
3. Use **node-red-contrib-sqlite** ou **node-red-node-mongodb** como banco de dados.
4. Termine com um nó **HTTP Response** configurando `msg.statusCode` e `msg.payload`.
5. Para DELETE com 204, defina `msg.statusCode = 204` e `msg.payload = ""`.

### Sugestão de flow para GET /reports com filtros

```
[HTTP In] → [Function: parseia query params e monta SQL/query] → [Database] → [Function: JSON.stringify] → [HTTP Response]
```

### Sugestão de flow para POST /reports/:id/vote

```
[HTTP In] → [Function: incrementa voteCount no banco] → [HTTP Response com Report atualizado]
```

---

## Configuração do baseURL no Swift

Edite `APIClient.swift`:

```swift
static let baseURL = "http://SEU_IP:1880"
```

Substitua `SEU_IP` pelo IP da máquina rodando o Node-RED na mesma rede do dispositivo.
Para produção, use HTTPS e configure o certificado adequadamente.
