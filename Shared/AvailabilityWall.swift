import SwiftUI

// MARK: - Mur de disponibilité — corps commun aux deux plateformes
//
// Le Mac et l'iPhone montraient deux murs écrits séparément, qui divergeaient à
// chaque retouche. Tout ce qui suit est partagé ; les deux pages n'en gardent
// que leur chrome propre — barre de titre, feuille ou pile de navigation.
//
// Trois états par jour, et l'ordre compte : une panne prime sur une lenteur,
// une lenteur sur un jour sain. Un service à terre n'est pas « lent ».

enum WallPeriod: Int, CaseIterable, Identifiable {
    case week = 7, fortnight = 14, month = 30
    var id: Int { rawValue }
    /// Trois clés littérales plutôt qu'une interpolée. « j » abrège « jours »
    /// et doit se traduire, mais `String(localized: "\(rawValue) j")` ne le
    /// permet pas : l'extracteur écrit `%@ j` dans le catalogue là où
    /// l'exécution cherche `%lld j`. Les deux ne se rencontrent jamais, et le
    /// libellé retombe silencieusement sur le français.
    var label: String {
        switch self {
        case .week: String(localized: "7 j")
        case .fortnight: String(localized: "14 j")
        case .month: String(localized: "30 j")
        }
    }
}

enum DayState {
    case ok, degraded, down
}

struct AvailabilityWall: View {
    @Environment(AppStore.self) private var store
    @Binding var period: WallPeriod
    @Binding var incident: IncidentSelection?

    /// Le survol n'existe qu'au pointeur ; sur iOS la valeur reste nulle.
    @State private var hovered: (service: String, day: Int)?

    /// Profondeur de l'historique tenu par `AppStore`.
    static let history = 30

    private var days: Int { period.rawValue }
    private var shown: Range<Int> { (Self.history - days)..<Self.history }

    /// Services à incident d'abord, puis les dégradés, puis les sains — l'ordre
    /// de la configuration ne dit rien de ce qui va mal, et une page de statut
    /// n'a que cette question à traiter. À gravité égale, l'ordre d'origine est
    /// conservé : deux lectures successives ne doivent pas permuter les rangées.
    private var ranked: [Service] {
        store.services.enumerated().sorted { a, b in
            let ga = gravity(a.element), gb = gravity(b.element)
            return ga == gb ? a.offset < b.offset : ga > gb
        }.map(\.element)
    }

    private func gravity(_ s: Service) -> Int {
        if store.isDown(s) { return 3 }
        if incidentDays(s).isEmpty == false { return 2 }
        if degraded(s).isEmpty == false { return 1 }
        return 0
    }

    private func incidentDays(_ s: Service) -> [Incident] {
        store.incidents(for: s).filter { shown.contains($0.day) }
    }

