// ============================================================
// ReportService.swift
// ============================================================
//
// Responsabilidade: todas as operações de Report com o Node-RED.
//
// Endpoints do Node-RED:
//   GET    /getreports              → devolve lista de Reports
//   POST   /postreport   { Report } → cria um Report
//   PUT    /putreport    { Report } → atualiza um Report
//   DELETE /deletereport { "id": "uuid" } → remove um Report
//
// IMPORTANTE sobre POST e PUT:
//   O Cloudant NÃO devolve o objeto salvo — devolve só confirmação.
//   Ex: { "status": 201, "result": { "ok": true, "id": "...", "rev": "..." } }
//   Por isso, após criar/atualizar, devolvemos o próprio objeto
//   que enviamos (chamado de "resposta otimista").
// ============================================================

import Foundation

// ============================================================
// MARK: - Body do DELETE
// ============================================================
// Como o Node-RED não usa parâmetro de rota (/deletereport/:id),
// enviamos o id dentro do corpo JSON mesmo.

private struct DeleteReportBody: Encodable {
    let id: String  // UUID do reporte a ser deletado
}

// ============================================================
// MARK: - ReportService
// ============================================================

final class ReportService {

    // Singleton — o app inteiro usa a mesma instância
    static let shared = ReportService()
    private init() {}

    private let client = APIClient.shared

    // ----------------------------------------------------------
    // MARK: fetchAll — GET /getreports
    // ----------------------------------------------------------
    // Busca todos os reportes do banco.
    //
    // O Node-RED pode devolver dois formatos:
    //   1) Array direto:  [ { Report }, { Report } ]
    //   2) Envelope Cloudant: { "rows": [ { "doc": { Report } } ] }
    //
    // Tentamos os dois para ser compatível com qualquer configuração.
    // ----------------------------------------------------------
    func fetchAll() async throws -> [Report] {
        return try await client.request(path: "/getreport")
    }

        // Pega os bytes brutos da resposta
        let data = try await client.requestRaw(path: "/getreports", method: "GET")

        // Tentativa 1: array direto de Reports
        if let reports = try? client.decoder.decode([Report].self, from: data) {
            return reports
        }

        // Tentativa 2: envelope Cloudant com rows
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

    // ----------------------------------------------------------
    // MARK: create — POST /postreport
    // ----------------------------------------------------------
    // Envia um novo Report ao Node-RED.
    // Retorna o mesmo report que enviamos (otimista) porque o
    // Cloudant não devolve o objeto salvo.
    // @discardableResult = pode ignorar o retorno sem warning.
    // ----------------------------------------------------------
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

    // ----------------------------------------------------------
    // MARK: update — PUT /putreport
    // ----------------------------------------------------------
    // Atualiza um Report existente no banco.
    // Mesma lógica do create: resposta otimista.
    // ----------------------------------------------------------
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

    // ----------------------------------------------------------
    // MARK: delete — DELETE /deletereport
    // ----------------------------------------------------------
    // Remove um Report pelo UUID.
    // O Node-RED não usa path param, então enviamos o id no body.
    // ----------------------------------------------------------
    func delete(id: UUID) async throws {
        let body = DeleteReportBody(id: id.uuidString)
        _ = try await client.requestRaw(
            path: "/deletereport",
            method: "DELETE",
            body: body
        )
        // Não importa o que o Node-RED respondeu — se não lançou erro, deletou.
    }

    // ----------------------------------------------------------
    // MARK: vote — incrementa voteCount e faz PUT
    // ----------------------------------------------------------
    // Como não temos endpoint específico de voto, reutilizamos
    // o PUT com o voteCount incrementado em 1.
    // ----------------------------------------------------------
    @discardableResult
    func vote(report: Report) async throws -> Report {
        var updated = report
        updated.voteCount += 1
        return try await update(updated)
    }

    // ----------------------------------------------------------
    // MARK: removeVote — decrementa voteCount e faz PUT
    // ----------------------------------------------------------
    @discardableResult
    func removeVote(report: Report) async throws -> Report {
        var updated = report
        updated.voteCount = max(0, updated.voteCount - 1)  // nunca negativo
        return try await update(updated)
    }

    // ----------------------------------------------------------
    // MARK: resolve — marca como resolvido e faz PUT
    // ----------------------------------------------------------
    // Altera status para .resolved, grava data/hora e comentário.
    // ----------------------------------------------------------
    @discardableResult
    func resolve(report: Report, comment: String? = nil) async throws -> Report {
        var updated = report
        updated.status = .resolved
        updated.resolvedAt = Date()
        updated.resolutionComment = comment
        return try await update(updated)
    }
}
