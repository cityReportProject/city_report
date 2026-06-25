// UserProfileService.swift
//
// CRUD de UserProfile contra o Node-RED + Cloudant.
//
// Mesma lógica do ReportService: POST/PUT devolvem envelope Cloudant,
// não o objeto salvo. Usamos resposta otimista.

import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - DTO com deviceID embutido (enviado ao Node-RED)

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

    // MARK: - Listar todos (GET /getuser)

    func fetchAll() async throws -> [UserProfileRecord] {
        let data = try await client.requestRaw(path: "/getuser", method: "GET")

        // 1) Array direto
        if let records = try? client.decoder.decode([UserProfileRecord].self, from: data) {
            return records
        }

        // 2) Envelope Cloudant { rows: [{ doc: UserProfileRecord }] }
        if let envelope = try? client.decoder.decode(CloudantListResponse<UserProfileRecord>.self, from: data) {
            return envelope.items
        }

        // 3) Array vazio (banco ainda sem documentos)
        if let empty = try? client.decoder.decode([String].self, from: data), empty.isEmpty {
            return []
        }

        throw APIError.decodingFailed(
            NSError(domain: "UserProfileService", code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "Formato de resposta desconhecido em /getuser"])
        )
    }

    // MARK: - Buscar perfil deste dispositivo

    func fetchMine() async throws -> UserProfile? {
        let all = try await fetchAll()
        return all.first(where: { $0.deviceID == deviceID })?.asUserProfile
    }

    // MARK: - Criar (POST /postuser)

    @discardableResult
    func create(_ profile: UserProfile) async throws -> UserProfileRecord {
        guard profile.isEmailValid || profile.email.isEmpty else {
            throw ProfileValidationError.invalidEmail
        }
        let record = UserProfileRecord(deviceID: deviceID, profile: profile)
        let data = try await client.requestRaw(path: "/postuser", method: "POST", body: record)

        // Valida confirmação do Cloudant (ignora erro de decodificação — o objeto foi salvo)
        if let response = try? client.decoder.decode(CloudantWriteResponse.self, from: data),
           response.isOk == false {
            throw APIError.decodingFailed(
                NSError(domain: "UserProfileService", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Cloudant não confirmou a gravação."])
            )
        }

        return record
    }

    // MARK: - Atualizar (PUT /putuser)

    @discardableResult
    func update(_ profile: UserProfile) async throws -> UserProfileRecord {
        guard profile.isEmailValid || profile.email.isEmpty else {
            throw ProfileValidationError.invalidEmail
        }
        let record = UserProfileRecord(deviceID: deviceID, profile: profile)
        let data = try await client.requestRaw(path: "/putuser", method: "PUT", body: record)

        if let response = try? client.decoder.decode(CloudantWriteResponse.self, from: data),
           response.isOk == false {
            throw APIError.decodingFailed(
                NSError(domain: "UserProfileService", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Cloudant não confirmou a atualização."])
            )
        }

        return record
    }

    // MARK: - Remover (DELETE /deleteuser)

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
