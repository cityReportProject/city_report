// ReportCategory.swift
// mobile
//
// Histórias de usuário: US04 (seleção pelo cidadão), US09 (filtro cidadão),
//                       US18 (filtro prefeitura)

import Foundation

enum ReportCategory: String, Codable, CaseIterable, Hashable {

    case pavement       = "Pavimentação"
    case lighting       = "Iluminação"
    case sewage         = "Esgoto"
    case waterSupply    = "Abastecimento de Água"
    case wasteCollection = "Coleta de Lixo"
    case environment    = "Meio Ambiente"
    case other          = "Outros"

    // MARK: - Helpers de UI

    /// US04 — ícone SF Symbol associado a cada categoria
    var icon: String {
        switch self {
        case .pavement:         return "road.lanes"
        case .lighting:         return "lightbulb"
        case .sewage:           return "drop.triangle"
        case .waterSupply:      return "drop"
        case .wasteCollection:  return "trash"
        case .environment:      return "leaf"
        case .other:            return "exclamationmark.circle"
        }
    }

    /// Rótulo de exibição (equivalente ao rawValue)
    var label: String { rawValue }
}
