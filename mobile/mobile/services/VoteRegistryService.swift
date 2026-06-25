// ============================================================
// VoteRegistryService.swift
// ============================================================
//
// Controla os votos localmente no dispositivo (US12).
// Regra: um voto por reporte por dispositivo.
//
// Funciona em duas camadas:
//   1) LOCAL (UserDefaults): salva quais reportes este dispositivo
//      já votou. Persiste entre sessões do app.
//   2) REMOTO (ReportService.vote/removeVote): faz o PUT no
//      Node-RED com o voteCount atualizado.
//
// Se a chamada remota falhar, o voto local é revertido para
// manter consistência entre app e banco.
// ============================================================

import Foundation

final class VoteRegistryService {

    static let shared = VoteRegistryService()

    // Chave usada para salvar no UserDefaults
    private let storageKey = "com.app.voteRegistry"

    // Registro em memória (carregado do UserDefaults no init)
    private(set) var registry = VoteRegistry()

    private init() {
        load() // carrega votos salvos ao inicializar
    }

    // ----------------------------------------------------------
    // MARK: Persistência local
    // ----------------------------------------------------------

    /// Lê o VoteRegistry salvo no UserDefaults
    private func load() {
        guard
            let data  = UserDefaults.standard.data(forKey: storageKey),
            let saved = try? JSONDecoder().decode(VoteRegistry.self, from: data)
        else { return }
        registry = saved
    }

    /// Grava o VoteRegistry atual no UserDefaults
    private func persist() {
        guard let data = try? JSONEncoder().encode(registry) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    // ----------------------------------------------------------
    // MARK: Consulta
    // ----------------------------------------------------------

    /// Retorna true se este dispositivo já votou neste reporte
    func hasVoted(on reportID: UUID) -> Bool {
        registry.hasVoted(on: reportID)
    }

    // ----------------------------------------------------------
    // MARK: Votar
    // ----------------------------------------------------------
    // Fluxo:
    //   1. Tenta registrar localmente (falha se já votou)
    //   2. Persiste no UserDefaults
    //   3. Faz PUT no Node-RED com voteCount + 1
    //   4. Se o PUT falhar, DESFAZ o voto local
    // ----------------------------------------------------------
    @discardableResult
    func vote(on report: Report) async throws -> Report {

        // Passo 1: tenta registrar localmente
        // VoteRegistry.vote() retorna false se já votou neste reporte
        guard registry.vote(on: report.id) else {
            throw VoteError.alreadyVoted
        }

        // Passo 2: persiste localmente
        persist()

        // Passo 3: tenta salvar no Node-RED
        do {
            return try await ReportService.shared.vote(report: report)
        } catch {
            // Passo 4: reverte o voto local se a rede falhou
            registry.removeVote(on: report.id)
            persist()
            throw error
        }
    }

    // ----------------------------------------------------------
    // MARK: Desfazer voto
    // ----------------------------------------------------------
    // Fluxo inverso ao de votar.
    // ----------------------------------------------------------
    @discardableResult
    func removeVote(from report: Report) async throws -> Report {

        // Verifica se tinha votado antes de tentar remover
        guard registry.hasVoted(on: report.id) else {
            throw VoteError.notVoted
        }

        // Remove localmente primeiro
        registry.removeVote(on: report.id)
        persist()

        // Tenta salvar no Node-RED
        do {
            return try await ReportService.shared.removeVote(report: report)
        } catch {
            // Reverte: re-adiciona o voto local se a rede falhou
            _ = registry.vote(on: report.id)
            persist()
            throw error
        }
    }
}

// ============================================================
// MARK: - VoteError
// ============================================================

enum VoteError: LocalizedError {
    case alreadyVoted  // tentou votar duas vezes
    case notVoted      // tentou remover voto que não existe

    var errorDescription: String? {
        switch self {
        case .alreadyVoted: return "Você já votou neste reporte."
        case .notVoted:     return "Nenhum voto para remover."
        }
    }
}
