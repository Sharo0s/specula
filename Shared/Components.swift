import SwiftUI

// MARK: - Composants Modernist partagés
// Radius 0 partout, flush-left, aucune ombre décorative.

/// Tuile pictogramme : logo dashboard-icons par slug, monogramme 2 lettres en secours.
struct ServiceTile: View {
    @Environment(AppStore.self) private var store
    let service: Service
    var size: CGFloat = 38
    var down = false

    var body: some View {
        Group {
            if let url = store.iconURL(service) {
                ZStack {
                    Ink.tileBg
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFit()
                        } else {
                            monogram
                        }
                    }
                    .padding(size * 0.16)
                }
            } else {
                ZStack {
                    down ? Ink.accent : Ink.text
                    monogram
                }
            }
        }
        .frame(width: size, height: size)
    }

    private var monogram: some View {
        Text(service.mono)
            .font(.archivo(size * 0.38, .heavy))
            .foregroundStyle(store.iconURL(service) != nil ? Ink.text : Ink.bg)
    }
}

/// Tag de latence — « 12 MS » / « HORS LIGNE ».
struct LatencyTag: View {
    let text: String
    var down = false
    /// Latence élevée ou mesure en attente — accent-2 (orange).
    var slow = false
    var size: CGFloat = 9.5

    var body: some View {
        Text(text)
            .font(.archivo(size, .bold))
            .monospacedDigit()
            .tracking(size * 0.02)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(down ? Ink.accent : (slow ? Ink.accent2Bg : Ink.tagBg))
            .foregroundStyle(down ? Ink.bg : (slow ? Ink.accent2Text : Ink.tagText))
    }
}

/// Contrôle segmenté Modernist : bordure 1 px, option active = encre pleine.
struct MSeg<T: Hashable>: View {
    let options: [(T, String)]
    @Binding var selection: T
    var fontSize: CGFloat = 10.5

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.offset) { _, opt in
                Button {
                    selection = opt.0
                } label: {
                    Text(LocalizedStringKey(opt.1))
                        .font(.archivo(fontSize, .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(selection == opt.0 ? Ink.text : .clear)
                        .foregroundStyle(selection == opt.0 ? Ink.bg : Ink.text)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
        .overlay(Rectangle().strokeBorder(Ink.divider, lineWidth: 1))
    }
}

/// Interrupteur carré Modernist — piste encre = actif, 150 ms.
struct MSwitch: View {
    @Binding var isOn: Bool
    var width: CGFloat = 44
    var height: CGFloat = 26

    var body: some View {
        Button {
            withAnimation(.linear(duration: 0.15)) { isOn.toggle() }
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Rectangle().fill(isOn ? Ink.text : Ink.switchOff)
                Rectangle()
                    .fill(Ink.bg)
                    .frame(width: height - 8, height: height - 8)
                    .padding(4)
            }
            .frame(width: width, height: height)
        }
        .buttonStyle(.plain)
    }
}

/// Bouton primaire pleine largeur — accent, libellé flush-left, 800.
struct MPrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(LocalizedStringKey(title))
                .font(.archivo(14, .heavy))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Ink.accent)
                .foregroundStyle(.white)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

/// Bouton secondaire pleine largeur — bordure 1 px, flush-left.
struct MSecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(LocalizedStringKey(title))
                .font(.archivo(14, .heavy))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .overlay(Rectangle().strokeBorder(Ink.divider, lineWidth: 1))
                .foregroundStyle(Ink.text)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

/// En-tête de groupe : h6 uppercase + compteur + filet 2 px.
struct GroupHeader: View {
    let name: String
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(LocalizedStringKey(name))
                    .upperLabel(10.5, .heavy)
                Text(String(format: "%02d", count))
                    .font(.archivo(10)).monospacedDigit()
                    .foregroundStyle(Ink.muted)
            }
            HRule(weight: 2)
        }
    }
}

/// Cellule de métrique : valeur 800 tabular + libellé uppercase.
struct MetricCell: View {
    let value: String
    let label: String
    var valueSize: CGFloat = 20
    var labelSize: CGFloat = 8.5
    var accent = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.archivo(valueSize, .heavy))
                .monospacedDigit()
                .foregroundStyle(accent ? Ink.accentText : Ink.text)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(LocalizedStringKey(label))
                .upperLabel(labelSize)
                .foregroundStyle(Ink.muted)
        }
    }
}

/// Graphe barres 24 points, aligné bas, sans animation.
struct BarChart: View {
    /// Valeurs normalisées 0…1.
    let values: [Double]
    var color: Color = Ink.text
    var gap: CGFloat = 2

