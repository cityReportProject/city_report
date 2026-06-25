// ============================================================
// ContentView.swift
// ============================================================
//
// Interface principal do app. Estrutura de navegação:
//
//   TabView
//   ├── ReportsListView       (lista de todos os reportes)
//   │   └── ReportDetailView  (detalhe + comentários + ações)
//   │       └── EditReportView    (editar campos)
//   │       └── ResolveReportView (marcar como resolvido)
//   │       └── CommentsView      (ver e adicionar comentários)
//   └── ProfileView           (perfil do usuário)
//
// Badges auxiliares ao final do arquivo:
//   UrgencyBadge, StatusBadge
// ============================================================

import SwiftUI

// ============================================================
// MARK: - ContentView (raiz do app)
// ============================================================

struct ContentView: View {
    var body: some View {
        TabView {
            ReportsListView()
                .tabItem {
                    Label("Reportes", systemImage: "list.bullet.clipboard")
                }
            ProfileView()
                .tabItem {
                    Label("Perfil", systemImage: "person.circle")
                }
        }
    }
}

// ============================================================
// MARK: - ReportsListView
// ============================================================
// Lista todos os reportes vindos do Node-RED.
// Ao carregar, já temos _id e _rev em cada report (do GET),
// o que permite fazer PUT/DELETE sem duplicar.

struct ReportsListView: View {

    @State private var reports:      [Report] = []
    @State private var isLoading:    Bool     = false
    @State private var errorMessage: String?  = nil
    @State private var showingCreate: Bool    = false

