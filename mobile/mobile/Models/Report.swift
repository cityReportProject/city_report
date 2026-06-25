// Model para report de usuario

import Foundation

struct Report: Identifiable, Codable, Hashable {

    // MARK: - Propriedades

    let id: UUID
    let protocolNumber: String       // US06 — número de protocolo exibido na confirmação
    let createdAt: Date

    var description: String          // US03
    var category: ReportCategory     // US04
    var urgency: UrgencyLevel        // US05
    var status: ReportStatus         // US10, US13, US16
    var location: ReportLocation     // US01, US02

    var voteCount: Int               // US12, US13 — score de credibilidade
    var resolvedAt: Date?            // US16 — preenchido ao marcar como resolvido
    var resolutionComment: String?   // US16 — comentário opcional do funcionário

    // MARK: - Inicializador

    init(
        id: UUID = UUID(),
        protocolNumber: String,
        createdAt: Date = Date(),
        description: String,
        category: ReportCategory,
        urgency: UrgencyLevel,
        status: ReportStatus = .open,
        location: ReportLocation,
        voteCount: Int = 0,
        resolvedAt: Date? = nil,
        resolutionComment: String? = nil
    ) {
        self.id = id
        self.protocolNumber = protocolNumber
        self.createdAt = createdAt
        self.description = description
        self.category = category
        self.urgency = urgency
        self.status = status
        self.location = location
        self.voteCount = voteCount
        self.resolvedAt = resolvedAt
        self.resolutionComment = resolutionComment
    }

    // MARK: - Helpers

    /// US13 — credibilidade alta: acima de 10 votos
    var isHighCredibility: Bool {
        voteCount >= 10
    }

    /// US16 — verifica se o reporte está resolvido
    var isResolved: Bool {
        status == .resolved
    }
}
