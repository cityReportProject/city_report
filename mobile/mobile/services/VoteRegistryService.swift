import Foundation

final class VoteRegistryService {

    static let shared = VoteRegistryService()
    private init() { load() }

    private let storageKey = "com.app.voteRegistry"
    private(set) var registry = VoteRegistry()

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let saved = try? JSONDecoder().decode(VoteRegistry.self, from: data)
        else { return }
        registry = saved
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(registry) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    func hasVoted(on reportID: UUID) -> Bool {
        registry.hasVoted(on: reportID)
    }

    @discardableResult
    func vote(on report: Report) async throws -> Report {
        guard registry.vote(on: report.id) else { throw VoteError.alreadyVoted }
        persist()
        do {
            return try await ReportService.shared.vote(report: report)
        } catch {
            registry.removeVote(on: report.id)
            persist()
            throw error
        }
    }

    @discardableResult
    func removeVote(from report: Report) async throws -> Report {
        guard registry.hasVoted(on: report.id) else { throw VoteError.notVoted }
        registry.removeVote(on: report.id)
        persist()
        do {
            return try await ReportService.shared.removeVote(report: report)
        } catch {
            _ = registry.vote(on: report.id)
            persist()
            throw error
        }
    }
}

enum VoteError: LocalizedError {
    case alreadyVoted, notVoted
    var errorDescription: String? {
        switch self {
        case .alreadyVoted: return "Você já votou neste reporte."
        case .notVoted:     return "Nenhum voto registrado para desfazer."
        }
    }
}
