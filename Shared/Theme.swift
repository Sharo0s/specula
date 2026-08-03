import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Modernist design tokens
// Source de vérité : _ds/modernist-…/styles.css + README du handoff.
// Flat, architectural, radius 0 partout, filets 2px/1px, encre + un seul accent rouge.

enum Ink {

    // Couleur dynamique clair / sombre
    private static func dyn(_ light: String, _ dark: String) -> Color {
        #if os(watchOS)
        // watchOS est toujours sombre
        return Color(hex: dark)
        #elseif canImport(UIKit)
        return Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
        #else
        return Color(NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? NSColor(hex: dark) : NSColor(hex: light)
        })
        #endif
    }

    /// fond `#f3f2f2` / `#201e1d`
    static let bg = dyn("f3f2f2", "201e1d")
    /// surface (cartes, sidebar) `#eae9e9` / `#2d2b2b`
    static let surface = dyn("eae9e9", "2d2b2b")
    /// texte / encre `#201e1d` / `#f3f2f2`
    static let text = dyn("201e1d", "f3f2f2")
    /// filets : encre à 40 %
    static let divider = text.opacity(0.4)
    /// texte atténué : encre à 55 %
    static let muted = text.opacity(0.55)
    /// accent — identique dans les deux modes
    static let accent = Color(hex: "ec3013")
    /// texte accent lisible sur le fond : `#ae1800` / `#ff9783`
    static let accentText = dyn("ae1800", "ff9783")
    /// accent-300, ring des cartes en panne
    static let accentRing = dyn("ffc4b8", "7c1405")
    /// accent-2 du design system — corail orangé, « attention sans gravité »
    static let accent2 = Color(hex: "e15b47")
    /// texte accent-2 lisible : `#9e3526` / `#ff9784`
    static let accent2Text = dyn("9e3526", "ff9784")
    /// fond de tag accent-2 : `#ffe0da` / `#71261b`
    static let accent2Bg = dyn("ffe0da", "71261b")
    /// tag latence : fond `#f8f4f4` / `#3a3737`
    static let tagBg = dyn("f8f4f4", "3a3737")
    /// tag latence : texte `#444141` / `#d7d3d3`
    static let tagText = dyn("444141", "d7d3d3")
    /// rangée non lue `#fff2ef` / `#4d170e`
    static let unreadBg = dyn("fff2ef", "4d170e")
    /// tuile logo : fond neutre clair `#f8f4f4` / `#3a3737`
    static let tileBg = tagBg
    /// piste inactive des interrupteurs
    static let switchOff = dyn("d7d3d3", "605d5d")
    /// console encre (journal) — toujours sombre
    static let console = Color(hex: "201e1d")
    static let consoleText = Color(hex: "f3f2f2")
}

// MARK: - Typographie Archivo

extension Font {
    /// Facteur d'échelle global de l'UI. Le Mac agrandit un peu toute l'interface
    /// (le texte passe par ce seul point d'entrée → agrandissement net, sans flou).
    static var uiScale: CGFloat {
        #if os(macOS)
        1.12
        #else
        1
        #endif
    }

    /// Archivo — titres 800, corps 400. Chiffres en direct : ajouter `.monospacedDigit()`.
    static func archivo(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .custom("Archivo", size: size * uiScale).weight(weight)
    }
}

extension View {
    /// Libellé uppercase letter-spacing 0.08em (métriques, h6 de groupe).
    func upperLabel(_ size: CGFloat, _ weight: Font.Weight = .regular) -> some View {
        font(.archivo(size, weight))
            .textCase(.uppercase)
            .tracking(size * 0.08)
    }
}

// MARK: - Filets structurels

/// Filet horizontal — 2 px entre sections majeures, 1 px entre rangées.
struct HRule: View {
    var weight: CGFloat = 1
    var color: Color = Ink.divider
    var body: some View {
        color.frame(height: weight)
    }
}

/// Filet vertical.
struct VRule: View {
    var weight: CGFloat = 1
    var color: Color = Ink.divider
    var body: some View {
        color.frame(width: weight)
    }
}

// MARK: - Hex helpers

extension Color {
    init(hex: String) {
        var v: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&v)
        self.init(red: Double((v >> 16) & 0xFF) / 255,
                  green: Double((v >> 8) & 0xFF) / 255,
                  blue: Double(v & 0xFF) / 255)
    }
}

#if canImport(UIKit)
extension UIColor {
    convenience init(hex: String) {
        var v: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&v)
        self.init(red: CGFloat((v >> 16) & 0xFF) / 255,
                  green: CGFloat((v >> 8) & 0xFF) / 255,
                  blue: CGFloat(v & 0xFF) / 255, alpha: 1)
    }
}
#else
extension NSColor {
    convenience init(hex: String) {
        var v: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&v)
        self.init(srgbRed: CGFloat((v >> 16) & 0xFF) / 255,
                  green: CGFloat((v >> 8) & 0xFF) / 255,
                  blue: CGFloat(v & 0xFF) / 255, alpha: 1)
    }
}
#endif
