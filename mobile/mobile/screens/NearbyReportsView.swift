// NearbyReportsView.swift
// Tela "Próximos a Você" — fiel ao protótipo prototipo_base/Mapa Principal.dc.html
// US11 — chama ReportService.fetchAll() (já existente) e ordena por distância.
//
// Sem LocationManager ainda (tarefa "Fundação de localização" não foi feita).
// Por isso a referência de distância usa o centróide dos próprios reportes
// carregados, em vez do GPS real do usuário — é um placeholder deliberado,
// fácil de trocar quando a localização real existir.

import SwiftUI
import CoreLocation

struct NearbyReportsView: View {
    @State private var reports: [Report] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedReport: Report?
    @State private var radiusKm: Double = 5.0

    @Environment(\.dismiss) private var dismiss

    private static let radiusOptions: [Double] = [1, 5, 10, 20]

    private struct NearbyItem: Identifiable {
        let report: Report
        let distanceMeters: Double
        var id: UUID { report.id }
    }

    private var referenceCoordinate: CLLocationCoordinate2D {
        guard !reports.isEmpty else { return CLLocationCoordinate2D(latitude: 0, longitude: 0) }
        let avgLat = reports.map(\.location.latitude).reduce(0, +) / Double(reports.count)
        let avgLng = reports.map(\.location.longitude).reduce(0, +) / Double(reports.count)
        return CLLocationCoordinate2D(latitude: avgLat, longitude: avgLng)
    }

    private var nearbyItems: [NearbyItem] {
        let reference = CLLocation(latitude: referenceCoordinate.latitude, longitude: referenceCoordinate.longitude)
        return reports
            .map { report -> NearbyItem in
                let location = CLLocation(latitude: report.location.latitude, longitude: report.location.longitude)
                return NearbyItem(report: report, distanceMeters: location.distance(from: reference))
            }
            .filter { $0.distanceMeters <= radiusKm * 1000 }
            .sorted { $0.distanceMeters < $1.distanceMeters }
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
                } else {
                    List {
                        Section {
                            ForEach(nearbyItems) { item in
                                Button {
                                    selectedReport = item.report
                                } label: {
                                    NearbyRowView(report: item.report, distanceMeters: item.distanceMeters)
                                }
                                .buttonStyle(.plain)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                            }

                            if nearbyItems.isEmpty {
                                Text("Nenhum reporte em um raio de \(Int(radiusKm)) km.")
                                    .foregroundStyle(.secondary)
                                    .listRowSeparator(.hidden)
                            }
                        } header: {
                            radiusHeader
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Próximos a Você")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fechar") { dismiss() }
                }
            }
            .sheet(item: $selectedReport) { report in
                ReportQuickLookView(report: report) { updated in
                    if let idx = reports.firstIndex(where: { $0.id == updated.id }) {
                        reports[idx] = updated
                    }
                    selectedReport = updated
                }
            }
            .task { await loadReports() }
        }
    }

    private var radiusHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Raio de \(Int(radiusKm)) km · \(nearbyItems.count) reporte\(nearbyItems.count == 1 ? "" : "s")")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .textCase(nil)

            HStack(spacing: 8) {
                ForEach(Self.radiusOptions, id: \.self) { option in
                    Button {
                        radiusKm = option
                    } label: {
                        Text("\(Int(option))km")
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .foregroundStyle(radiusKm == option ? .white : .primary)
                            .background(radiusKm == option ? Color.brandDark : Color(.systemGray5))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 4)
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

// MARK: - Linha da lista

private struct NearbyRowView: View {
    let report: Report
    let distanceMeters: Double

    private var distanceLabel: String {
        if distanceMeters < 1000 {
            return "\(Int(distanceMeters))m de distância"
        } else {
            return String(format: "%.1fkm de distância", distanceMeters / 1000)
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(urgencyColor(report.urgency))
                    .frame(width: 42, height: 42)
                Image(systemName: report.category.icon)
                    .foregroundStyle(.white)
                    .font(.system(size: 16, weight: .bold))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(report.description)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Text(report.category.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(distanceLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.userBlue)
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    NearbyReportsView()
}
