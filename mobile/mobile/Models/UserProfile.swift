// UserProfile.swift
// mobile
//
// Histórias de usuário: US21 (preferências de notificação),
//                       US22 (histórico de reportes), US23 (editar perfil)
//
// Nota: sem autenticação, o perfil é persistido localmente no dispositivo.

import Foundation

struct UserProfile: Codable, Hashable {

    // MARK: - Propriedades

    var name: String                         // US23
    var email: String                        // US23
    var pushNotificationsEnabled: Bool       // US21

    // MARK: - Inicializador

    init(
        name: String = "",
        email: String = "",
        pushNotificationsEnabled: Bool = true
    ) {
        self.name = name
        self.email = email
        self.pushNotificationsEnabled = pushNotificationsEnabled
    }

    // MARK: - Validação

    /// US23 — e-mail deve ter formato válido para salvar
    var isEmailValid: Bool {
        let pattern = #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }
}
