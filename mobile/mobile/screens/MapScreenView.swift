// MapScreenView.swift
// Tela de Mapa Principal — fiel ao protótipo prototipo_base/Mapa Principal.dc.html
// US07, US08, US09, US10, US12, US13, US17, US18 — chama ReportService.fetchAll()
// e VoteRegistryService (ambos já existentes); filtros são client-side.

import SwiftUI
import MapKit

struct MapScreenView: View {
    @State private var reports: [Report] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    @State private var selectedReport: Report?
    @State private var showingCreate = false
    @State private var showingProfile = false
    @State private var showingReportsList = false
    @State private var showingCategorySheet = false
    @State private var showingNearby = false
    @State private var searchText = ""

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var mapStyle: MapStyle = .standard
    @State private var isStandardMapStyle = true

    @State private var urgencyFilter: Set<UrgencyLevel> = []
    @State private var statusFilter: StatusFilter = .open
    @State private var categoryFilter: Set<ReportCategory> = []

    private var filteredReports: [Report] {
        reports.filter { report in
            (urgencyFilter.isEmpty || urgencyFilter.contains(report.urgency))
                && (categoryFilter.isEmpty || categoryFilter.contains(report.category))
                && statusFilter.matches(report.status)
        }
    }

    var body: some View {
        ZStack {
            mapLayer
            topControls
            bottomLayer
            statusBanner
        }
        .sheet(item: $selectedReport) { report in
            ReportQuickLookView(report: report) { updated in
                if let idx = reports.firstIndex(where: { $0.id == updated.id }) {
                    reports[idx] = updated
                }
                selectedReport = updated
            }
        }
        .sheet(isPresented: $showingCreate) {
            CreateReportView { newReport in
                reports.insert(newReport, at: 0)
            }
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
        }
        .fullScreenCover(isPresented: $showingReportsList) {
            ReportsListView()
        }
        .sheet(isPresented: $showingCategorySheet) {
            categoryFilterSheet
        }
        .sheet(isPresented: $showingNearby) {
            NearbyReportsView()
        }
        .task { await loadReports() }
    }

    // MARK: - Camadas

    private var mapLayer: some View {
        Map(position: $cameraPosition) {
            ForEach(filteredReports) { report in
                Annotation(report.category.label, coordinate: CLLocationCoordinate2D(
                    latitude: report.location.latitude,
                    longitude: report.location.longitude
                )) {
                    ReportPinView(report: report)
                        .onTapGesture { selectedReport = report }
                }
            }
        }
        .mapStyle(mapStyle)
        .ignoresSafeArea()
    }

