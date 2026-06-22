// UrgencyLevel.swift
// mobile
//
// Histórias de usuário: US05 (definição pelo cidadão), US08 (pin colorido),
//                       US10 (filtro no painel da prefeitura), US17 (ordenação por urgência)

import Foundation

enum UrgencyLevel: String, Codable, CaseIterable, Hashable, Comparable {

    case low    = "Baixa"
    case medium = "Média"
    case high   = "Alta"

    // MARK: - Comparable (low < medium < high)

    private var order: Int {
        switch self {
        case .low:    return 0
        case .medium: return 1
        case .high:   return 2
        }
    }

    static func < (lhs: UrgencyLevel, rhs: UrgencyLevel) -> Bool {
        lhs.order < rhs.order
    }

    // MARK: - Helpers de UI

    /// US08 — nome do asset de cor no catálogo (definir AccentColor equivalentes)
    var colorName: String {
        switch self {
        case .low:    return "UrgencyLow"
        case .medium: return "UrgencyMedium"
        case .high:   return "UrgencyHigh"
        }
    }

    /// US05 — dica de quando usar cada nível
    var hint: String {
        switch self {
        case .low:
            return "Problema que não oferece risco imediato, mas precisa de atenção."
        case .medium:
            return "Problema que pode se agravar ou afetar muitas pessoas."
        case .high:
            return "Risco imediato à segurança ou saúde pública."
        }
    }

    /// Rótulo de exibição (equivalente ao rawValue)
    var label: String { rawValue }
}
