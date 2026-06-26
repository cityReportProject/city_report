// ContentView.swift
// Navegação principal do app — MapScreenView com dock personalizado
// ReportsListView agora gera dados mockados próximos ao centro recebido.

import SwiftUI
import CoreLocation
#if os(iOS)
import UIKit
#endif

struct ContentView: View {
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false

    var body: some View {
        MapScreenView()
            .preferredColorScheme(darkModeEnabled ? .dark : .light)
    }
}

// MARK: - Lista de Reportes

struct ReportsListView: View {
    // Centro a partir do qual os mocks serão gerados (vindo do mapa)
    let center: CLLocationCoordinate2D?

    @State private var reports: [Report] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingCreate = false
    @Environment(\.dismiss) private var dismiss

    init(center: CLLocationCoordinate2D? = nil) {
        self.center = center
    }

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

    @MainActor
    private func loadReports() async {
        isLoading = true
        errorMessage = nil

        // Centro padrão (mesmo do mapa) caso não seja informado
        let defaultCenter = CLLocationCoordinate2D(latitude: -5.062429, longitude: -42.794596)
        let base = center ?? defaultCenter

        // Gera 30 reportes próximos ao centro recebido
        reports = generateMockReports(around: base, count: 30)

        isLoading = false
    }

    // Gerador local (cópia reduzida do usado no mapa)
    private func generateMockReports(around center: CLLocationCoordinate2D, count: Int = 30) -> [Report] {
        let samples: [ReportCategory: [String]] = [
            .pavement: ["Buraco na via", "Asfalto esfarelando", "Lombada danificada", "Calçada quebrada"],
            .lighting: ["Poste apagado", "Lâmpada piscando", "Iluminação fraca na rua", "Poste caído"],
            .sewage: ["Esgoto a céu aberto", "Bueiro entupido", "Vazamento de esgoto", "Mau cheiro constante"],
            .waterSupply: ["Vazamento de água", "Falta d'água", "Baixa pressão na rede", "Hidrante vazando"],
            .wasteCollection: ["Acúmulo de lixo", "Coleta atrasada", "Ponto de descarte irregular", "Lixeira danificada"],
            .environment: ["Queimada em terreno", "Descarte de entulho", "Árvore caída", "Poluição sonora"],
            .other: ["Problema de infraestrutura", "Sinalização precária", "Situação de risco", "Obra irregular"]
        ]

        var result: [Report] = []
        result.reserveCapacity(count)

        for _ in 0..<count {
            let category = ReportCategory.allCases.randomElement()!
            let urgency = UrgencyLevel.allCases.randomElement()!
            let isResolved = Bool.random() && Bool.random()
            let createdAt = Date().addingTimeInterval(-Double.random(in: 0...(7 * 24 * 3600)))
            let voteCount = Int.random(in: 0...15)

            let latOffset = Double.random(in: -0.02...0.02)
            let lngOffset = Double.random(in: -0.02...0.02)
            let lat = center.latitude + latOffset
            let lng = center.longitude + lngOffset

            let desc = samples[category]?.randomElement() ?? "Problema em \(category.label)"
            let address = String(format: "Próximo a %.5f, %.5f", lat, lng)
            let protocolNumber = "MOCK-\(Int.random(in: 1000...9999))"

            let resolvedAt: Date? = isResolved ? createdAt.addingTimeInterval(Double.random(in: 3600...72_000)) : nil
            let resolutionComment: String? = isResolved ? "Resolvido pela equipe." : nil

            let report = Report(
                protocolNumber: protocolNumber,
                createdAt: createdAt,
                description: desc,
                category: category,
                urgency: urgency,
                status: isResolved ? .resolved : .open,
                location: ReportLocation(latitude: lat, longitude: lng, address: address),
                voteCount: voteCount,
                comments: [],
                resolvedAt: resolvedAt,
                resolutionComment: resolutionComment
            )
            result.append(report)
        }

        return result.sorted { $0.createdAt > $1.createdAt }
    }
}

// MARK: - Row da lista (inalterado)

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

// MARK: - Detalhe / Criar / Editar / LocationManager / Badges
// (mantidos exatamente como estavam no arquivo — sem mudanças)

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

    @MainActor
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

    @MainActor
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

    @MainActor
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

// CreateReportView, EditReportView, LocationManager, UrgencyBadge, StatusBadge
// permanecem idênticos ao que você já tem neste arquivo (acima).

#Preview {
    ContentView()
}
