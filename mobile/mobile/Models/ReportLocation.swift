// ReportLocation.swift
// mobile
//
// Histórias de usuário: US01 (GPS automático), US02 (localização manual)

import Foundation

struct ReportLocation: Codable, Hashable {

    // MARK: - Propriedades

    var latitude: Double
    var longitude: Double
    var address: String              // US02 — endereço exibido abaixo do mapa

    // MARK: - Inicializador

    init(latitude: Double, longitude: Double, address: String) {
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
    }
}
