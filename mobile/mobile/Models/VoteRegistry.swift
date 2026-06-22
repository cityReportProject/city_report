// VoteRegistry.swift
// mobile
//
// Histórias de usuário: US12 (votar uma vez por reporte por dispositivo)
//
// Nota: sem autenticação, o controle de voto é feito por dispositivo.
//       Este modelo é persistido apenas localmente (UserDefaults ou arquivo local)
//       e nunca sincronizado com a API.

import Foundation

struct VoteRegistry: Codable {

    // MARK: - Propriedades

    /// IDs dos reportes em que este dispositivo já votou
    var votedReportIDs: Set<UUID>

    // MARK: - Inicializador

    init(votedReportIDs: Set<UUID> = []) {
        self.votedReportIDs = votedReportIDs
    }

    // MARK: - Operações

    /// US12 — verifica se o dispositivo já votou neste reporte
    func hasVoted(on reportID: UUID) -> Bool {
        votedReportIDs.contains(reportID)
    }

    /// US12 — registra voto; retorna false se já tinha votado
    mutating func vote(on reportID: UUID) -> Bool {
        guard !hasVoted(on: reportID) else { return false }
        votedReportIDs.insert(reportID)
        return true
    }

    /// US12 — remove voto (desfazer)
    mutating func removeVote(on reportID: UUID) {
        votedReportIDs.remove(reportID)
    }
}
