// APIClient.swift
// Camada de rede base — endpoints reais do Node-RED (roport_city)
//
// Report Endpoints:
//   GET    /getreports
//   POST   /postreport    { ...Report }
//   PUT    /putreport     { ...Report }
//   DELETE /deletereport  { "id": "uuid" }
//
// User Endpoints:
//   GET    /getuser
//   POST   /postuser      { ...UserProfile + deviceID }
//   PUT    /putuser       { ...UserProfile + deviceID }
//   DELETE /deleteuser    { "deviceID": "..." }

import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case encodingFailed(Error)
    case networkError(Error)
    case unexpectedStatusCode(Int, Data)
    case decodingFailed(Error)
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL:                       return "URL inválida."
        case .encodingFailed(let e):            return "Falha ao codificar: \(e.localizedDescription)"
        case .networkError(let e):              return "Erro de rede: \(e.localizedDescription)"
        case .unexpectedStatusCode(let c, _):   return "Status inesperado: \(c)"
        case .decodingFailed(let e):            return "Falha ao decodificar: \(e.localizedDescription)"
        case .noData:                           return "Nenhum dado recebido."
        }
    }
}

final class APIClient {

    // MARK: - Configuração — altere o IP para o da máquina com Node-RED
    static var baseURL = "http://192.168.128.29:1880"

    static let shared = APIClient()
    private init() {}

    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 15
        return URLSession(configuration: cfg)
    }()

    let encoder: JSONEncoder = {
        let e = JSONEncoder()
//        e.dateEncodingStrategy = .iso8601
        return e
    }()

    let decoder: JSONDecoder = {
        let d = JSONDecoder()
//        d.dateDecodingStrategy = .iso8601
        return d
    }()

    // MARK: - Request com resposta decodificável

    func request<T: Decodable>(
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

        return data
    }
}

// MARK: - Type-erased Encodable

private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    init(_ value: Encodable) { _encode = value.encode }
    func encode(to encoder: Encoder) throws { try _encode(encoder) }
}
