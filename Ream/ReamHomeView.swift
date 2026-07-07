import SwiftUI

struct ReamHomeView: View {
    @EnvironmentObject private var store: ReamStore
    @EnvironmentObject private var purchases: PurchaseManager
    @State private var activeSheet: ReamSheet?
    @State private var selectedKidID: UUID?

    private var selectedKid: Kid? {
        store.kids.first(where: { $0.id == selectedKidID }) ?? store.kids.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RMTheme.backdrop.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        header

                        if store.kids.isEmpty {
                            emptyKidsState
                        } else {
                            kidPicker

                            if let kid = selectedKid {
                                restockBanner
                                suppliesList(for: kid)
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                if selectedKidID == nil {
                    selectedKidID = store.kids.first?.id
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .addKid:
                    KidFormView()
                case .addSupply(let kidID):
                    SupplyFormView(kidID: kidID, existing: nil)
                case .editSupply(let item):
                    SupplyFormView(kidID: item.kidID, existing: item)
                case .paywall:
                    PaywallView()
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Ream")
                .font(RMTheme.titleFont)
                .foregroundStyle(RMTheme.ink)
            Spacer()
            Button {
                if store.canAddKid(isPro: purchases.isPro) {
                    activeSheet = .addKid
                } else {
                    activeSheet = .paywall
                }
            } label: {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 22))
                    .foregroundStyle(RMTheme.tapeRed)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("addKidButton")
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    private var kidPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(store.kids) { kid in
                    Button {
                        selectedKidID = kid.id
                    } label: {
                        Text(kid.name)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedKidID == kid.id ? RMTheme.tapeRed : RMTheme.surface)
                            .foregroundStyle(selectedKidID == kid.id ? .white : RMTheme.ink)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(RMTheme.rule, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("kidChip_\(kid.name)")
                }
            }
            .padding(.horizontal, 18)
        }
    }

    private var restockBanner: some View {
        Group {
            if store.restockNeededCount > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(RMTheme.lowStock)
                    Text("\(store.restockNeededCount) item\(store.restockNeededCount == 1 ? "" : "s") need restocking")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RMTheme.ink)
                        .accessibilityIdentifier("restockBannerText")
                    Spacer()
                }
                .padding(12)
                .background(RMTheme.pencilYellow.opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 18)
            }
        }
    }

    private func suppliesList(for kid: Kid) -> some View {
        let supplies = store.supplies(for: kid.id)
        return VStack(spacing: 14) {
            HStack {
                Text("Supplies")
                    .font(RMTheme.headlineFont)
                    .foregroundStyle(RMTheme.ink)
                Spacer()
                Button {
                    if store.canAddSupply(isPro: purchases.isPro) {
                        activeSheet = .addSupply(kidID: kid.id)
                    } else {
                        activeSheet = .paywall
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(RMTheme.tapeRed)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("addSupplyButton")
            }
            .padding(.horizontal, 18)

            if supplies.isEmpty {
                emptySuppliesState(kid: kid)
            } else {
                VStack(spacing: 12) {
                    ForEach(supplies) { item in
                        SupplyRow(
                            item: item,
                            onUse: { store.useSupply(item.id) },
                            onRestock: { store.restockSupply(item.id) },
                            onEdit: { activeSheet = .editSupply(item) }
                        )
                    }
                }
                .padding(.horizontal, 18)
            }
        }
    }

    private var emptyKidsState: some View {
        VStack(spacing: 16) {
            Image(systemName: "backpack.fill")
                .font(.system(size: 48))
                .foregroundStyle(RMTheme.inkFaded)
            Text("No kids yet")
                .font(RMTheme.headlineFont)
                .foregroundStyle(RMTheme.ink)
            Text("Add a kid to start tracking their school supplies.")
                .font(.subheadline)
                .foregroundStyle(RMTheme.inkFaded)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.top, 40)
    }

    private func emptySuppliesState(kid: Kid) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "pencil.and.list.clipboard")
                .font(.system(size: 40))
                .foregroundStyle(RMTheme.inkFaded)
            Text("No supplies tracked for \(kid.name) yet.")
                .font(.subheadline)
                .foregroundStyle(RMTheme.inkFaded)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 16)
        .padding(.horizontal, 32)
    }
}

/// The quirky signature feature: each supply renders as a literal pencil (or
/// glue stick) that visibly shortens as it's used, like a real classroom
/// supply wearing down — not just a generic progress bar.
struct SupplyRow: View {
    let item: SupplyItem
    var onUse: () -> Void
    var onRestock: () -> Void
    var onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button(action: onEdit) {
                    HStack(spacing: 8) {
                        Image(systemName: item.kind.systemImage)
                            .foregroundStyle(RMTheme.graphite)
                        Text(item.name)
                            .font(RMTheme.headlineFont)
                            .foregroundStyle(RMTheme.ink)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("supplyNameLabel_\(item.name)")

                Spacer()

                if item.needsRestock {
                    Text("RESTOCK")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(RMTheme.lowStock)
                        .clipShape(Capsule())
                        .accessibilityIdentifier("restockBadge_\(item.name)")
                }
            }

            supplyShrinkVisual

            HStack(spacing: 10) {
                Button("Use") { onUse() }
                    .buttonStyle(.plain)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(item.isEmpty ? RMTheme.rule : RMTheme.surfaceRaised)
                    .foregroundStyle(item.isEmpty ? RMTheme.inkFaded : RMTheme.ink)
                    .clipShape(Capsule())
                    .disabled(item.isEmpty)
                    .accessibilityIdentifier("useButton_\(item.name)")

                Button("Restocked") { onRestock() }
                    .buttonStyle(.plain)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(RMTheme.tapeRed)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .accessibilityIdentifier("restockButton_\(item.name)")

                Spacer()

                Text("\(Int(item.level * 100))%")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RMTheme.inkFaded)
                    .accessibilityIdentifier("levelLabel_\(item.name)")
            }
        }
        .padding(14)
        .background(RMTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RMTheme.rule, lineWidth: 1))
    }

    /// Draws a literal shrinking bar shaped like the supply: a pencil with a
    /// visible tip that gets shorter, or a glue-stick/eraser block that
    /// visibly shrinks from the right edge, animated on every use.
    private var supplyShrinkVisual: some View {
        GeometryReader { geo in
            let fullWidth = geo.size.width
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(RMTheme.surfaceRaised)
                    .frame(height: 22)

                HStack(spacing: 0) {
                    Rectangle()
                        .fill(barColor)
                        .frame(width: max(4, fullWidth * item.level), height: 22)
                    if item.kind == .pencil {
                        Triangle()
                            .fill(RMTheme.graphite)
                            .frame(width: 14, height: 14)
                            .opacity(item.isEmpty ? 0 : 1)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: item.level)
            }
        }
        .frame(height: 22)
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("shrinkVisual_\(item.name)")
        .accessibilityValue("\(Int(item.level * 100)) percent remaining")
    }

    private var barColor: Color {
        if item.needsRestock { return RMTheme.lowStock }
        switch item.kind {
        case .pencil: return RMTheme.pencilYellow
        case .glueStick: return Color(red: 0.83, green: 0.87, blue: 0.66)
        case .eraser: return Color(red: 0.90, green: 0.55, blue: 0.62)
        case .notebook: return RMTheme.tapeRed.opacity(0.7)
        case .crayon: return Color(red: 0.95, green: 0.55, blue: 0.25)
        case .other: return RMTheme.graphite.opacity(0.5)
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    ReamHomeView()
        .environmentObject(ReamStore())
        .environmentObject(PurchaseManager())
}