    var body: some View {
        NavigationStack {
            Group {

                // --- Estado: carregando ---
                if isLoading {
                    ProgressView("Carregando...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                // --- Estado: erro de rede ---
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.system(size: 44))
                            .foregroundStyle(.secondary)
                        Text(error)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        Button("Tentar novamente") {
                            Task { await loadReports() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // --- Estado: lista vazia ---
                } else if reports.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 44))
                            .foregroundStyle(.secondary)
                        Text("Nenhum reporte ainda.")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // --- Estado: lista com itens ---
                } else {
                    List {
                        ForEach(reports) { report in
                            NavigationLink(
                                destination: ReportDetailView(
                                    report: report,
                                    // Callback: atualiza o item na lista sem recarregar tudo
                                    onUpdate: { updated in
                                        if let idx = reports.firstIndex(where: { $0.id == updated.id }) {
                                            reports[idx] = updated
                                        }
                                    },
                                    // Callback: remove o item da lista
                                    onDelete: { id in
                                        reports.removeAll { $0.id == id }
                                    }
                                )
                            ) {
                                ReportRowView(report: report)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Reportes")
            .toolbar {
                // Botão de atualizar (↺)
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task { await loadReports() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                // Botão de criar novo reporte (+)
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreate = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            // Sheet de criação de reporte
            .sheet(isPresented: $showingCreate) {
                CreateReportView { newReport in
                    reports.insert(newReport, at: 0)
                }
            }
            // Carrega ao aparecer na tela
            .task { await loadReports() }
        }
    }

    /// Chama GET /getreports e popula a lista.
    /// Após este fetch, cada Report tem cloudantID e cloudantRev preenchidos.
    private func loadReports() async {
        isLoading    = true
        errorMessage = nil
        do {
            reports = try await ReportService.shared.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// ============================================================
// MARK: - ReportRowView
// ============================================================
// Célula da lista. Mostra categoria, urgência, status, votos e data.

struct ReportRowView: View {
    let report: Report

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            // Linha 1: ícone + categoria + badges
            HStack {
                Image(systemName: report.category.icon)
                    .foregroundStyle(.secondary)
                Text(report.category.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                UrgencyBadge(urgency: report.urgency)
                StatusBadge(status: report.status)
            }

            // Linha 2: descrição (máx 2 linhas)
            Text(report.description)
                .font(.subheadline)
                .lineLimit(2)

            // Linha 3: votos + comentários + data
            HStack {
                Image(systemName: "hand.thumbsup")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(report.voteCount)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Image(systemName: "bubble.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(report.comments.count)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()
                Text(report.createdAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// ============================================================
// MARK: - ReportDetailView
// ============================================================
// Exibe todos os dados de um reporte e oferece ações:
// editar, votar, resolver, comentar e excluir.

struct ReportDetailView: View {

    @State var report: Report
    var onUpdate: (Report) -> Void
    var onDelete: (UUID)   -> Void

    @State private var showingEdit:      Bool    = false
    @State private var showingResolve:   Bool    = false
    @State private var showingComments:  Bool    = false
    @State private var isVoting:         Bool    = false
    @State private var isDeleting:       Bool    = false
    @State private var errorMessage:     String? = nil

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {

            // --- Seção: informações gerais ---
            Section {
                LabeledContent("Protocolo", value: report.protocolNumber)
                LabeledContent("Categoria", value: report.category.label)
                LabeledContent("Urgência",  value: report.urgency.label)
                LabeledContent("Status",    value: report.status.label)
                LabeledContent("Data",      value: report.createdAt.formatted(
                    date: .abbreviated, time: .shortened))
            }

            // --- Seção: descrição ---
            Section("Descrição") {
                Text(report.description)
            }

            // --- Seção: localização ---
            Section("Localização") {
                Text(report.location.address)
                LabeledContent("Lat", value: String(format: "%.6f", report.location.latitude))
                LabeledContent("Lng", value: String(format: "%.6f", report.location.longitude))
            }

            // --- Seção: votos ---
            Section("Credibilidade") {
                HStack {
                    Image(systemName: "hand.thumbsup.fill")
                    Text("\(report.voteCount) votos")
                    Spacer()
                    // Badge de alta credibilidade (≥10 votos)
                    if report.isHighCredibility {
                        Label("Alta credibilidade", systemImage: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }

                // Botão de votar / remover voto
                let hasVoted = VoteRegistryService.shared.hasVoted(on: report.id)
                Button {
                    Task { await toggleVote(hasVoted: hasVoted) }
                } label: {
                    HStack {
                        if isVoting { ProgressView().scaleEffect(0.7) }
                        Text(hasVoted ? "Remover voto" : "Votar neste reporte")
                    }
                }
                .disabled(isVoting)
            }

            // --- Seção: comentários ---
            Section("Comentários") {
                // Preview: mostra os 2 últimos comentários
                if report.comments.isEmpty {
                    Text("Nenhum comentário ainda.")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                } else {
                    ForEach(report.comments.suffix(2)) { comment in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(comment.text)
                                .font(.subheadline)
                            Text(comment.createdAt, style: .relative)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Botão para abrir a tela completa de comentários
                Button {
                    showingComments = true
                } label: {
                    Label(
                        report.comments.count > 2
                            ? "Ver todos os \(report.comments.count) comentários"
                            : "Adicionar comentário",
                        systemImage: "bubble.right"
                    )
                }
            }

            // --- Seção: resolução (só aparece se resolvido) ---
            if report.isResolved, let resolvedAt = report.resolvedAt {
                Section("Resolução") {
                    LabeledContent("Resolvido em",
                                   value: resolvedAt.formatted(date: .abbreviated, time: .shortened))
                    if let comment = report.resolutionComment {
                        Text(comment)
                    }
                }
            }

            // --- Seção: mensagem de erro (se houver) ---
            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }

            // --- Seção: ações ---
            Section {
                Button("Editar reporte") { showingEdit = true }

                if !report.isResolved {
                    Button("Marcar como resolvido") { showingResolve = true }
                        .foregroundStyle(.green)
                }

                Button(role: .destructive) {
                    Task { await deleteReport() }
                } label: {
                    HStack {
                        if isDeleting { ProgressView().scaleEffect(0.7) }
                        Text("Excluir reporte")
                    }
                }
                .disabled(isDeleting)
            }
        }
        .navigationTitle("Reporte")
        .navigationBarTitleDisplayMode(.inline)
        // Sheet: editar campos do reporte
        .sheet(isPresented: $showingEdit) {
            EditReportView(report: report) { updated in
                report = updated
                onUpdate(updated)
            }
        }
        // Alert: confirmar resolução
        .alert("Marcar como resolvido?", isPresented: $showingResolve) {
            Button("Confirmar") { Task { await resolveReport() } }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Esta ação não pode ser desfeita.")
        }
        // Sheet: tela de comentários
        .sheet(isPresented: $showingComments) {
            CommentsView(report: report) { updated in
                report = updated
                onUpdate(updated)
            }
        }
    }

    // ----------------------------------------------------------
    // Alternar voto (votar ou remover voto)
    // ----------------------------------------------------------
    private func toggleVote(hasVoted: Bool) async {
        isVoting     = true
        errorMessage = nil
        do {
            let updated: Report
            if hasVoted {
                updated = try await VoteRegistryService.shared.removeVote(from: report)
            } else {
                updated = try await VoteRegistryService.shared.vote(on: report)
            }
            report = updated
            onUpdate(updated)
        } catch {
            errorMessage = error.localizedDescription
        }
        isVoting = false
    }

    // ----------------------------------------------------------
    // Marcar como resolvido
    // ----------------------------------------------------------
    private func resolveReport() async {
        errorMessage = nil
        do {
            let updated = try await ReportService.shared.resolve(report: report)
            report = updated
            onUpdate(updated)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // ----------------------------------------------------------
    // Excluir reporte
    // ----------------------------------------------------------
    private func deleteReport() async {
        isDeleting   = true
        errorMessage = nil
        do {
            try await ReportService.shared.delete(report: report)
            onDelete(report.id)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            isDeleting = false
        }
    }
}

// ============================================================
// MARK: - CommentsView
// ============================================================
// Exibe todos os comentários do reporte e permite adicionar novos.

struct CommentsView: View {

    @State var report: Report
    var onUpdate: (Report) -> Void

    @State private var newCommentText: String  = ""
    @State private var isSaving:       Bool    = false
    @State private var errorMessage:   String? = nil

    @Environment(\.dismiss) private var dismiss

    // DeviceID do usuário atual (identifica o autor do comentário)
    private var deviceID: String { UserProfileService.shared.deviceID }

    var body: some View {
        NavigationStack {
            List {
                // --- Lista de comentários existentes ---
                if report.comments.isEmpty {
                    Section {
                        Text("Nenhum comentário ainda. Seja o primeiro!")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                } else {
                    Section("Comentários (\(report.comments.count))") {
                        ForEach(report.comments) { comment in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(comment.text)
                                    .font(.subheadline)
                                HStack {
                                    // Destaca "Você" se for o dispositivo atual
                                    Text(comment.deviceID == deviceID ? "Você" : "Usuário")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(comment.createdAt, style: .relative)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                // --- Campo para novo comentário ---
                Section("Novo comentário") {
                    TextField("Escreva um comentário...", text: $newCommentText, axis: .vertical)
                        .lineLimit(2...5)

                    // Mostra erro se houver
                    if let error = errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }

                    // Botão de enviar
                    Button {
                        Task { await sendComment() }
                    } label: {
                        HStack {
                            if isSaving { ProgressView().scaleEffect(0.8) }
                            Text("Enviar comentário")
                        }
                    }
                    .disabled(isSaving || newCommentText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .navigationTitle("Comentários")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
    }

    /// Envia o comentário para o Node-RED via PUT no report
    private func sendComment() async {
        let trimmed = newCommentText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        isSaving     = true
        errorMessage = nil
        do {
            let updated = try await ReportService.shared.addComment(
                to:       report,
                text:     trimmed,
                deviceID: deviceID
            )
            report         = updated
            newCommentText = ""   // limpa o campo após enviar
            onUpdate(updated)
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

// ============================================================
// MARK: - CreateReportView
// ============================================================
// Formulário para criar um novo reporte.

struct CreateReportView: View {

    var onCreated: (Report) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var descriptionText: String        = ""
    @State private var category:        ReportCategory = .other
    @State private var urgency:         UrgencyLevel   = .medium
    @State private var address:         String         = ""
    @State private var latitude:        String         = ""
    @State private var longitude:       String         = ""
    @State private var isSaving:        Bool           = false
    @State private var errorMessage:    String?        = nil

    var body: some View {
        NavigationStack {
            Form {
                Section("Descrição") {
                    TextField("Descreva o problema", text: $descriptionText, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Categoria e Urgência") {
                    Picker("Categoria", selection: $category) {
                        ForEach(ReportCategory.allCases, id: \.self) { c in
                            Label(c.label, systemImage: c.icon).tag(c)
                        }
                    }
                    Picker("Urgência", selection: $urgency) {
                        ForEach(UrgencyLevel.allCases, id: \.self) { u in
                            Text(u.label).tag(u)
                        }
                    }
                }

                Section("Localização") {
                    TextField("Endereço", text: $address)
                    TextField("Latitude  (ex: -5.0892)", text: $latitude)
                        .keyboardType(.decimalPad)
                    TextField("Longitude (ex: -42.8016)", text: $longitude)
                        .keyboardType(.decimalPad)
                }

                if let error = errorMessage {
                    Section {
                        Text(error).foregroundStyle(.red).font(.caption)
                    }
                }
            }
            .navigationTitle("Novo Reporte")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Salvar") { Task { await save() } }
                        .disabled(isSaving || descriptionText.isEmpty)
                }
            }
        }
    }

    private func save() async {
        isSaving     = true
        errorMessage = nil

        // Converte latitude/longitude (aceita vírgula ou ponto)
        let lat = Double(latitude.replacingOccurrences(of: ",", with: "."))   ?? 0
        let lng = Double(longitude.replacingOccurrences(of: ",", with: "."))  ?? 0

        // Monta o Report local (sem cloudantID/cloudantRev — ainda não existe no banco)
        let report = Report(
            protocolNumber: "APP-\(Int(Date().timeIntervalSince1970))",
            description:    descriptionText,
            category:       category,
            urgency:        urgency,
            location:       ReportLocation(latitude: lat, longitude: lng, address: address)
        )

        do {
            let created = try await ReportService.shared.create(report)
            onCreated(created)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            isSaving = false
        }
    }
}

// ============================================================
// MARK: - EditReportView
// ============================================================
// Edita descrição, categoria, urgência e endereço de um reporte.
// Mantém cloudantID e cloudantRev intactos para o PUT funcionar.

struct EditReportView: View {

    var report: Report
    var onUpdated: (Report) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var descriptionText: String
    @State private var category:        ReportCategory
    @State private var urgency:         UrgencyLevel
    @State private var address:         String
    @State private var isSaving:        Bool    = false
    @State private var errorMessage:    String? = nil

    init(report: Report, onUpdated: @escaping (Report) -> Void) {
        self.report    = report
        self.onUpdated = onUpdated
        // Pré-preenche os campos com os valores atuais
        _descriptionText = State(initialValue: report.description)
        _category        = State(initialValue: report.category)
        _urgency         = State(initialValue: report.urgency)
        _address         = State(initialValue: report.location.address)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Descrição") {
                    TextField("Descrição", text: $descriptionText, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Categoria e Urgência") {
                    Picker("Categoria", selection: $category) {
                        ForEach(ReportCategory.allCases, id: \.self) { c in
                            Label(c.label, systemImage: c.icon).tag(c)
                        }
                    }
                    Picker("Urgência", selection: $urgency) {
                        ForEach(UrgencyLevel.allCases, id: \.self) { u in
                            Text(u.label).tag(u)
                        }
                    }
                }

                Section("Endereço") {
                    TextField("Endereço", text: $address)
                }

                if let error = errorMessage {
                    Section {
                        Text(error).foregroundStyle(.red).font(.caption)
                    }
                }
            }
            .navigationTitle("Editar Reporte")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Salvar") { Task { await save() } }
                        .disabled(isSaving || descriptionText.isEmpty)
                }
            }
        }
    }

    private func save() async {
        isSaving     = true
        errorMessage = nil

        // Copia o report atual e altera só os campos editáveis.
        // cloudantID e cloudantRev são preservados — essencial para o PUT não duplicar.
        var updated = report
        updated.description      = descriptionText
        updated.category         = category
        updated.urgency          = urgency
        updated.location.address = address

        do {
            let saved = try await ReportService.shared.update(updated)
            onUpdated(saved)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            isSaving = false
        }
    }
}

// ============================================================
// MARK: - ProfileView
// ============================================================
// Tela de perfil do usuário. Sem autenticação — usa deviceID.

struct ProfileView: View {

    @State private var name:        String  = ""
    @State private var email:       String  = ""
    @State private var pushEnabled: Bool    = true
    @State private var isLoading:   Bool    = false
    @State private var isSaving:    Bool    = false
    @State private var message:     String? = nil
    @State private var isError:     Bool    = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Dados pessoais") {
                    TextField("Nome", text: $name)
                    TextField("E-mail", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }

                Section("Preferências") {
                    Toggle("Notificações push", isOn: $pushEnabled)
                }

                Section("Dispositivo") {
                    // O deviceID identifica este aparelho no banco (sem login)
                    LabeledContent("ID", value: UserProfileService.shared.deviceID)
                        .font(.caption)
                }

                if let msg = message {
                    Section {
                        Text(msg)
                            .font(.caption)
                            .foregroundStyle(isError ? .red : .green)
                    }
                }

                Section {
                    Button("Salvar perfil") { Task { await save() } }
                        .disabled(isSaving)

                    Button("Excluir perfil", role: .destructive) {
                        Task { await delete() }
                    }
                }
            }
            .navigationTitle("Perfil")
            .task { await load() }
        }
    }

    /// Carrega o perfil deste dispositivo do Node-RED
    private func load() async {
        isLoading = true
        do {
            if let profile = try await UserProfileService.shared.fetchMine() {
                name        = profile.name
                email       = profile.email
                pushEnabled = profile.pushNotificationsEnabled
            }
        } catch {
            // Perfil ainda não existe → campos ficam vazios (normal na 1ª vez)
        }
        isLoading = false
    }

    /// Salva o perfil via POST /postuser
    private func save() async {
        isSaving = true
        message  = nil
        let profile = UserProfile(
            name:                    name,
            email:                   email,
            pushNotificationsEnabled: pushEnabled
        )
        do {
            try await UserProfileService.shared.create(profile)
            message = "Perfil salvo com sucesso!"
            isError = false
        } catch {
            message = error.localizedDescription
            isError = true
        }
        isSaving = false
    }

    /// Remove o perfil via DELETE /deleteuser
    private func delete() async {
        do {
            try await UserProfileService.shared.delete()
            name = ""; email = ""; pushEnabled = true
            message = "Perfil excluído."
            isError = false
        } catch {
            message = error.localizedDescription
            isError = true
        }
    }
}

// ============================================================
// MARK: - UrgencyBadge
// ============================================================
// Pílula colorida que indica o nível de urgência.

struct UrgencyBadge: View {
    let urgency: UrgencyLevel

    private var color: Color {
        switch urgency {
        case .low:    return .green
        case .medium: return .orange
        case .high:   return .red
        }
    }

    var body: some View {
        Text(urgency.label)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

// ============================================================
// MARK: - StatusBadge
// ============================================================
// Pílula que indica se o reporte está aberto ou resolvido.

struct StatusBadge: View {
    let status: ReportStatus

    var body: some View {
        Label(status.label, systemImage: status.icon)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(status == .open
                        ? Color.blue.opacity(0.12)
                        : Color.green.opacity(0.12))
            .foregroundStyle(status == .open ? Color.blue : Color.green)
            .clipShape(Capsule())
    }
}

// ============================================================
// MARK: - Preview
// ============================================================

#Preview {
    ContentView()
}
