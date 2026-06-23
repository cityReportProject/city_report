// ReportService.swift
//
// CRUD de Report — endpoints reais do Node-RED (roport_city)
//
//   GET    /getreports              → [Report]
//   POST   /postreport   { Report } → resposta do Node-RED
//   PUT    /putreport    { Report } → resposta do Node-RED
//   DELETE /deletereport { "id": "uuid" } → resposta do Node-RED

import Foundation

// Wrapper para DELETE (Node-RED sem parâmetro de path)
private struct DeleteReportBody: Encodable {
    let id: String
}

final class ReportService {

    static let shared = ReportService()
    private init() {}

    private let client = APIClient.shared

    // MARK: - Listar todos (GET /getreports)

    func fetchAll() async throws -> [Report] {
        return try await client.request(path: "/getreports")
    }

    // MARK: - Criar (POST /postreport)

    @discardableResult
    func create(_ report: Report) async throws -> Report {
        return try await client.request(
            path: "/postreport",
            method: "POST",
            body: report
        )
    }

    // MARK: - Atualizar (PUT /putreport)

    @discardableResult
    func update(_ report: Report) async throws -> Report {
        return try await client.request(
            path: "/putreport",
            method: "PUT",
            body: report
        )
    }

    // MARK: - Remover (DELETE /deletereport)
    // Node-RED não aceita path param, então envia id no body

    func delete(id: UUID) async throws {
        let body = DeleteReportBody(id: id.uuidString)
        _ = try await client.requestRaw(
            path: "/deletereport",
            method: "DELETE",
            body: body
        )
    }

    // MARK: - Votar (reutiliza PUT /putreport incrementando voteCount)

    @discardableResult
    func vote(report: Report) async throws -> Report {
        var updated = report
        updated.voteCount += 1
        return try await update(updated)
    }

    @discardableResult
    func removeVote(report: Report) async throws -> Report {
        var updated = report
        updated.voteCount = max(0, updated.voteCount - 1)
        return try await update(updated)
    }

    // MARK: - Resolver (reutiliza PUT /putreport)

    @discardableResult
    func resolve(report: Report, comment: String? = nil) async throws -> Report {
        var updated = report
        updated.status = .resolved
        updated.resolvedAt = Date()
        updated.resolutionComment = comment
        return try await update(updated)
    }
}
