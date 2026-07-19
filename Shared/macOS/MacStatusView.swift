#if os(macOS)
import SwiftUI

// MARK: - Statut : mur de disponibilité 30 j

struct MacStatusView: View {
    @Environment(AppStore.self) private var store
    @State private var incident: IncidentSelection?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Disponibilité sur 30 jours")
                        .upperLabel(10.5, .heavy)
                    Spacer()
                    Text("J-29 → aujourd'hui")
                        .font(.archivo(10))
                        .foregroundStyle(Ink.muted)
                }
                .padding(.bottom, 6)
                HRule(weight: 2)

                // Panneau incident — sous l'en-tête, au-dessus des rangées
                if let inc = incident {
                    HStack(alignment: .top, spacing: 14) {
                        Rectangle().fill(Ink.accent).frame(width: 10, height: 10)
                            .padding(.top, 4)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("INCIDENT — \(inc.service)")
                                .upperLabel(10, .heavy)
                                .foregroundStyle(Ink.accentText)
                            Text("\(inc.when) · \(inc.duration)")
                                .font(.archivo(12, .bold)).monospacedDigit()
                            Text(inc.cause)
                                .font(.archivo(11.5))
                                .foregroundStyle(Ink.muted)
                        }
                        Spacer()
                        Button {
                            incident = nil
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .semibold))
                                .frame(width: 24, height: 24)
                                .overlay(Rectangle().strokeBorder(Ink.divider, lineWidth: 1))
                                .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(Ink.text)
                    }
                    .padding(14)
                    .background(Ink.surface)
                    .overlay(Rectangle().strokeBorder(Ink.accentRing, lineWidth: 2))
                    .padding(.top, 12)
                }

                // Rangées par service
                VStack(spacing: 0) {
                    ForEach(Array(store.services.enumerated()), id: \.element.id) { i, s in
                        if i > 0 { HRule() }
                        row(s)
                    }
                }
                .padding(.top, 8)
            }
            .padding(20)
            .padding(.bottom, 30)
        }
    }

    private func row(_ s: Service) -> some View {
        let incs = store.incidents(for: s)
        let liveDown = store.isDown(s)
        let hasIssue = !incs.isEmpty || liveDown
        return HStack(spacing: 14) {
            Text(s.name)
                .font(.archivo(12.5, .heavy))
                .frame(width: 150, alignment: .leading)
                .lineLimit(1)
            HStack(spacing: 3) {
                ForEach(0..<30, id: \.self) { day in
                    let inc = incs.first { $0.day == day }
                    let live = day == 29 && liveDown
                    let bad = inc != nil || live
                    Rectangle()
                        .fill(bad ? Ink.accent : Ink.text)
                        .frame(maxWidth: .infinity)
                        .frame(height: 15)
                        .onTapGesture {
                            guard bad else { return }
                            incident = IncidentSelection(
                                service: s.name,
                                when: live ? "aujourd'hui · en cours" : "J-\(29 - day)",
                                duration: live ? "\(store.downDurationMin) min" : (inc?.duration ?? ""),
                                cause: live ? "Délai dépassé (timeout) — 3 tentatives échouées" : (inc?.cause ?? ""))
                        }
                }
            }
            Text(store.availability(s))
                .font(.archivo(12.5, .heavy)).monospacedDigit()
                .foregroundStyle(hasIssue ? Ink.accentText : Ink.text)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.vertical, 9)
    }
}
#endif
