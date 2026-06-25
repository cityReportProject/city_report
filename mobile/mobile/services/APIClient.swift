// ============================================================
// APIClient.swift
// ============================================================
//
// Responsabilidade: fazer requisições HTTP ao Node-RED.
//
// Como funciona o fluxo:
//   App Swift  →  APIClient  →  Node-RED  →  Cloudant (banco)
//
// O Cloudant fica atrás do Node-RED — o app nunca fala direto
// com o banco, só com o Node-RED.
// ============================================================

import Foundation

// ============================================================
// MARK: - Erros personalizados
// ============================================================
// Cada caso representa um tipo de falha diferente que pode
// acontecer durante uma requisição.

enum APIError: LocalizedError {
    case invalidURL                        // URL montada ficou inválida
    case encodingFailed(Error)             // falhou ao converter Swift → JSON
    case networkError(Error)               // sem internet / Node-RED offline
    case unexpectedStatusCode(Int, Data)   // servidor respondeu fora de 200-299
    case decodingFailed(Error)             // JSON da resposta não bate com o modelo Swift
    case noData                            // servidor respondeu vazio quando não devia

    // Mensagem legível para mostrar na UI
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL inválida. Verifique o baseURL em APIClient."
        case .encodingFailed(let e):
            return "Erro ao serializar dados: \(e.localizedDescription)"
        case .networkError(let e):
            return "Erro de rede: \(e.localizedDescription)"
        case .unexpectedStatusCode(let code, _):
            return "Servidor retornou status \(code)."
        case .decodingFailed(let e):
            return "Erro ao ler resposta: \(e.localizedDescription)"
        case .noData:
            return "Resposta vazia do servidor."
        }
    }
}

// ============================================================
// MARK: - APIClient
// ============================================================

final class APIClient {

    // MARK: - Configuração — altere o IP para o da máquina com Node-RED
    static var baseURL = "http://192.168.128.29:1880"

    // Singleton — o app inteiro usa a mesma instância
    static let shared = APIClient()
    private init() {}

    // ----------------------------------------------------------
    // URLSession com timeout de 15 s
    // ----------------------------------------------------------
    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 15
        return URLSession(configuration: cfg)
    }()

    // ----------------------------------------------------------
    // Encoder: Swift → JSON  (datas em ISO 8601: "2025-06-01T10:00:00Z")
    // ----------------------------------------------------------
    let encoder: JSONEncoder = {
        let e = JSONEncoder()
//        e.dateEncodingStrategy = .iso8601
        return e
    }()

    // ----------------------------------------------------------
    // Decoder: JSON → Swift  (datas em ISO 8601)
    // ----------------------------------------------------------
    let decoder: JSONDecoder = {
        let d = JSONDecoder()
//        d.dateDecodingStrategy = .iso8601
        return d
    }()

    // ----------------------------------------------------------
    // MARK: requestRaw — envia a requisição e devolve Data bruta
    // ----------------------------------------------------------
    // Todos os métodos de serviço usam este como base.
    // Retorna os bytes crus da resposta para que cada serviço
    // possa interpretar o formato certo (o Cloudant tem envelopes
    // diferentes dependendo da operação).
    //
    // Parâmetros:
    //   path   → ex: "/getreports"
    //   method → "GET", "POST", "PUT", "DELETE"
    //   body   → qualquer struct Encodable (opcional)
    // ----------------------------------------------------------
    func requestRaw(
        path: String,
        method: String = "GET",
        body: Encodable? = nil
    ) async throws -> T {
        guard let url = URL(string: APIClient.baseURL + path) else {
            throw APIError.invalidURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body {
            do { req.httpBody = try encoder.encode(AnyEncodable(body)) }
            catch { throw APIError.encodingFailed(error) }
        }

        let (data, response): (Data, URLResponse)
        do { (data, response) = try await session.data(for: req) }
        catch { throw APIError.networkError(error) }

        if let http = response as? HTTPURLResponse,
           !(200...299).contains(http.statusCode) {
            throw APIError.unexpectedStatusCode(http.statusCode, data)
        }

        do { return try decoder.decode(T.self, from: data) }
        catch { throw APIError.decodingFailed(error) }
    }
    
    func request(
        path: String,
        method: String = "GET",
        body: Encodable? = nil
    ) async throws {
        guard let url = URL(string: APIClient.baseURL + path) else {
            throw APIError.invalidURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body {
            do { req.httpBody = try JSONEncoder().encode(body) }
//            do { req.httpBody = try encoder.encode(AnyEncodable(body)) }
            catch { throw APIError.encodingFailed(error) }
        }

        let (data, response): (Data, URLResponse)
        do { (data, response) = try await session.data(for: req) }
        catch { throw APIError.networkError(error) }

        if let http = response as? HTTPURLResponse,
           !(200...299).contains(http.statusCode) {
            throw APIError.unexpectedStatusCode(http.statusCode, data)
        }
    }

    // MARK: - Request sem corpo de resposta esperado

    func requestRaw(
        path: String,
        method: String,
        body: Encodable? = nil
    ) async throws -> Data {

        // 1. Monta a URL completa
        guard let url = URL(string: APIClient.baseURL + path) else {
            throw APIError.invalidURL
        }

        // 2. Configura a requisição
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // 3. Se houver body, converte para JSON e anexa
        if let body {
            do {
                req.httpBody = try encoder.encode(AnyEncodable(body))
            } catch {
                throw APIError.encodingFailed(error)
            }
        }

        // 4. Faz a chamada de rede (await = espera sem travar a thread)
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw APIError.networkError(error)
        }

        // 5. Verifica o status HTTP
        if let http = response as? HTTPURLResponse,
           !(200...299).contains(http.statusCode) {
            throw APIError.unexpectedStatusCode(http.statusCode, data)
        }

        return data
    }

    // ----------------------------------------------------------
    // MARK: request<T> — versão com decodificação automática
    // ----------------------------------------------------------
    // Atalho para quando a resposta já é diretamente o tipo T.
    // Internamente chama requestRaw e depois decodifica.
    // ----------------------------------------------------------
    func request<T: Decodable>(
        path: String,
        method: String = "GET",
        body: Encodable? = nil
    ) async throws -> T {
        let data = try await requestRaw(path: path, method: method, body: body)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed(error)
        }
    }
}

// ============================================================
// MARK: - AnyEncodable (helper interno)
// ============================================================
// O Swift não permite passar `Encodable` diretamente para o
// encoder porque é um protocolo com Self. Este wrapper apaga
// o tipo concreto e permite usar qualquer Encodable.

private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    init(_ value: Encodable) { _encode = value.encode }
    func encode(to encoder: Encoder) throws { try _encode(encoder) }
}
