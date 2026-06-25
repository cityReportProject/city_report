// ProfileView.swift
// Tela de Perfil — estatísticas, Meus Reportes e modo noturno (US21, US22, US23)
// Movida de ContentView.swift para a pasta padrão de telas.

import SwiftUI

struct ProfileView: View {
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false

    @State private var name = ""
    @State private var email = ""
    @State private var pushEnabled = true
    @State private var isLoading = false
    @State private var isSaving = false
    @State private var message: String?
    @State private var isError = false

    @State private var allReports: [Report] = []
    @State private var selectedReport: Report?

    private var myReports: [Report] {
        allReports
            .filter { MyReportsRegistryService.shared.isMine($0.id) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private var sentCount: Int { myReports.count }
    private var resolvedCount: Int { myReports.filter(\.isResolved).count }
    private var openCount: Int { myReports.filter { !$0.isResolved }.count }

    var body: some View {
        NavigationStack {
            Form {
                statsSection

                Section("Dados pessoais") {
                    TextField("Nome", text: $name)
                    TextField("E-mail", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }

                Section("Preferências") {
                    Toggle("Notificações push", isOn: $pushEnabled)
                    Toggle("Modo noturno", isOn: $darkModeEnabled)
                }

                Section("Dispositivo") {
                    LabeledContent("ID", value: UserProfileService.shared.deviceID)
                        .font(.caption)
                }

                if !myReports.isEmpty {
                    Section("Meus Reportes") {
                        ForEach(myReports) { report in
                            Button {
                                selectedReport = report
                            } label: {
                                MyReportRowView(report: report)
                            }
                            .buttonStyle(.plain)
                        }
                    }
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
            .task {
                await load()
                await loadMyReports()
            }
            .sheet(item: $selectedReport) { report in
                ReportQuickLookView(report: report) { updated in
                    if let idx = allReports.firstIndex(where: { $0.id == updated.id }) {
                        allReports[idx] = updated
                    }
                    selectedReport = updated
                }
            }
        }
    }

    private var statsSection: some View {
        Section {
            HStack {
                statItem(value: sentCount, label: "Enviados", color: .primary)
                Divider()
                statItem(value: resolvedCount, label: "Resolvidos", color: .green)
                Divider()
                statItem(value: openCount, label: "Abertos", color: .orange)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func statItem(value: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title2.weight(.bold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func load() async {
        isLoading = true
        do {
            if let profile = try await UserProfileService.shared.fetchMine() {
                name = profile.name
                email = profile.email
                pushEnabled = profile.pushNotificationsEnabled
            }
        } catch {
            // perfil ainda não existe, tudo bem
        }
        isLoading = false
    }

    private func loadMyReports() async {
        do {
            allReports = try await ReportService.shared.fetchAll()
        } catch {
            // estatísticas ficam zeradas se a lista não carregar; não bloqueia o resto da tela
        }
    }

    private func save() async {
        isSaving = true
        message = nil
        let profile = UserProfile(name: name, email: email, pushNotificationsEnabled: pushEnabled)
        do {
            _ = try await UserProfileService.shared.create(profile)
            message = "Perfil salvo com sucesso!"
            isError = false
        } catch {
            message = error.localizedDescription
            isError = true
        }
        isSaving = false
    }

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

// MARK: - Linha "Meus Reportes"

private struct MyReportRowView: View {
    let report: Report

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(report.description)
                    .font(.subheadline)
                    .lineLimit(1)
                Text("Protocolo \(report.protocolNumber)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            StatusBadge(status: report.status)
        }
    }
}

#Preview {
    ProfileView()
}
