import SwiftUI

struct EditReportView: View {
    var report: Report
    var onSave: (Report) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var descriptionText: String
    @State private var category: ReportCategory
    @State private var urgency: UrgencyLevel

    @State private var isSaving = false
    @State private var errorMessage: String?

    init(report: Report, onSave: @escaping (Report) -> Void) {
        self.report = report
        self.onSave = onSave
        _descriptionText = State(initialValue: report.description)
        _category = State(initialValue: report.category)
        _urgency = State(initialValue: report.urgency)
    }

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
                if let error = errorMessage {
                    Section { Text(error).foregroundStyle(.red).font(.caption) }
                }
            }
            .navigationTitle("Editar Reporte")
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
    }

    @MainActor
    private func save() async {
        guard isValid else { return }
        isSaving = true
        errorMessage = nil

        var updated = report
        updated.description = descriptionText
        updated.category = category
        updated.urgency = urgency

        // Se você quiser persistir remotamente, troque por:
        // let saved = try await ReportService.shared.update(updated)
        onSave(updated)
        isSaving = false
        dismiss()
    }
}