    private var topControls: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                SearchBarView(text: $searchText)
                GlassIconButton(systemImage: "bell.fill", badge: true, action: {})
            }

            HStack(spacing: 8) {
                ForEach(UrgencyLevel.allCases, id: \.self) { level in
                    FilterChip(
                        label: level.label,
                        color: urgencyColor(level),
                        isSelected: urgencyFilter.contains(level)
                    ) {
                        toggle(level, in: &urgencyFilter)
                    }
                }
                StatusChip(filter: $statusFilter)
                categoryFilterButton
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var categoryFilterButton: some View {
        Button {
            showingCategorySheet = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                if !categoryFilter.isEmpty {
                    Text("\(categoryFilter.count)")
                }
            }
            .font(.caption.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
        }
        .background(.ultraThinMaterial, in: Capsule())
    }

    private var bottomLayer: some View {
        VStack(spacing: 14) {
            Spacer()
            HStack {
                VStack(spacing: 10) {
                    GlassIconButton(systemImage: "list.bullet") {
                        showingNearby = true
                    }
                    GlassIconButton(systemImage: "square.2.layers.3d") {
                        isStandardMapStyle.toggle()
                        mapStyle = isStandardMapStyle ? .standard : .imagery(elevation: .realistic)
                    }
                }
                Spacer()
                GlassIconButton(systemImage: "location.fill") {
                    cameraPosition = .automatic
                }
            }
            dock
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }

    private var dock: some View {
        HStack(spacing: 20) {
            DockIconButton(systemImage: "list.bullet.clipboard") {
                showingReportsList = true
            }

            Button {
                showingCreate = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        LinearGradient(colors: [.userBlue, .brandDark], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: Circle()
                    )
                    .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
            }

            DockIconButton(systemImage: "person.fill") {
                showingProfile = true
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.4), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
    }

    @ViewBuilder
    private var statusBanner: some View {
        if let error = errorMessage {
            VStack {
                bannerCard {
                    VStack(spacing: 8) {
                        Text(error).font(.caption).multilineTextAlignment(.center)
                        Button("Tentar novamente") { Task { await loadReports() } }
                            .font(.caption.bold())
                    }
                }
                .padding(.top, 150)
                Spacer()
            }
        } else if isLoading {
            VStack {
                bannerCard { ProgressView("Carregando...") }
                    .padding(.top, 150)
                Spacer()
            }
        }
    }

    private func bannerCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private var categoryFilterSheet: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 10)], spacing: 10) {
                    ForEach(ReportCategory.allCases, id: \.self) { category in
                        Button {
                            toggle(category, in: &categoryFilter)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: category.icon)
                                Text(category.label)
                                    .font(.caption.weight(.medium))
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(categoryFilter.contains(category) ? Color.brandDark : Color(.systemGray5))
                            .foregroundStyle(categoryFilter.contains(category) ? .white : .primary)
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Filtrar por categoria")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Aplicar") { showingCategorySheet = false }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
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

// MARK: - Filtro de status (cicla Abertos → Resolvidos → Todos)

private enum StatusFilter: String, CaseIterable, Equatable {
    case open = "Abertos"
    case resolved = "Resolvidos"
    case all = "Todos"

    func matches(_ status: ReportStatus) -> Bool {
        switch self {
        case .open: return status == .open
        case .resolved: return status == .resolved
        case .all: return true
        }
    }
}

private struct StatusChip: View {
    @Binding var filter: StatusFilter

    var body: some View {
        Button {
            let all = StatusFilter.allCases
            let idx = all.firstIndex(of: filter) ?? 0
            filter = all[(idx + 1) % all.count]
        } label: {
            Text(filter.rawValue)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
        }
        .background(.ultraThinMaterial, in: Capsule())
    }
}

// MARK: - Helpers de seleção
// (urgencyColor(_:) e as cores Color.urgency*/userBlue/brandDark moraram para ReportQuickLookView.swift,
// já que agora são usadas por mais de uma tela)

private func toggle<T: Hashable>(_ value: T, in set: inout Set<T>) {
    if set.contains(value) {
        set.remove(value)
    } else {
        set.insert(value)
    }
}

// MARK: - Pin do mapa
// US14 — pins de reports com isHighCredibility ganham halo pulsante + ficam maiores

private struct ReportPinView: View {
    let report: Report
    @State private var isPulsing = false

    private var pinSize: CGFloat { report.isHighCredibility ? 40 : 32 }

    var body: some View {
        ZStack {
            if report.isHighCredibility {
                Circle()
                    .fill(urgencyColor(report.urgency).opacity(0.35))
                    .frame(width: pinSize + 18, height: pinSize + 18)
                    .scaleEffect(isPulsing ? 1.15 : 0.8)
                    .opacity(isPulsing ? 0 : 0.7)
            }
            Circle()
                .fill(urgencyColor(report.urgency))
                .frame(width: pinSize, height: pinSize)
                .shadow(radius: 2, y: 1)
            Image(systemName: report.category.icon)
                .font(.system(size: report.isHighCredibility ? 16 : 14, weight: .bold))
                .foregroundStyle(.white)
        }
        .onAppear {
            guard report.isHighCredibility else { return }
            withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Search bar (visual — sem busca ligada ainda)

private struct SearchBarView: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Buscar endereço...", text: $text)
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Legenda de urgência

private struct UrgencyLegend: View {
    var body: some View {
        HStack(spacing: 14) {
            item(.high, "Alta")
            item(.medium, "Média")
            item(.low, "Baixa")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
    }

    private func item(_ level: UrgencyLevel, _ label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(urgencyColor(level)).frame(width: 8, height: 8)
            Text(label).font(.caption2.weight(.medium))
        }
    }
}

// MARK: - Chip de filtro (urgência)

private struct FilterChip: View {
    let label: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(label).font(.caption.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .foregroundStyle(isSelected ? .white : .primary)
            .background(isSelected ? Color.brandDark : Color.clear)
            .background(.ultraThinMaterial, in: Capsule())
            .clipShape(Capsule())
        }
    }
}

// MARK: - Botões flutuantes de vidro (notificações, localização, lista)

private struct GlassIconButton: View {
    let systemImage: String
    var badge: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 52, height: 52)
                if badge {
                    Circle()
                        .fill(Color.urgencyHigh)
                        .frame(width: 9, height: 9)
                        .offset(x: -6, y: 6)
                }
            }
        }
        .background(.ultraThinMaterial, in: Circle())
        .overlay(Circle().strokeBorder(.white.opacity(0.4), lineWidth: 0.5))
        .foregroundStyle(.primary)
    }
}

// MARK: - Botão do dock (Layers, Perfil)

private struct DockIconButton: View {
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.brandDark)
                .frame(width: 48, height: 48)
                .background(Color.userBlue.opacity(0.15), in: Circle())
        }
    }
}

#Preview {
    MapScreenView()
}
