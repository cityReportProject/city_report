// MyReportsRegistryService.swift
//
// Persistência local (UserDefaults) do MyReportsRegistry — mesmo padrão de
// VoteRegistryService.

import Foundation

final class MyReportsRegistryService {

    static let shared = MyReportsRegistryService()
    private init() { load() }

    private let storageKey = "com.app.myReportsRegistry"
    private(set) var registry = MyReportsRegistry()

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let saved = try? JSONDecoder().decode(MyReportsRegistry.self, from: data)
        else { return }
        registry = saved
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(registry) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    func isMine(_ id: UUID) -> Bool {
        registry.contains(id)
    }

    func markCreated(_ id: UUID) {
        registry.add(id)
        persist()
    }
}
