import SwiftUI

/// Ream's identity: composition-notebook marble (black/white flecked cover)
/// with red spine-tape trim and a chalk/pencil-yellow accent — a fresh
/// school-supply palette distinct from every sibling app's colors.
enum RMTheme {
    static let backdrop = Color(red: 0.965, green: 0.961, blue: 0.949)   // notebook paper cream-white
    static let surface = Color.white
    static let surfaceRaised = Color(red: 0.925, green: 0.921, blue: 0.910)
    static let ink = Color(red: 0.114, green: 0.114, blue: 0.129)        // marble-cover black
    static let inkFaded = Color(red: 0.114, green: 0.114, blue: 0.129).opacity(0.55)
    static let rule = Color.black.opacity(0.10)

    static let tapeRed = Color(red: 0.729, green: 0.180, blue: 0.161)    // composition-book spine tape
    static let pencilYellow = Color(red: 0.945, green: 0.769, blue: 0.180)
    static let graphite = Color(red: 0.325, green: 0.325, blue: 0.353)
    static let danger = Color(red: 0.729, green: 0.180, blue: 0.161)
    static let success = Color(red: 0.220, green: 0.522, blue: 0.298)
    static let lowStock = Color(red: 0.827, green: 0.412, blue: 0.129)

    static let titleFont = Font.system(.title2, design: .rounded).weight(.bold)
    static let headlineFont = Font.system(.headline, design: .rounded).weight(.semibold)
}

struct DismissKeyboardOnTap: ViewModifier {
    func body(content: Content) -> some View {
        content.simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            }
        )
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTap())
    }
}
