import Foundation

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


final class APIClient {
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
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    // Decoder: JSON -> Swift
    let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    
    func requestRaw(
        path: String,
        method: String = "GET",
        body: Encodable? = nil
    ) async throws -> Data {

        // Monta a URL completa
        guard let url = URL(string: APIClient.baseURL + path) else {
            throw APIError.invalidURL
        }

        // Configura a requisição
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Se houver body, converte para JSON e anexa
        if let body {
            do {
                req.httpBody = try encoder.encode(AnyEncodable(body))
            } catch {
                throw APIError.encodingFailed(error)
            }
        }

        // Faz a chamada de rede (await = espera sem travar a thread)
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw APIError.networkError(error)
        }

        // Verifica o status HTTP
        if let http = response as? HTTPURLResponse,
           !(200...299).contains(http.statusCode) {
            throw APIError.unexpectedStatusCode(http.statusCode, data)
        }

        return data
    }

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

private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    init(_ value: Encodable) { _encode = value.encode }
    func encode(to encoder: Encoder) throws { try _encode(encoder) }
}
