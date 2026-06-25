import Foundation

struct CloudantWriteResponse: Decodable {

    // Código HTTP dentro do corpo (nem sempre presente)
    let status: Int?

    // O bloco "result" com a confirmação do banco
    let result: CloudantResult?

    struct CloudantResult: Decodable {
        let ok: Bool       // true = gravado com sucesso
        let id: String?    // id do documento no Cloudant
        let rev: String?   // revisão (versão) do documento
    }

    // Atalho: retorna true se o Cloudant confirmou a gravação
    var isOk: Bool {
        // Se não veio resultado nenhum, assumimos sucesso
        // (alguns flows do Node-RED respondem só o status HTTP)
        guard let result else { return true }
        return result.ok
    }
}

struct CloudantListResponse<T: Decodable>: Decodable {

    let totalRows: Int?
    let rows: [CloudantRow<T>]?

    // Mapeia "total_rows" do JSON para totalRows no Swift
    enum CodingKeys: String, CodingKey {
        case totalRows = "total_rows"
        case rows
    }

    // Cada linha do Cloudant pode trazer o objeto em "doc" ou "value"
    struct CloudantRow<U: Decodable>: Decodable {
        let doc: U?    // formato padrão Cloudant view com include_docs
        let value: U?  // alguns flows customizados usam "value"

        // Tenta doc primeiro, depois value
        var item: U? { doc ?? value }
    }

    // Extrai apenas os objetos válidos (ignora linhas sem doc)
    var items: [T] {
        rows?.compactMap(\.item) ?? []
    }
}
