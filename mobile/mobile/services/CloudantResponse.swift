// ============================================================
// CloudantResponse.swift
// ============================================================
//
// O Cloudant tem um protocolo próprio de resposta que é diferente
// do objeto que você salva. Este arquivo define os tipos Swift
// para decodificar esses envelopes.
//
// RESPOSTA DE POST / PUT / DELETE:
// {
//   "status": 201,
//   "result": { "ok": true, "id": "abc123", "rev": "2-xyz" }
// }
//
// RESPOSTA DE GET (quando usa view do Cloudant):
// {
//   "total_rows": 3,
//   "rows": [ { "doc": { "_id": "...", "_rev": "...", ...campos } } ]
// }
// ============================================================

import Foundation

// ============================================================
// MARK: - CloudantWriteResponse
// ============================================================
// Decodifica a resposta de POST, PUT e DELETE.
// O campo "rev" dentro do result é o NOVO _rev gerado pelo
// Cloudant após a operação — precisamos dele para atualizar
// o cloudantRev no model local e evitar conflitos.

struct CloudantWriteResponse: Decodable {

    let status: Int?           // código HTTP dentro do body (nem sempre presente)
    let result: CloudantResult?

    struct CloudantResult: Decodable {
        let ok:  Bool           // true = operação bem-sucedida
        let id:  String?        // _id do documento no Cloudant
        let rev: String?        // _rev NOVO gerado após a operação
    }

    /// true se o Cloudant confirmou a operação (ou se não veio result nenhum)
    var isOk: Bool {
        guard let result else { return true } // sem result = assume sucesso
        return result.ok
    }

    /// O _rev novo gerado pelo Cloudant após POST/PUT.
    /// Use-o para atualizar Report.cloudantRev localmente,
    /// assim o próximo update não precisa de fetchAll().
    var rev: String? {
        result?.rev
    }
}

// ============================================================
// MARK: - CloudantListResponse<T>
// ============================================================
// Decodifica resposta de GET que segue o formato de view do Cloudant.
// Suporta o campo "doc" (include_docs=true) e "value".

struct CloudantListResponse<T: Decodable>: Decodable {

    let totalRows: Int?
    let rows: [CloudantRow<T>]?

    enum CodingKeys: String, CodingKey {
        case totalRows = "total_rows"
        case rows
    }

    struct CloudantRow<U: Decodable>: Decodable {
        let doc:   U?   // presente quando include_docs=true
        let value: U?   // alguns flows customizados usam "value"

        var item: U? { doc ?? value }
    }

    /// Extrai os objetos válidos, ignorando linhas sem documento
    var items: [T] {
        rows?.compactMap(\.item) ?? []
    }
}
