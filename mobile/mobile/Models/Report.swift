// ============================================================
// Report.swift
// ============================================================
//
// Model principal do app.
//
// POR QUE DECODE CUSTOMIZADO:
//   O JSONDecoder padrão quebra se um campo não-opcional como
//   `comments: [ReportComment]` não existir no JSON.
//   Documentos antigos no banco não têm esse campo → crash.
//   A solução é implementar init(from:) manualmente e usar
//   decodeIfPresent para campos que podem estar ausentes.
// ============================================================

import Foundation

// ============================================================
// MARK: - ReportComment
// ============================================================
// Comentário anexado a um reporte. Identificado por deviceID
// (sem autenticação — cada aparelho tem seu ID único).

struct ReportComment: Identifiable, Codable, Hashable {
    let id:        UUID    // id local do comentário
    let deviceID:  String  // quem comentou
    let text:      String  // texto do comentário
    let createdAt: Date    // quando foi criado
}

// ============================================================
// MARK: - Report
// ============================================================

struct Report: Identifiable, Codable, Hashable {

    // ----------------------------------------------------------
    // Campos do Cloudant
    // ----------------------------------------------------------
    // Preenchidos automaticamente quando o GET retorna documentos.
    // OBRIGATÓRIOS no PUT para o Cloudant atualizar (não duplicar).
    var cloudantID:  String?  // mapeado para "_id"  no JSON
    var cloudantRev: String?  // mapeado para "_rev" no JSON

    // ----------------------------------------------------------
    // Identificação
    // ----------------------------------------------------------
    let id:             UUID    // UUID gerado pelo app
    let protocolNumber: String  // número de protocolo exibido ao usuário
    let createdAt:      Date    // data/hora de criação

    // ----------------------------------------------------------
    // Conteúdo
    // ----------------------------------------------------------
    var description: String
    var category:    ReportCategory
    var urgency:     UrgencyLevel
    var status:      ReportStatus
    var location:    ReportLocation

    // ----------------------------------------------------------
    // Engajamento
    // ----------------------------------------------------------
    var voteCount: Int             // número de votos
    var comments:  [ReportComment] // comentários dos usuários

    // ----------------------------------------------------------
    // Resolução
    // ----------------------------------------------------------
    var resolvedAt:        Date?    // data de resolução (nil = não resolvido)
    var resolutionComment: String?  // comentário do funcionário

    // ----------------------------------------------------------
    // MARK: Helpers
    // ----------------------------------------------------------

    var isHighCredibility: Bool { voteCount >= 10 }
    var isResolved:        Bool { status == .resolved }
    var existsInCloudant:  Bool { cloudantID != nil && cloudantRev != nil }

    // ----------------------------------------------------------
    // MARK: Inicializador normal (criação local, sem _id/_rev)
    // ----------------------------------------------------------

    init(
        cloudantID:        String?         = nil,
        cloudantRev:       String?         = nil,
        id:                UUID            = UUID(),
        protocolNumber:    String,
        createdAt:         Date            = Date(),
        description:       String,
        category:          ReportCategory,
        urgency:           UrgencyLevel,
        status:            ReportStatus    = .open,
        location:          ReportLocation,
        voteCount:         Int             = 0,
        comments:          [ReportComment] = [],
        resolvedAt:        Date?           = nil,
        resolutionComment: String?         = nil
    ) {
        self.cloudantID        = cloudantID
        self.cloudantRev       = cloudantRev
        self.id                = id
        self.protocolNumber    = protocolNumber
        self.createdAt         = createdAt
        self.description       = description
        self.category          = category
        self.urgency           = urgency
        self.status            = status
        self.location          = location
        self.voteCount         = voteCount
        self.comments          = comments
        self.resolvedAt        = resolvedAt
        self.resolutionComment = resolutionComment
    }

    // ----------------------------------------------------------
    // MARK: CodingKeys
    // ----------------------------------------------------------
    // Mapeia os nomes Swift para as chaves JSON.
    // _id e _rev são os campos internos do Cloudant.

    enum CodingKeys: String, CodingKey {
        case cloudantID  = "_id"
        case cloudantRev = "_rev"
        case id, protocolNumber, createdAt
        case description, category, urgency, status, location
        case voteCount, comments
        case resolvedAt, resolutionComment
    }

    // ----------------------------------------------------------
    // MARK: Decode customizado
    // ----------------------------------------------------------
    // Necessário para lidar com documentos antigos no banco que
    // não têm todos os campos (ex: comments, resolvedAt, etc.).
    // decodeIfPresent retorna nil em vez de lançar erro quando
    // o campo não existe no JSON.

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        // Campos do Cloudant — sempre opcionais
        cloudantID  = try c.decodeIfPresent(String.self, forKey: .cloudantID)
        cloudantRev = try c.decodeIfPresent(String.self, forKey: .cloudantRev)

        // Campos obrigatórios do reporte
        // Se qualquer um destes falhar, o documento é inválido e o erro é lançado
        id             = try c.decode(UUID.self,   forKey: .id)
        protocolNumber = try c.decode(String.self, forKey: .protocolNumber)
        createdAt      = try c.decode(Date.self,   forKey: .createdAt)
        description    = try c.decode(String.self, forKey: .description)
        category       = try c.decode(ReportCategory.self, forKey: .category)
        urgency        = try c.decode(UrgencyLevel.self,   forKey: .urgency)
        status         = try c.decode(ReportStatus.self,   forKey: .status)
        location       = try c.decode(ReportLocation.self, forKey: .location)

        // Campos com fallback — se não existir no JSON, usa valor padrão
        // Isso garante compatibilidade com documentos criados antes dessas features
        voteCount         = (try c.decodeIfPresent(Int.self,              forKey: .voteCount))          ?? 0
        comments          = (try c.decodeIfPresent([ReportComment].self,  forKey: .comments))           ?? []
        resolvedAt        =  try c.decodeIfPresent(Date.self,             forKey: .resolvedAt)
        resolutionComment =  try c.decodeIfPresent(String.self,           forKey: .resolutionComment)
    }

    // ----------------------------------------------------------
    // MARK: Encode customizado
    // ----------------------------------------------------------
    // Necessário porque definimos init(from:) manualmente.
    // Inclui _id e _rev no JSON de saída quando existem,
    // o que é essencial para o PUT do Cloudant funcionar.

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)

        // Só inclui _id e _rev se existirem (PUT exige, POST não deve ter)
        try c.encodeIfPresent(cloudantID,  forKey: .cloudantID)
        try c.encodeIfPresent(cloudantRev, forKey: .cloudantRev)

        try c.encode(id,             forKey: .id)
        try c.encode(protocolNumber, forKey: .protocolNumber)
        try c.encode(createdAt,      forKey: .createdAt)
        try c.encode(description,    forKey: .description)
        try c.encode(category,       forKey: .category)
        try c.encode(urgency,        forKey: .urgency)
        try c.encode(status,         forKey: .status)
        try c.encode(location,       forKey: .location)
        try c.encode(voteCount,      forKey: .voteCount)
        try c.encode(comments,       forKey: .comments)

        try c.encodeIfPresent(resolvedAt,        forKey: .resolvedAt)
        try c.encodeIfPresent(resolutionComment, forKey: .resolutionComment)
    }
}
