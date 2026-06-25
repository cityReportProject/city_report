import SwiftUI

struct AppNotification: Identifiable, Codable, Hashable {
    enum Kind: String, Codable, CaseIterable {
        case reportResolved
        case newVote
        case system
    }

    let id: UUID
    let title: String
    let message: String
    let date: Date
    let kind: Kind
    var isRead: Bool
    var relatedReportID: UUID?

    init(
        id: UUID = UUID(),
        title: String,
        message: String,
        date: Date = Date(),
        kind: Kind,
        isRead: Bool = false,
        relatedReportID: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.date = date
        self.kind = kind
        self.isRead = isRead
        self.relatedReportID = relatedReportID
    }
}

struct NotificationsView: View {
    @State private var notifications: [AppNotification] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedReport: Report?
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
                        Button("Tentar novamente") { Task { await load() } }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if notifications.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("Sem notificações por enquanto.")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(notifications) { item in
                            Button {
                                Task { await open(item) }
                            } label: {
                                NotificationRow(item: item)
                            }
                            .buttonStyle(.plain)
                            .swipeActions {
                                Button {
                                    Task { await toggleRead(item) }
                                } label: {
                                    Label(item.isRead ? "Marcar como não lida" : "Marcar como lida",
                                          systemImage: item.isRead ? "envelope.badge" : "envelope.open")
                                }
                                .tint(.blue)

                                Button(role: .destructive) {
                                    Task { await delete(item) }
                                } label: {
                                    Label("Apagar", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Notificações")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fechar") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Marcar todas como lidas") {
                            Task { await markAllRead() }
                        }
                        Button("Limpar todas", role: .destructive) {
                            Task { await clearAll() }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(item: $selectedReport) { report in
                ReportQuickLookView(report: report) { updated in
                    // sem sincronismo com uma lista local de reports aqui;
                    // apenas reabre com o atualizado para manter consistência visual
                    selectedReport = updated
                }
            }
            .task { await load() }
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            notifications = try await NotificationService.shared.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func toggleRead(_ item: AppNotification) async {
        do {
            let updated = try await NotificationService.shared.toggleRead(id: item.id)
            if let idx = notifications.firstIndex(where: { $0.id == updated.id }) {
                notifications[idx] = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func delete(_ item: AppNotification) async {
        do {
            try await NotificationService.shared.delete(id: item.id)
            notifications.removeAll { $0.id == item.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func markAllRead() async {
        do {
            notifications = try await NotificationService.shared.markAllRead()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func clearAll() async {
        do {
            try await NotificationService.shared.clearAll()
            notifications.removeAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func open(_ item: AppNotification) async {
        // marca como lida ao abrir
        await toggleRead(item)

        // Se a notificação estiver vinculada a um Report, tenta carregá-lo e abrir o quick look
        if let id = item.relatedReportID {
            do {
                let reports = try await ReportService.shared.fetchAll()
                if let report = reports.first(where: { $0.id == id }) {
                    selectedReport = report
                }
            } catch {
                // silencioso: se falhar, apenas não abre o detalhe
            }
        }
    }
}

private struct NotificationRow: View {
    let item: AppNotification

    private var iconName: String {
        switch item.kind {
        case .reportResolved: return "checkmark.seal.fill"
        case .newVote:        return "hand.thumbsup.fill"
        case .system:         return "bell.badge.fill"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(backgroundColor)
                    .frame(width: 42, height: 42)
                Image(systemName: iconName)
                    .foregroundStyle(foregroundColor)
                    .font(.system(size: 16, weight: .bold))
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(item.title)
                        .font(.subheadline.weight(item.isRead ? .regular : .semibold))
                        .lineLimit(1)
                    if !item.isRead {
                        Circle().fill(Color.urgencyHigh).frame(width: 6, height: 6)
                    }
                }
                Text(item.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text(item.date, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var backgroundColor: Color {
        switch item.kind {
        case .reportResolved: return Color.green.opacity(0.2)
        case .newVote:        return Color.blue.opacity(0.2)
        case .system:         return Color.orange.opacity(0.2)
        }
    }

    private var foregroundColor: Color {
        switch item.kind {
        case .reportResolved: return .green
        case .newVote:        return .blue
        case .system:         return .orange
        }
    }
}

#Preview {
    NotificationsView()
}
