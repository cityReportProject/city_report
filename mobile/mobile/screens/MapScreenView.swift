// MapScreenView.swift
// Tela de Mapa Principal — fiel ao protótipo prototipo_base/Mapa Principal.dc.html
// Agora usando dados mockados fixos gerados ao redor do centro do mapa.

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
    @State private var searchText = ""

    @State private var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -5.062429, longitude: -42.794596),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    ))
    @State private var mapStyle: MapStyle = .standard
    @State private var isStandardMapStyle = true
    
    @State private var userLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: -5.062429, longitude: -42.794596)

    // Centro atual do mapa (usado para gerar mocks ao redor)
    @State private var mapCenter: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: -5.062429, longitude: -42.794596)

    @State private var urgencyFilter: Set<UrgencyLevel> = []
    @State private var statusFilter: StatusFilter = .open
    @State private var categoryFilter: Set<ReportCategory> = []

    // Notificações
    @State private var showingNotifications = false
    @State private var unreadCount: Int = 0

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
                // Insere o novo item no topo da lista atual de mocks
                reports.insert(newReport, at: 0)
            }
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
        }
        .fullScreenCover(isPresented: $showingReportsList) {
            // Passa o centro atual do mapa para a lista gerar mocks próximos
            ReportsListView(center: mapCenter)
        }
        .sheet(isPresented: $showingCategorySheet) {
            categoryFilterSheet
        }
        .sheet(isPresented: $showingNotifications) {
            NotificationsView()
        }
        .task {
            await regenerateReportsNearCenter()
            refreshUnreadCount()
        }
        .onAppear {
            refreshUnreadCount()
        }
    }

    // MARK: - Camadas

    private var mapLayer: some View {
        Map(position: $cameraPosition) {
            // Marcador da localização do usuário
            Annotation("Sua localização", coordinate: userLocation) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 60, height: 60)
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                        )
                }
            }
            
            // Pins dos reportes
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
        .onMapCameraChange(frequency: .onEnd) { context in
            // Atualiza o centro e regenera os mocks quando o usuário termina de mover/zoom
            mapCenter = context.region.center
            Task { await regenerateReportsNearCenter() }
        }
        .mapStyle(mapStyle)
        .ignoresSafeArea()
    }

    private var topControls: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                SearchBarView(text: $searchText)
                GlassIconButton(systemImage: "bell.fill", badge: unreadCount > 0) {
                    showingNotifications = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        refreshUnreadCount()
                    }
                }
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
                    GlassIconButton(systemImage: "square.2.layers.3d") {
                        isStandardMapStyle.toggle()
                        mapStyle = isStandardMapStyle ? .standard : .imagery(elevation: .realistic)
                    }
                }
                Spacer()
                GlassIconButton(systemImage: "location.fill") {
                    // Centralizar no usuário
                    cameraPosition = .region(MKCoordinateRegion(
                        center: userLocation,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    ))
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
                        Button("Tentar novamente") { Task { await regenerateReportsNearCenter() } }
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

    @MainActor
    private func regenerateReportsNearCenter() async {
        isLoading = true
        errorMessage = nil
        // Gera exatamente 10 reportes fixos próximos ao centro atual do mapa
        reports = generateFixedReports(around: mapCenter)
        isLoading = false
    }

    // MARK: - Notificações helpers

    private func refreshUnreadCount() {
        unreadCount = NotificationService.shared.unreadCount()
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

private func toggle<T: Hashable>(_ value: T, in set: inout Set<T>) {
    if set.contains(value) {
        set.remove(value)
    } else {
        set.insert(value)
    }
}

// MARK: - Pin do mapa (inalterado)

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

// MARK: - Search bar

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

// MARK: - Botões flutuantes

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

// MARK: - Botão do dock

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

// MARK: - Gerador de reportes mockados FIXOS

private func generateFixedReports(around center: CLLocationCoordinate2D) -> [Report] {
    // 10 deslocamentos fixos (em graus) ao redor do centro
    // ~0.005 deg ≈ 550 m próximos ao equador; em Teresina fica parecido.
    let offsets: [(Double, Double)] = [
        ( 0.0000,  0.0000),
        ( 0.0040,  0.0000),
        (-0.0040,  0.0000),
        ( 0.0000,  0.0040),
        ( 0.0000, -0.0040),
        ( 0.0030,  0.0030),
        ( 0.0030, -0.0030),
        (-0.0030,  0.0030),
        (-0.0030, -0.0030),
        ( 0.0050,  0.0015)
    ]

    let categories: [ReportCategory] = [
        .pavement, .lighting, .sewage, .waterSupply, .wasteCollection,
        .environment, .other, .pavement, .lighting, .sewage
    ]

    let urgencies: [UrgencyLevel] = [
        .high, .medium, .low, .medium, .high, .low, .medium, .high, .low, .medium
    ]

    let descriptions: [String] = [
        "Buraco na via principal",
        "Poste apagado próximo à praça",
        "Bueiro entupido na esquina",
        "Falta d'água no quarteirão",
        "Acúmulo de lixo em terreno",
        "Queimada em terreno baldio",
        "Sinalização precária na rua",
        "Calçada quebrada em frente à escola",
        "Lâmpada piscando no poste",
        "Mau cheiro constante no bueiro"
    ]

    var result: [Report] = []
    result.reserveCapacity(10)

    for i in 0..<10 {
        let lat = center.latitude  + offsets[i].0
        let lng = center.longitude + offsets[i].1
        let address = String(format: "Próximo a %.5f, %.5f", lat, lng)

        let report = Report(
            protocolNumber: String(format: "FIX-%04d", i + 1),
            createdAt: Calendar.current.date(byAdding: .hour, value: -(i * 6), to: Date()) ?? Date(),
            description: descriptions[i],
            category: categories[i],
            urgency: urgencies[i],
            status: i % 4 == 0 ? .resolved : .open, // alguns resolvidos para variar
            location: ReportLocation(latitude: lat, longitude: lng, address: address),
            voteCount: i, // votos crescentes e determinísticos
            comments: [],
            resolvedAt: i % 4 == 0 ? Date().addingTimeInterval(-Double(i) * 3600) : nil,
            resolutionComment: i % 4 == 0 ? "Resolvido pela equipe." : nil
        )
        result.append(report)
    }

    // Ordena por mais recentes primeiro (i=0 mais recente)
    return result.sorted { $0.createdAt > $1.createdAt }
}

#Preview {
    MapScreenView()
}
