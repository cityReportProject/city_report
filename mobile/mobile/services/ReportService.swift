// ============================================================
// ReportService.swift
// ============================================================
//
// CRUD de Report contra o Node-RED + Cloudant.
//
// Endpoints:
//   GET    /getreports
//   POST   /postreport   { Report }
//   PUT    /putreport    { Report com _id e _rev }
//   DELETE /deletereport { "_id": "...", "_rev": "..." }
// ============================================================

import Foundation

// Body enviado no DELETE (Node-RED não usa path param)
private struct DeleteReportBody: Encodable {
    let _id:  String
    let _rev: String
}

final class ReportService {

    static let shared = ReportService()
    private init() {}

    private let client = APIClient.shared

    // ----------------------------------------------------------
    // MARK: fetchAll — GET /getreports
    // ----------------------------------------------------------
    // Suporta 3 formatos de resposta possíveis do Node-RED:
    //   1) Array direto:     [ { Report }, ... ]
    //   2) Envelope Cloudant: { "rows": [ { "doc": Report } ] }
    //   3) Objeto único:     { Report }  (fallback, vira array de 1)
    //
    // O decode customizado em Report.init(from:) garante que
    // campos ausentes (comments, resolvedAt, etc.) viram nil/[]
    // em vez de travar o decode.
    // ----------------------------------------------------------
    func fetchAll() async throws -> [Report] {
        let data = try await client.requestRaw(path: "/getreports", method: "GET")

        // --- Tentativa 1: array direto ---
        if let reports = try? client.decoder.decode([Report].self, from: data), !reports.isEmpty {
            return reports
        }

        // --- Tentativa 2: envelope Cloudant { rows: [{ doc: Report }] } ---
        if let envelope = try? client.decoder.decode(CloudantListResponse<Report>.self, from: data),
           !envelope.items.isEmpty {
            return envelope.items
        }

        // --- Tentativa 3: array vazio ---
        if let empty = try? client.decoder.decode([Report].self, from: data), empty.isEmpty {
            return []
        }

        // --- Formato não reconhecido ---
        let raw = String(data: data, encoding: .utf8) ?? "(binário não legível)"
        throw APIError.decodingFailed(
            NSError(domain: "ReportService", code: 0,
                    userInfo: [NSLocalizedDescriptionKey:
                        "Formato desconhecido em /getreports.\n\nResposta recebida:\n\(raw)"])
        )
    }

    // ----------------------------------------------------------
    // MARK: create — POST /postreport
    // ----------------------------------------------------------
    // Envia o Report SEM _id e _rev (o Cloudant os gera).
    // Retorna o report com cloudantID/cloudantRev preenchidos
    // a partir do CloudantWriteResponse (id/rev), permitindo
    // editar/votar/excluir imediatamente após criar.
    // ----------------------------------------------------------
    @discardableResult
    func create(_ report: Report) async throws -> Report {
        let data = try await client.requestRaw(
            path: "/postreport",
            method: "POST",
            body: report
        )

        // Decodifica confirmação do Cloudant e extrai id/rev
        let response = try? client.decoder.decode(CloudantWriteResponse.self, from: data)
        if let response, !response.isOk {
            throw APIError.decodingFailed(
                NSError(domain: "ReportService", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Cloudant não confirmou a gravação."])
            )
        }

        var created = report
        if let result = response?.result {
            created.cloudantID  = result.id
            created.cloudantRev = result.rev
        }

        return created
    }

    // ----------------------------------------------------------
    // MARK: update — PUT /putreport
    // ----------------------------------------------------------
    // ATENÇÃO: o report DEVE ter cloudantID e cloudantRev.
    // Sem eles o Cloudant cria um documento novo (DUPLICATA).
    //
    // Esses campos são preenchidos automaticamente no fetchAll()
    // e agora também no create().
    // Após o PUT, o Cloudant gera um novo _rev — atualizamos
    // cloudantRev localmente para o próximo update não precisar
    // de um novo fetchAll().
    // ----------------------------------------------------------
    @discardableResult
    func update(_ report: Report) async throws -> Report {

        // Segurança: bloqueia update sem _id/_rev
        guard report.existsInCloudant else {
            throw APIError.decodingFailed(
                NSError(domain: "ReportService", code: 0,
                        userInfo: [NSLocalizedDescriptionKey:
                            "Update bloqueado: _id/_rev ausentes.\n" +
                            "Recarregue a lista antes de editar."])
            )
        }

        let data = try await client.requestRaw(
            path: "/putreport",
            method: "PUT",
            body: report  // encode() inclui _id e _rev automaticamente
        )

        // Verifica confirmação do Cloudant e atualiza o _rev local com o novo
        let response = try? client.decoder.decode(CloudantWriteResponse.self, from: data)
        if let response, !response.isOk {
            throw APIError.decodingFailed(
                NSError(domain: "ReportService", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Cloudant não confirmou a atualização."])
            )
        }

        var updated = report
        if let newRev = response?.rev {
            updated.cloudantRev = newRev
        }

        return updated
    }

    // ----------------------------------------------------------
    // MARK: delete — DELETE /deletereport
    // ----------------------------------------------------------
    func delete(report: Report) async throws {
        guard let cid = report.cloudantID, let crev = report.cloudantRev else {
            throw APIError.decodingFailed(
                NSError(domain: "ReportService", code: 0,
                        userInfo: [NSLocalizedDescriptionKey:
                            "Delete bloqueado: _id/_rev ausentes."])
            )
        }

        _ = try await client.requestRaw(
            path: "/deletereport",
            method: "DELETE",
            body: DeleteReportBody(_id: cid, _rev: crev)
        )
    }

    // ----------------------------------------------------------
    // MARK: vote / removeVote — reutiliza PUT
    // ----------------------------------------------------------

    @discardableResult
    func vote(report: Report) async throws -> Report {
        var r = report
        r.voteCount += 1
        return try await update(r)
    }

    @discardableResult
    func removeVote(report: Report) async throws -> Report {
        var r = report
        r.voteCount = max(0, r.voteCount - 1)
        return try await update(r)
    }

    // ----------------------------------------------------------
    // MARK: resolve — muda status e faz PUT
    // ----------------------------------------------------------

    @discardableResult
    func resolve(report: Report, comment: String? = nil) async throws -> Report {
        var r = report
        r.status            = .resolved
        r.resolvedAt        = Date()
        r.resolutionComment = comment
        return try await update(r)
    }

    // ----------------------------------------------------------
    // MARK: addComment — adiciona comentário e faz PUT
    // ----------------------------------------------------------

    @discardableResult
    func addComment(
        to report: Report,
        text: String,
        deviceID: String
    ) async throws -> Report {

        // Garante que o documento existe no Cloudant
        guard report.existsInCloudant else {
            throw APIError.decodingFailed(
                NSError(
                    domain: "ReportService",
                    code: 0,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                        "Comentário bloqueado: _id/_rev ausentes."
                    ]
                )
            )
        }

        var updatedReport = report

        let comment = ReportComment(
            id: UUID(),
            deviceID: deviceID,
            text: text,
            createdAt: Date()
        )

        updatedReport.comments.append(comment)

        // update() já envia _id/_rev e atualiza o _rev retornado pelo Cloudant
        return try await update(updatedReport)
    }
}
