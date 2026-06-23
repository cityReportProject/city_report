// UserProfileService.swift
//
// CRUD de UserProfile — endpoints reais do Node-RED (roport_city)
//
//   GET    /getuser                          → [UserProfileRecord]
//   POST   /postuser   { UserProfileRecord } → resposta do Node-RED
//   PUT    /putuser    { UserProfileRecord } → resposta do Node-RED
//   DELETE /deleteuser { "deviceID": "..." } → resposta do Node-RED
//
// Como não há autenticação, o dispositivo é identificado por deviceID
// (UIDevice.identifierForVendor) embutido no payload JSON.

import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Modelo de transferência (inclui deviceID no JSON)

struct UserProfileRecord: Codable {
    var deviceID: String
    var name: String
    var email: String
    var pushNotificationsEnabled: Bool

    init(deviceID: String, profile: UserProfile) {
        self.deviceID = deviceID
        self.name = profile.name
        self.email = profile.email
        self.pushNotificationsEnabled = profile.pushNotificationsEnabled
    }

    var asUserProfile: UserProfile {
        UserProfile(
            name: name,
            email: email,
            pushNotificationsEnabled: pushNotificationsEnabled
        )
    }
}

private struct DeleteUserBody: Encodable {
    let deviceID: String
}

// MARK: - Service

final class UserProfileService {

    static let shared = UserProfileService()
    private init() {}

    private let client = APIClient.shared

    var deviceID: String {
        #if canImport(UIKit)
        return UIDevice.current.identifierForVendor?.uuidString ?? "unknown-device"
        #else
        return "unknown-device"
        #endif
    }

    // MARK: - Listar todos os perfis (GET /getuser)

    func fetchAll() async throws -> [UserProfileRecord] {
        return try await client.request(path: "/getuser")
    }

    // MARK: - Buscar perfil deste dispositivo

    func fetchMine() async throws -> UserProfile? {
        let all = try await fetchAll()
        return all.first(where: { $0.deviceID == deviceID })?.asUserProfile
    }

    // MARK: - Criar perfil (POST /postuser)

    @discardableResult
    func create(_ profile: UserProfile) async throws -> UserProfileRecord {
        guard profile.isEmailValid || profile.email.isEmpty else {
            throw ProfileValidationError.invalidEmail
        }
        let record = UserProfileRecord(deviceID: deviceID, profile: profile)
        return try await client.request(path: "/postuser", method: "POST", body: record)
    }

    // MARK: - Atualizar perfil (PUT /putuser)

    @discardableResult
    func update(_ profile: UserProfile) async throws -> UserProfileRecord {
        guard profile.isEmailValid || profile.email.isEmpty else {
            throw ProfileValidationError.invalidEmail
        }
        let record = UserProfileRecord(deviceID: deviceID, profile: profile)
        return try await client.request(path: "/putuser", method: "PUT", body: record)
    }

    // MARK: - Remover perfil (DELETE /deleteuser)

    func delete() async throws {
        let body = DeleteUserBody(deviceID: deviceID)
        _ = try await client.requestRaw(path: "/deleteuser", method: "DELETE", body: body)
    }
}

// MARK: - Erro de validação

enum ProfileValidationError: LocalizedError {
    case invalidEmail
    var errorDescription: String? { "E-mail inválido. Corrija antes de salvar." }
}
