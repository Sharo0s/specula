import Foundation
import Network

// MARK: - Détection du réseau (README : « NWPathMonitor + présence du daemon TS »)
// Maison = Wi-Fi/Ethernet → URLs locales ; sinon, si une interface porte une
// adresse CGNAT Tailscale (100.64.0.0/10), on passe par le tailnet.

@MainActor
@Observable
final class NetworkMonitor {
    private(set) var onLocalNetwork = true
    private(set) var tailscaleActive = false
    var onChange: (() -> Void)?

    private let monitor = NWPathMonitor()

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let local = path.usesInterfaceType(.wifi) || path.usesInterfaceType(.wiredEthernet)
            let ts = Self.hasTailscaleAddress()
            Task { @MainActor [weak self] in
                guard let self else { return }
                let changed = local != onLocalNetwork || ts != tailscaleActive
                onLocalNetwork = local
                tailscaleActive = ts
                if changed { onChange?() }
            }
        }
        monitor.start(queue: DispatchQueue(label: "specula.netmonitor"))
    }

    /// Une interface avec une adresse dans 100.64.0.0/10 = daemon Tailscale actif.
    nonisolated private static func hasTailscaleAddress() -> Bool {
        var addrs: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&addrs) == 0, let first = addrs else { return false }
        defer { freeifaddrs(addrs) }
        var ptr: UnsafeMutablePointer<ifaddrs>? = first
        while let ifa = ptr {
            if let sa = ifa.pointee.ifa_addr, sa.pointee.sa_family == sa_family_t(AF_INET) {
                let addr = ifa.pointee.ifa_addr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) {
                    UInt32(bigEndian: $0.pointee.sin_addr.s_addr)
                }
                // 100.64.0.0/10 → 100.64.0.0 … 100.127.255.255
                if (addr & 0xFFC0_0000) == 0x6440_0000 { return true }
            }
            ptr = ifa.pointee.ifa_next
        }
        return false
    }
}
