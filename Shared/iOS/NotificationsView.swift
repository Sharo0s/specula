#if os(iOS)
import SwiftUI

// MARK: - Notifications iPhone

struct NotificationsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Retour")
                            .font(.archivo(13, .semibold))
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Ink.text)
                Spacer()
                Button {
                    store.markAllRead()
                } label: {
                    Text("Tout lire")
                        .font(.archivo(12, .heavy))
                        .foregroundStyle(Ink.accentText)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)

            HStack {
                Text("Notifications")
                    .font(.archivo(24, .heavy))
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 10)

            HRule(weight: 2).padding(.horizontal, 18)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(store.notifs.enumerated()), id: \.element.id) { i, n in
                        if i > 0 { HRule().padding(.leading, 18) }
                        NotifRow(item: n)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onDisappear { store.markAllRead() }
    }
}

struct NotifRow: View {
    let item: NotifItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Rectangle()
                .fill(item.alert ? Ink.accent : Ink.text)
                .frame(width: 10, height: 10)
                .padding(.top, 4)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.title)
                    .font(.archivo(13, .bold))
                Text(item.sub)
                    .font(.archivo(11))
                    .foregroundStyle(Ink.muted)
            }
            Spacer()
            Text(item.timeLabel)
                .font(.archivo(10)).monospacedDigit()
                .foregroundStyle(Ink.muted)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(item.unread ? Ink.unreadBg : .clear)
    }
}
#endif
