// ContentView.swift
// ContentView.swift
// Navegação principal do app — MapScreenView com dock personalizado

import SwiftUI
import CoreLocation

struct ContentView: View {
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false

    var body: some View {
        MapScreenView()
            .preferredColorScheme(darkModeEnabled ? .dark : .light)
    }
}

// MARK: - Lista de Reportes

struct ReportsListView: View {
    @State private var reports: [Report] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingCreate = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Carregando...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text(error)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                        Button("Tentar novamente") { Task { await loadReports() } }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if reports.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("Nenhum reporte ainda.")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(reports) { report in
                            NavigationLink(destination: ReportDetailView(report: report, onUpdate: { updated in
                                if let idx = reports.firstIndex(where: { $0.id == updated.id }) {
                                    reports[idx] = updated
                                }
                            }, onDelete: { id in
                                reports.removeAll { $0.id == id }
                            })) {
                                ReportRowView(report: report)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Reportes")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreate = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await loadReports() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $showingCreate) {
                CreateReportView { newReport in
                    reports.insert(newReport, at: 0)
                }
            }
            .task { await loadReports() }
        }
    }

    private func loadReports() async {
        isLoading = true
        errorMessage = nil
        do {
            reports = try await ReportService.shared.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Row da lista

struct ReportRowView: View {
    let report: Report

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
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
            Text(report.description)
                .font(.subheadline)
                .lineLimit(2)
            HStack {
                Image(systemName: "hand.thumbsup")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(report.voteCount) votos")
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

// MARK: - Detalhe do Reporte

struct ReportDetailView: View {
    @State var report: Report
    var onUpdate: (Report) -> Void
    var onDelete: (UUID) -> Void

    @State private var showingEdit = false
    @State private var showingResolve = false
    @State private var isVoting = false
    @State private var isDeleting = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                LabeledContent("Protocolo", value: report.protocolNumber)
                LabeledContent("Categoria", value: report.category.label)
                LabeledContent("Urgência", value: report.urgency.label)
                LabeledContent("Status", value: report.status.label)
                LabeledContent("Data", value: report.createdAt.formatted(date: .abbreviated, time: .shortened))
            }

            Section("Descrição") {
                Text(report.description)
            }

            Section("Localização") {
                Text(report.location.address)
                LabeledContent("Lat", value: String(format: "%.6f", report.location.latitude))
                LabeledContent("Lng", value: String(format: "%.6f", report.location.longitude))
            }

            Section("Credibilidade") {
                HStack {
                    Image(systemName: "hand.thumbsup.fill")
                    Text("\(report.voteCount) votos")
                    Spacer()
                    if report.isHighCredibility {
                        Label("Alta credibilidade", systemImage: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }

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

            if report.isResolved, let resolvedAt = report.resolvedAt {
                Section("Resolução") {
                    LabeledContent("Resolvido em", value: resolvedAt.formatted(date: .abbreviated, time: .shortened))
                    if let comment = report.resolutionComment {
                        Text(comment)
                    }
                }
            }

            if let error = errorMessage {
                Section {
                    Text(error).foregroundStyle(.red).font(.caption)
                }
            }

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
        .sheet(isPresented: $showingEdit) {
            EditReportView(report: report) { updated in
                report = updated
                onUpdate(updated)
            }
        }
        .alert("Marcar como resolvido?", isPresented: $showingResolve) {
            Button("Resolver") { Task { await resolveReport() } }
            Button("Cancelar", role: .cancel) {}
        }
    }

    private func toggleVote(hasVoted: Bool) async {
        isVoting = true
        errorMessage = nil
        do {
            let updated = hasVoted
                ? try await VoteRegistryService.shared.removeVote(from: report)
                : try await VoteRegistryService.shared.vote(on: report)
            report = updated
            onUpdate(updated)
        } catch {
            errorMessage = error.localizedDescription
        }
        isVoting = false
    }

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

    private func deleteReport() async {
        isDeleting = true
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

// MARK: - Criar Reporte

struct CreateReportView: View {
    var onCreated: (Report) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var description = ""
    @State private var category: ReportCategory = .other
    @State private var urgency: UrgencyLevel = .medium
    @State private var address = ""
    @State private var latitude: Double?
    @State private var longitude: Double?
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var isLoadingLocation = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Descrição") {
                    TextField("Descreva o problema", text: $description, axis: .vertical)
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
                    
                    if let lat = latitude, let lng = longitude {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundStyle(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Localização capturada")
                                    .font(.subheadline)
                                Text("Lat: \(lat, specifier: "%.6f"), Lng: \(lng, specifier: "%.6f")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    Button {
                        Task { await getCurrentLocation() }
                    } label: {
                        HStack {
                            if isLoadingLocation {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "location.fill")
                            }
                            Text(latitude == nil ? "Usar localização atual" : "Atualizar localização")
                        }
                    }
                    .disabled(isLoadingLocation)
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
                        .disabled(isSaving || description.isEmpty || latitude == nil || longitude == nil)
                }
            }
        }
    }

    private func getCurrentLocation() async {
        isLoadingLocation = true
        errorMessage = nil
        
        do {
            let locationManager = LocationManager()
            let location = try await locationManager.requestLocation()
            latitude = location.coordinate.latitude
            longitude = location.coordinate.longitude
        } catch {
            errorMessage = "Não foi possível obter a localização: \(error.localizedDescription)"
        }
        
        isLoadingLocation = false
    }

    private func save() async {
        guard let lat = latitude, let lng = longitude else {
            errorMessage = "Por favor, capture a localização antes de salvar."
            return
        }
        
        isSaving = true
        errorMessage = nil
        let report = Report(
            protocolNumber: "APP-\(Int(Date().timeIntervalSince1970))",
            description: description,
            category: category,
            urgency: urgency,
            location: ReportLocation(latitude: lat, longitude: lng, address: address)
        )
        do {
            let created = try await ReportService.shared.create(report)
            MyReportsRegistryService.shared.markCreated(created.id)
            onCreated(created)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            isSaving = false
        }
    }
}

// MARK: - Editar Reporte

struct EditReportView: View {
    var report: Report
    var onUpdated: (Report) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var description: String
    @State private var category: ReportCategory
    @State private var urgency: UrgencyLevel
    @State private var address: String
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(report: Report, onUpdated: @escaping (Report) -> Void) {
        self.report = report
        self.onUpdated = onUpdated
        _description = State(initialValue: report.description)
        _category = State(initialValue: report.category)
        _urgency = State(initialValue: report.urgency)
        _address = State(initialValue: report.location.address)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Descrição") {
                    TextField("Descrição", text: $description, axis: .vertical)
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
                        .disabled(isSaving || description.isEmpty)
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        var updated = report
        updated.description = description
        updated.category = category
        updated.urgency = urgency
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

// MARK: - LocationManager

import CoreLocation

@MainActor
class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation, Error>?
    
    override init() {
        super.init()
        manager.delegate = self
    }
    
    func requestLocation() async throws -> CLLocation {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            switch manager.authorizationStatus {
            case .notDetermined:
                // Não decide nada aqui — só dispara o prompt do sistema.
                // A resposta do usuário chega depois em locationManagerDidChangeAuthorization,
                // que resolve essa mesma continuation.
                manager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            case .denied, .restricted:
                continuation.resume(throwing: LocationError.notAuthorized)
                self.continuation = nil
            @unknown default:
                continuation.resume(throwing: LocationError.notAuthorized)
                self.continuation = nil
            }
        }
    }

    // Chamado pelo sistema quando o usuário responde ao prompt de permissão
    // (ou na primeira inicialização, reportando o status atual).
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            // Só age se houver uma requestLocation() pendente — evita
            // disparar uma busca de localização não solicitada.
            guard continuation != nil else { return }

            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            case .denied, .restricted:
                continuation?.resume(throwing: LocationError.notAuthorized)
                continuation = nil
            default:
                break // ainda .notDetermined — continua esperando
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        Task { @MainActor in
            continuation?.resume(returning: location)
            continuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            continuation?.resume(throwing: error)
            continuation = nil
        }
    }
}

enum LocationError: LocalizedError {
    case notAuthorized
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Permissão de localização não concedida. Por favor, habilite nas Configurações."
        }
    }
}

// MARK: - Badges auxiliares

struct UrgencyBadge: View {
    let urgency: UrgencyLevel
    var color: Color {
        switch urgency {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
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

struct StatusBadge: View {
    let status: ReportStatus
    var body: some View {
        Label(status.label, systemImage: status.icon)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(status == .open ? Color.blue.opacity(0.12) : Color.green.opacity(0.12))
            .foregroundStyle(status == .open ? Color.blue : Color.green)
            .clipShape(Capsule())
    }
}

#Preview {
    ContentView()
}
