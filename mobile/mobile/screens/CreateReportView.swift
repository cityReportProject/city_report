import SwiftUI
import CoreLocation

struct CreateReportView: View {
    var onCreate: (Report) -> Void
    @Environment(\.dismiss) private var dismiss

    // Campos do formulário
    @State private var descriptionText: String = ""
    @State private var category: ReportCategory = .pavement
    @State private var urgency: UrgencyLevel = .medium
    @State private var address: String = ""
    @State private var latitude: String = "-5.062429"
    @State private var longitude: String = "-42.794596"

    // Estado
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Descrição") {
                    TextField("Descreva o problema", text: $descriptionText, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Classificação") {
                    Picker("Categoria", selection: $category) {
                        ForEach(ReportCategory.allCases, id: \.self) { cat in
                            Label(cat.label, systemImage: cat.icon).tag(cat)
                        }
                    }
                    Picker("Urgência", selection: $urgency) {
                        ForEach(UrgencyLevel.allCases, id: \.self) { level in
                            Text(level.label).tag(level)
                        }
                    }
                }

                Section("Localização") {
                    TextField("Endereço", text: $address)
                    TextField("Latitude", text: $latitude)
                        .keyboardType(.numbersAndPunctuation)
                    TextField("Longitude", text: $longitude)
                        .keyboardType(.numbersAndPunctuation)
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
                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving { ProgressView() } else { Text("Salvar") }
                    }
                    .disabled(isSaving || !isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        !descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && Double(latitude) != nil
        && Double(longitude) != nil
    }

    @MainActor
    private func save() async {
        guard isValid else { return }
        isSaving = true
        errorMessage = nil

        let lat = Double(latitude) ?? 0
        let lng = Double(longitude) ?? 0
        let location = ReportLocation(latitude: lat, longitude: lng, address: address)

        // Protocolo simples e único
        let protocolNumber = "MOCK-\(Int.random(in: 1000...9999))"

        let newReport = Report(
            protocolNumber: protocolNumber,
            createdAt: Date(),
            description: descriptionText,
            category: category,
            urgency: urgency,
            status: .open,
            location: location,
            voteCount: 0,
            comments: [],
            resolvedAt: nil,
            resolutionComment: nil
        )

        // Para manter fluxo offline/mock, chamamos o callback diretamente e fechamos
        onCreate(newReport)
        isSaving = false
        dismiss()
    }
}