    private func degraded(_ s: Service) -> Set<Int> {
        store.degradedDays(for: s).filter { shown.contains($0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            summary
            HRule(weight: 2)
            if store.services.isEmpty {
                Text("Aucun service configuré — le mur se remplit dès qu'un service est suivi.")
                    .font(.archivo(12))
                    .foregroundStyle(Ink.muted)
                    .padding(.top, 16)
            } else {
                if let inc = incident { incidentPanel(inc) }
                VStack(spacing: 0) {
                    ForEach(Array(ranked.enumerated()), id: \.element.id) { i, s in
                        if i > 0 { HRule() }
                        row(s)
                    }
                }
                .padding(.top, 8)
                legend
            }
        }
    }

    // MARK: Résumé

    private var summary: some View {
        let faulty = store.services.filter { gravity($0) > 0 }.count
        let worst = ranked.first.flatMap { gravity($0) > 0 ? $0 : nil }
        // Le résumé prend toute la largeur sous le titre : mis à côté du
        // sélecteur, il se faisait tronquer dès qu'un nom de service était long.
        return VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 14) {
                Text("Disponibilité")
                    .upperLabel(10.5, .heavy)
                Spacer(minLength: 8)
                MSeg(options: WallPeriod.allCases.map { ($0, $0.label) }, selection: $period)
            }
            Text(worst.map {
                String(localized: "\(faulty) service(s) en défaut · le plus instable : \($0.name)")
            } ?? String(localized: "Aucun incident sur la période"))
                .font(.archivo(10.5))
                .foregroundStyle(worst == nil ? Ink.muted : Ink.accentText)
                .lineLimit(1)
        }
        .padding(.bottom, 8)
    }

    // MARK: Panneau d'incident

    private func incidentPanel(_ inc: IncidentSelection) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Rectangle().fill(Ink.accent).frame(width: 10, height: 10)
                .padding(.top, 4)
            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "INCIDENT — \(inc.service)"))
                    .upperLabel(10, .heavy)
                    .foregroundStyle(Ink.accentText)
                Text(verbatim: "\(inc.when) · \(inc.duration)")
                    .font(.archivo(12, .bold)).monospacedDigit()
                Text(inc.cause)
                    .font(.archivo(11.5))
                    .foregroundStyle(Ink.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
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

    // MARK: Rangée

    private func row(_ s: Service) -> some View {
        let incs = store.incidents(for: s)
        let degs = store.degradedDays(for: s)
        let liveDown = store.isDown(s)
        let hasIssue = !incidentDays(s).isEmpty || liveDown
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Text(s.name)
                    .font(.archivo(13, .heavy))
                    .lineLimit(1)
                Spacer(minLength: 8)
                if let h = hovered, h.service == s.id {
                    Text(dayCaption(h.day, state: state(s, day: h.day, incs: incs, degs: degs)))
                        .font(.archivo(10.5)).monospacedDigit()
                        .foregroundStyle(Ink.muted)
                }
                Text(store.availability(s, days: days))
                    .font(.archivo(13, .heavy)).monospacedDigit()
                    .foregroundStyle(hasIssue ? Ink.accentText : Ink.text)
            }
            HStack(spacing: 3) {
                ForEach(Array(shown), id: \.self) { day in
                    block(s, day: day, incs: incs, degs: degs)
                }
            }
            let labels = dayLabels
            HStack(spacing: 3) {
                ForEach(Array(shown), id: \.self) { day in
                    // `fixedSize` laisse le repère déborder de sa colonne : à
                    // trente jours une colonne fait 10 pt, et sans lui tous les
                    // repères se réduisent à « … ». Le débordement ne chevauche
                    // rien tant que les colonnes écrites restent espacées.
                    Text(labels[day] ?? " ")
                        .font(.archivo(8.5)).monospacedDigit()
                        .foregroundStyle(day == Self.history - 1 ? Ink.text : Ink.muted)
                        .fixedSize()
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 10)
    }

    private func block(_ s: Service, day: Int, incs: [Incident], degs: Set<Int>) -> some View {
        let st = state(s, day: day, incs: incs, degs: degs)
        let isToday = day == Self.history - 1
        return Rectangle()
            .fill(colour(st))
            .frame(maxWidth: .infinity)
            .frame(height: 22)
            // Aujourd'hui porte un liseré : sans lui, le dernier carré n'est
            // qu'un carré de plus et le mur n'a pas de point d'ancrage.
            .overlay(isToday ? Rectangle().strokeBorder(Ink.text, lineWidth: 2) : nil)
            .contentShape(.rect)
            .onTapGesture {
                guard st != .ok else { return }
                let inc = incs.first { $0.day == day }
                let live = isToday && store.isDown(s)
                incident = IncidentSelection(
                    service: s.name,
                    when: dayCaption(day, state: st),
                    duration: live ? String(localized: "\(store.downDurationMin) min")
                                   : (inc?.duration ?? String(localized: "journée entière")),
                    cause: live ? String(localized: "Délai dépassé (timeout) — 3 tentatives échouées")
                                : (inc?.cause ?? String(localized: "Latence au-dessus de \(AppStore.slowMs) ms sur trois relevés")))
            }
            .onHover { inside in
                hovered = inside ? (s.id, day) : nil
            }
    }

    private func state(_ s: Service, day: Int, incs: [Incident], degs: Set<Int>) -> DayState {
        if day == Self.history - 1 && store.isDown(s) { return .down }
        if incs.contains(where: { $0.day == day }) { return .down }
        if degs.contains(day) { return .degraded }
        return .ok
    }

    private func colour(_ st: DayState) -> Color {
        switch st {
        case .down: Ink.accent
        case .degraded: Ink.accent2
        case .ok: Ink.text
        }
    }

    // MARK: Repères de dates

    /// Toutes les colonnes portent leur jour tant qu'elles sont assez larges ;
    /// au-delà de quinze, une sur cinq, plus aujourd'hui.
    private func labelled(_ day: Int) -> Bool {
        if days <= 14 { return true }
        return day == Self.history - 1 || (Self.history - 1 - day) % 5 == 0
    }

    private func dateFor(_ day: Int) -> Date {
        Calendar.current.date(byAdding: .day,
                              value: -(Self.history - 1 - day), to: Date()) ?? Date()
    }

    /// Le quantième suffit d'ordinaire, mais au changement de mois la suite
    /// « 28, 2 » se lit comme un retour en arrière. Le mois est donc abrégé sur
    /// la première colonne écrite et à chaque bascule — nulle part ailleurs, où
    /// il n'apprendrait rien.
    private var dayLabels: [Int: String] {
        let cal = Calendar.current
        var out: [Int: String] = [:]
        var lastMonth: Int?
        for day in shown where labelled(day) {
            let date = dateFor(day)
            let month = cal.component(.month, from: date)
            out[day] = month == lastMonth
                ? date.formatted(.dateTime.day())
                : date.formatted(.dateTime.day().month(.abbreviated))
            lastMonth = month
        }
        return out
    }

    private func dayCaption(_ day: Int, state st: DayState) -> String {
        let back = Self.history - 1 - day
        let when = back == 0 ? String(localized: "aujourd'hui") : String(localized: "J-\(back)")
        switch st {
        case .down: return String(localized: "\(when) · hors ligne")
        case .degraded: return String(localized: "\(when) · lent")
        case .ok: return when
        }
    }

    // MARK: Légende

    private var legend: some View {
        HStack(spacing: 14) {
            key(Ink.text, "En ligne")
            key(Ink.accent2, "Lent")
            key(Ink.accent, "Hors ligne")
            Spacer(minLength: 0)
        }
        .padding(.top, 12)
    }

    private func key(_ fill: Color, _ label: LocalizedStringKey) -> some View {
        HStack(spacing: 5) {
            Rectangle().fill(fill).frame(width: 10, height: 10)
            Text(label)
                .font(.archivo(10))
                .foregroundStyle(Ink.muted)
        }
    }
}
