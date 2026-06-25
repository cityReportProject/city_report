import Foundation

final class NotificationService {

    static let shared = NotificationService()
    private init() { load() }

    private let storageKey = "com.app.notifications"
    private var items: [AppNotification] = []

    // MARK: - Persistência local simples (UserDefaults)

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let saved = try? JSONDecoder().decode([AppNotification].self, from: data)
        else {
            // seed inicial opcional
            items = seed()
            persist()
            return
        }
        items = saved.sorted { $0.date > $1.date }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    // MARK: - API pública

    func fetchAll() async throws -> [AppNotification] {
        items.sorted { $0.date > $1.date }
    }

    func unreadCount() -> Int {
        items.filter { !$0.isRead }.count
    }

    @discardableResult
    func toggleRead(id: UUID) async throws -> AppNotification {
        guard let idx = items.firstIndex(where: { $0.id == id }) else {
            throw NSError(domain: "NotificationService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Notificação não encontrada"])
        }
        items[idx].isRead.toggle()
        persist()
        return items[idx]
    }

    func delete(id: UUID) async throws {
        items.removeAll { $0.id == id }
        persist()
    }

    @discardableResult
    func markAllRead() async throws -> [AppNotification] {
        items = items.map { n in
            var n = n; n.isRead = true; return n
        }
        persist()
        return items.sorted { $0.date > $1.date }
    }

    func clearAll() async throws {
        items.removeAll()
        persist()
    }

    // MARK: - Helpers

    private func seed() -> [AppNotification] {
        // Dados fictícios para a primeira execução
        return [
            AppNotification(
                title: "Reporte resolvido",
                message: "Seu reporte APP-123 foi marcado como resolvido.",
                date: Date().addingTimeInterval(-60 * 30),
                kind: .reportResolved,
                isRead: false
            ),
            AppNotification(
                title: "Novo voto",
                message: "Seu reporte APP-456 recebeu mais 1 confirmação.",
                date: Date().addingTimeInterval(-60 * 60 * 5),
                kind: .newVote,
                isRead: false
            ),
            AppNotification(
                title: "Bem-vindo!",
                message: "Fique de olho nas melhorias próximas a você.",
                date: Date().addingTimeInterval(-60 * 60 * 24),
                kind: .system,
                isRead: true
            )
        ]
    }
}
