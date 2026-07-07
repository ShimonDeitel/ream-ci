import SwiftUI

enum ReamSheet: Identifiable {
    case addKid
    case addSupply(kidID: UUID)
    case editSupply(SupplyItem)
    case paywall

    var id: String {
        switch self {
        case .addKid: return "addKid"
        case .addSupply(let kidID): return "addSupply-\(kidID)"
        case .editSupply(let item): return "edit-\(item.id)"
        case .paywall: return "paywall"
        }
    }
}

struct KidFormView: View {
    @EnvironmentObject private var store: ReamStore
    @EnvironmentObject private var purchases: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Kid's Name") {
                    TextField("e.g. Sam", text: $name)
                        .accessibilityIdentifier("kidNameField")
                }
            }
            .dismissKeyboardOnTap()
            .navigationTitle("New Kid")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        store.addKid(name: name, isPro: purchases.isPro)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("saveKidButton")
                }
            }
        }
    }
}

struct SupplyFormView: View {
    @EnvironmentObject private var store: ReamStore
    @EnvironmentObject private var purchases: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    let kidID: UUID
    let existing: SupplyItem?

    @State private var name: String
    @State private var kind: SupplyKind
    @State private var thresholdPercent: Double

    init(kidID: UUID, existing: SupplyItem?) {
        self.kidID = kidID
        self.existing = existing
        _name = State(initialValue: existing?.name ?? "")
        _kind = State(initialValue: existing?.kind ?? .pencil)
        _thresholdPercent = State(initialValue: (existing?.restockThreshold ?? 0.25) * 100)
    }

    private var isEditing: Bool { existing != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Supply") {
                    TextField("e.g. No. 2 Pencils", text: $name)
                        .accessibilityIdentifier("supplyNameField")
                    Picker("Type", selection: $kind) {
                        ForEach(SupplyKind.allCases) { k in
                            Label(k.rawValue, systemImage: k.systemImage).tag(k)
                        }
                    }
                    .accessibilityIdentifier("supplyKindPicker")
                }

                Section("Restock Alert") {
                    VStack(alignment: .leading) {
                        Text("Alert when below \(Int(thresholdPercent))%")
                            .font(.subheadline)
                            .foregroundStyle(RMTheme.inkFaded)
                        Slider(value: $thresholdPercent, in: 5...75, step: 5)
                            .accessibilityIdentifier("restockThresholdSlider")
                    }
                }

                if isEditing {
                    Section {
                        Button("Delete Supply", role: .destructive) {
                            if let existing {
                                store.deleteSupply(existing.id)
                            }
                            dismiss()
                        }
                        .accessibilityIdentifier("deleteSupplyButton")
                    }
                }
            }
            .dismissKeyboardOnTap()
            .navigationTitle(isEditing ? "Edit Supply" : "New Supply")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        if isEditing, let existing {
                            store.updateSupply(existing.id, name: name, kind: kind, restockThreshold: thresholdPercent / 100)
                        } else {
                            store.addSupply(kidID: kidID, name: name, kind: kind, isPro: purchases.isPro)
                        }
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("saveSupplyButton")
                }
            }
        }
    }
}