    var body: some View {
        GeometryReader { geo in
            let n = max(values.count, 1)
            let w = (geo.size.width - gap * CGFloat(n - 1)) / CGFloat(n)
            HStack(alignment: .bottom, spacing: gap) {
                ForEach(Array(values.enumerated()), id: \.offset) { _, v in
                    Rectangle()
                        .fill(color)
                        .frame(width: max(w, 1), height: max(4, geo.size.height * min(1, v)))
                }
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }
}

/// Journal de conteneur : console encre, mono 9.5, 6 lignes.
struct ConsoleLog: View {
    let lines: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(.system(size: 9.5, design: .monospaced))
                    .foregroundStyle(Ink.consoleText.opacity(line.hasPrefix("WARN") ? 1 : 0.75))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Ink.console)
    }
}

/// Toast de confirmation — barre encre, bas de l'écran, 2,2 s.
struct ToastOverlay: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack {
            Spacer()
            if let toast = store.toast {
                Text(toast)
                    .font(.archivo(13.5, .semibold))
                    .foregroundStyle(Ink.bg)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Ink.text)
                    .padding(.bottom, 28)
                    .transition(.opacity)
            }
        }
        .animation(.linear(duration: 0.15), value: store.toast)
        .allowsHitTesting(false)
    }
}

/// Bandeau système — cellules bordées de filets.
struct SystemBandCell: View {
    let value: String
    let label: String
    var progress: Double? = nil
    var tint: Color? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.archivo(17, .heavy))
                .monospacedDigit()
                .foregroundStyle(tint ?? Ink.text)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(LocalizedStringKey(label))
                .upperLabel(8.5)
                .foregroundStyle(Ink.muted)
            if let progress {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Ink.divider.opacity(0.5)
                        Ink.text.frame(width: geo.size.width * min(1, progress))
                    }
                }
                .frame(height: 3)
                .padding(.top, 3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Lecture en cours (Jellyfin) : ▶︎/⏸ titre (utilisateur) · position / durée + progression.
struct NowPlayingRow: View {
    let session: LiveFetcher.NowPlayingSession
    /// Pause/reprise — l'icône devient interactive quand fourni.
    var onTogglePause: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Button {
                    onTogglePause?()
                } label: {
                    Image(systemName: session.paused ? "pause.fill" : "play.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Ink.accent2)
                        .frame(width: 18, height: 18)
                        .overlay(Rectangle().strokeBorder(
                            onTogglePause == nil ? .clear : Ink.divider, lineWidth: 1))
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .disabled(onTogglePause == nil)
                Text(verbatim: session.user.isEmpty
                     ? session.title : "\(session.title) (\(session.user))")
                    .font(.archivo(11, .bold))
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text(verbatim: "\(timecode(session.position)) / \(timecode(session.duration))")
                    .font(.archivo(10)).monospacedDigit()
                    .foregroundStyle(Ink.muted)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Ink.divider.opacity(0.4)
                    Ink.accent2.frame(width: geo.size.width * fraction)
                }
            }
            .frame(height: 3)
        }
    }

    private var fraction: Double {
        session.duration > 0 ? min(1, Double(session.position) / Double(session.duration)) : 0
    }

    private func timecode(_ seconds: Int) -> String {
        seconds >= 3600
            ? String(format: "%d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60)
            : String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

/// Petit carré de marque — LE carré rouge Specula.
struct BrandSquare: View {
    var size: CGFloat = 15
    var body: some View {
        Rectangle().fill(Ink.accent).frame(width: size, height: size)
    }
}

/// Carte service dense — dashboard Mac et grille iPad.
/// Tuile + nom + description + tag latence, filet, 3 métriques.
struct ServiceCard: View {
    @Environment(AppStore.self) private var store
    let service: Service
    var pad: CGFloat = 12
    var selected = false
    let select: () -> Void

    var body: some View {
        let down = store.isDown(service)
        Button(action: select) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 10) {
                    ServiceTile(service: service, size: 34, down: down)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(service.name)
                            .font(.archivo(14, .heavy))
                            .foregroundStyle(down ? Ink.accentText : Ink.text)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(LocalizedStringKey(service.desc))
                            .font(.archivo(10.5))
                            .foregroundStyle(Ink.muted)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    LatencyTag(text: store.pingText(service), down: down,
                               slow: store.isSlow(service), size: 9)
                }
                HRule()
                HStack(spacing: 0) {
                    ForEach(Array(store.metrics(service).prefix(3).enumerated()), id: \.offset) { i, m in
                        if i > 0 { Spacer(minLength: 6) }
                        MetricCell(value: m[0], label: m[1], valueSize: 15, labelSize: 8)
                    }
                }
                // Lecture en cours (Jellyfin)
                if let sessions = store.nowPlaying[service.id], !sessions.isEmpty {
                    HRule()
                    ForEach(Array(sessions.prefix(2)), id: \.self) { session in
                        NowPlayingRow(session: session) {
                            store.togglePause(service, session: session)
                        }
                    }
                }
            }
            .padding(pad)
            .background(Ink.surface)
            .overlay(Rectangle().strokeBorder(
                selected ? Ink.accent : (down ? Ink.accentRing : .clear), lineWidth: 2))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
