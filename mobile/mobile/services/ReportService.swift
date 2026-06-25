import Foundation

private struct DeleteReportBody: Encodable {
    let id: String  // UUID do reporte a ser deletado
}

final class ReportService {

    // Singleton — o app inteiro usa a mesma instância
    static let shared = ReportService()
    private init() {}

    private let client = APIClient.shared

    
    func fetchAll() async throws -> [Report] {

        // Pega os bytes brutos da resposta
        let data = try await client.requestRaw(path: "/getreport", method: "GET")

        // array direto de Reports
        if let reports = try? client.decoder.decode([Report].self, from: data) {
            return reports
        }

        // envelope Cloudant com rows
        if let envelope = try? client.decoder.decode(CloudantListResponse<Report>.self, from: data) {
            return envelope.items
        }

        // Nenhum formato funcionou — lança erro com o texto cru para debug
        let raw = String(data: data, encoding: .utf8) ?? "(binário)"
        throw APIError.decodingFailed(
            NSError(domain: "ReportService", code: 0,
                    userInfo: [NSLocalizedDescriptionKey:
                        "Formato desconhecido em /getreports. Resposta: \(raw)"])
        )
    }

    @discardableResult
    func create(_ report: Report) async throws -> Report {

        let data = try await client.requestRaw(
            path: "/postreport",
            method: "POST",
            body: report  // serializado automaticamente para JSON
        )

        // Verifica se o Cloudant confirmou (ok: true)
        // Se não conseguir nem decodificar a confirmação, assume sucesso
        // (alguns flows respondem só o status HTTP 200/201)
        if let response = try? client.decoder.decode(CloudantWriteResponse.self, from: data),
           !response.isOk {
            throw APIError.decodingFailed(
                NSError(domain: "ReportService", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Cloudant não confirmou a gravação."])
            )
        }

        // Devolve o objeto que enviamos (o banco não retorna o objeto)
        return report
    }

    @discardableResult
    func update(_ report: Report) async throws -> Report {

        let data = try await client.requestRaw(
            path: "/putreport",
            method: "PUT",
            body: report
        )

        if let response = try? client.decoder.decode(CloudantWriteResponse.self, from: data),
           !response.isOk {
            throw APIError.decodingFailed(
                NSError(domain: "ReportService", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Cloudant não confirmou a atualização."])
            )
        }

        return report
    }

    func delete(id: UUID) async throws {
        let body = DeleteReportBody(id: id.uuidString)
        _ = try await client.requestRaw(
            path: "/deletereport",
            method: "DELETE",
            body: body
        )
        // Não importa o que o Node-RED respondeu — se não lançou erro, deletou.
    }

   
    @discardableResult
    func vote(report: Report) async throws -> Report {
        var updated = report
        updated.voteCount += 1
        return try await update(updated)
    }


    @discardableResult
    func removeVote(report: Report) async throws -> Report {
        var updated = report
        updated.voteCount = max(0, updated.voteCount - 1)  // nunca negativo
        return try await update(updated)
    }

    @discardableResult
    func resolve(report: Report, comment: String? = nil) async throws -> Report {
        var updated = report
        updated.status = .resolved
        updated.resolvedAt = Date()
        updated.resolutionComment = comment
        return try await update(updated)
    }
}
