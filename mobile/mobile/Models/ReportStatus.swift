// ReportStatus.swift
// mobile
//
// Histórias de usuário: US10 (filtro por status no mapa),
//                       US13 (exibição no card de detalhes),
//                       US16 (marcar como resolvido)

import Foundation

enum ReportStatus: String, Codable, CaseIterable, Hashable {

    case open     = "Aberto"
    case resolved = "Resolvido"

    // MARK: - Helpers de UI

    /// US10 — ícone SF Symbol para cada status
    var icon: String {
        switch self {
        case .open:     return "clock"
        case .resolved: return "checkmark.circle"
        }
    }

    /// Rótulo de exibição (equivalente ao rawValue)
    var label: String { rawValue }
}
