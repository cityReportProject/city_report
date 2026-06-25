// ReportQuickLookView.swift
// Detalhe rápido (bottom sheet) — US08, US12, US13
// Compartilhado entre MapScreenView (toque no pin) e NearbyReportsView (toque na lista)

import SwiftUI

// MARK: - Cores de urgência/marca (hex exatos do protótipo)

extension Color {
    static let urgencyHigh = Color(red: 0.8627, green: 0.2078, blue: 0.2706)   // #DC3545
    static let urgencyMedium = Color(red: 0.9608, green: 0.6196, blue: 0.0431) // #F59E0B
    static let urgencyLow = Color(red: 0.1333, green: 0.7725, blue: 0.3686)   // #22C55E
    static let userBlue = Color(red: 0.1765, green: 0.4902, blue: 0.8235)     // #2D7DD2
    static let brandDark = Color(red: 0.1020, green: 0.2980, blue: 0.5490)   // #1A4C8C
}

func urgencyColor(_ level: UrgencyLevel) -> Color {
    switch level {
    case .low: return .urgencyLow
    case .medium: return .urgencyMedium
    case .high: return .urgencyHigh
    }
}

// MARK: - Detalhe rápido

struct ReportQuickLookView: View {
    let report: Report
    var onVoteChanged: (Report) -> Void

    @State private var isVoting = false
    @Environment(\.dismiss) private var dismiss

    private var hasVoted: Bool { VoteRegistryService.shared.hasVoted(on: report.id) }

    private var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.localizedString(for: report.createdAt, relativeTo: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                Text(report.description)
                    .font(.headline)
                    .lineLimit(2)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 8) {
                badge(report.urgency.label, color: urgencyColor(report.urgency))
                badge(report.category.label, color: .blue)
                badge(report.status.label, color: report.status == .open ? .blue : .green)
            }

            HStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse").foregroundStyle(.secondary)
                Text(report.location.address)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Credibilidade da comunidade")
                        .font(.caption.weight(.semibold))
                    Spacer()
                    if report.isHighCredibility {
                        Text("Alta credibilidade ★")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.orange)
                    }
                }
                ProgressView(value: min(Double(report.voteCount) / 10.0, 1.0))
                Text("\(report.voteCount) votos")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 6) {
                Circle()
                    .fill(Color(.systemGray4))
                    .frame(width: 28, height: 28)
                    .overlay(Image(systemName: "person.fill").font(.caption2).foregroundStyle(.white))
                Text("Cidadão · \(relativeTime)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Button {
                    Task { await toggleVote() }
                } label: {
                    HStack {
                        if isVoting { ProgressView().scaleEffect(0.7) }
                        Text(hasVoted ? "Remover confirmação" : "Confirmar problema")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isVoting)

                ShareLink(item: "Reporte #\(report.protocolNumber): \(report.description) — \(report.location.address)") {
                    Text("Compartilhar")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(20)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private func toggleVote() async {
        isVoting = true
        do {
            let updated = hasVoted
                ? try await VoteRegistryService.shared.removeVote(from: report)
                : try await VoteRegistryService.shared.vote(on: report)
            onVoteChanged(updated)
        } catch {
            // mantém simples por ora — tratamento de erro de voto fica para um passe futuro
        }
        isVoting = false
    }
}
