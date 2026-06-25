// MyReportsRegistry.swift
//
// Rastreio local (US22) — quais reports foram criados por este dispositivo.
// Report não tem campo de "dono"; assim como VoteRegistry, isso fica fora do
// modelo de rede e só existe localmente no dispositivo.

import Foundation

struct MyReportsRegistry: Codable {
    var myReportIDs: Set<UUID> = []

    func contains(_ id: UUID) -> Bool {
        myReportIDs.contains(id)
    }

    mutating func add(_ id: UUID) {
        myReportIDs.insert(id)
    }
}
