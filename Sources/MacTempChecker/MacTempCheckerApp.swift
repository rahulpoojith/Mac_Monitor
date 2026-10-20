import AppKit
import Combine
import SwiftUI

@main
struct MacTempCheckerApp: App {
    @StateObject private var monitor = MonitorStore()

    var body: some Scene {
        Window("Mac Monitor", id: "dashboard") {
            DashboardView()
                .environmentObject(monitor)
                .frame(minWidth: 760, minHeight: 650)
        }
        MenuBarExtra {
            MenuBarView().environmentObject(monitor)
        } label: {
            Label("Mac Monitor", systemImage: "waveform.path.ecg")
        }
        .menuBarExtraStyle(.window)
    }
}

struct SecurityFinding: Identifiable {
    let type: String
    let process: String
    let pid: String
    var id: String { "\(pid)-\(process)" }
}

@MainActor
final class MonitorStore: ObservableObject {
    @Published private(set) var cpu = 0.0
    @Published private(set) var memoryUsed = 0.0
    @Published private(set) var memoryTotal = 0.0
    @Published private(set) var diskUsed = 0.0
    @Published private(set) var diskTotal = 0.0
    @Published private(set) var diskAvailable = 0.0
    @Published private(set) var temperature: Double?
    @Published private(set) var batteryTemperature: Double?
    @Published private(set) var thermal = "Normal"
    @Published private(set) var battery = "Plugged in"
    @Published private(set) var networkIn = 0.0
    @Published private(set) var networkOut = 0.0
    @Published private(set) var uptime = ""
    @Published private(set) var findings: [SecurityFinding] = []
    @Published private(set) var updated = Date()
    private var timer: Timer?
    private var previousNetwork: (UInt64, UInt64, Date)?

    init() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func refresh() {
        cpu = readCPU()
        (memoryUsed, memoryTotal) = readMemory()
        (diskUsed, diskTotal, diskAvailable) = readDisk()
        temperature = readTemperature()
        batteryTemperature = readBatteryTemperature()
        thermal = ProcessInfo.processInfo.thermalState.label
        battery = readBattery()
        readNetwork()
        findings = scanProcesses()
        uptime = formatUptime(ProcessInfo.processInfo.systemUptime)
        updated = Date()
    }

    private func command(_ path: String, _ arguments: [String] = []) -> String? {
        guard FileManager.default.isExecutableFile(atPath: path) else { return nil }
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return nil }
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }

    private func readCPU() -> Double {
        guard let output = command("/usr/bin/top", ["-l", "1", "-n", "0"]),
              let line = output.components(separatedBy: .newlines).first(where: { $0.contains("CPU usage:") }),
              let range = line.range(of: #"([0-9.]+)% user,\s*([0-9.]+)% sys"#, options: .regularExpression) else { return 0 }
        let values = line[range].split(whereSeparator: { !$0.isNumber && $0 != "." }).compactMap { Double($0) }
        return min((values.first ?? 0) + (values.last ?? 0), 100)
    }

    private func readMemory() -> (Double, Double) {
        let total = Double(ProcessInfo.processInfo.physicalMemory)
        guard let output = command("/usr/bin/vm_stat") else { return (0, total) }
        let pageSize = output.range(of: #"page size of ([0-9]+) bytes"#, options: .regularExpression)
            .flatMap { Int(output[$0].filter(\.isNumber)) } ?? 4096
        let names = ["Pages active", "Pages wired down", "Pages occupied by compressor"]
        let pages = output.split(separator: "\n").reduce(0.0) { sum, line in
            guard names.contains(where: { line.hasPrefix($0) }) else { return sum }
            return sum + (line.split(whereSeparator: { !$0.isNumber }).compactMap { Double($0) }.first ?? 0)
        }
        return (min(pages * Double(pageSize), total), total)
    }

    private func readDisk() -> (Double, Double, Double) {
        let home = URL(fileURLWithPath: NSHomeDirectory())
        let keys: Set<URLResourceKey> = [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeAvailableCapacityKey
        ]
        if let values = try? home.resourceValues(forKeys: keys),
           let total = values.volumeTotalCapacity {
            let available = values.volumeAvailableCapacityForImportantUsage.map { Int($0) } ?? values.volumeAvailableCapacity ?? 0
            return (Double(max(total - Int(available), 0)), Double(total), Double(available))
        }
        guard let attributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
              let total = attributes[.systemSize] as? NSNumber,
              let available = attributes[.systemFreeSize] as? NSNumber else { return (0, 0, 0) }
        let totalBytes = Double(total.int64Value)
        let availableBytes = Double(available.int64Value)
        return (max(totalBytes - availableBytes, 0), totalBytes, availableBytes)
    }

    private func readTemperature() -> Double? {
        for path in ["/opt/homebrew/bin/osx-cpu-temp", "/usr/local/bin/osx-cpu-temp"] {
            guard let output = command(path),
                  let range = output.range(of: #"[0-9]+(?:\.[0-9]+)?"#, options: .regularExpression),
                let value = Double(output[range]), value > 0 else { continue }
            return value
        }
        return nil
    }

    private func readBatteryTemperature() -> Double? {
        guard let output = command("/usr/sbin/ioreg", ["-r", "-c", "AppleSmartBattery", "-d", "1", "-l", "-w0"]),
              let range = output.range(of: #""Temperature"\s*=\s*[0-9]+"#, options: .regularExpression),
              let rawValue = Double(output[range].filter(\.isNumber)) else { return nil }
        let celsius = rawValue / 10 - 273.15
        return (0...80).contains(celsius) ? celsius : nil
    }

    private func readBattery() -> String {
        guard let output = command("/usr/bin/pmset", ["-g", "batt"]), output.contains("InternalBattery") else { return "Plugged in" }
        let percent = output.range(of: #"[0-9]+%"#, options: .regularExpression).map { String(output[$0]) } ?? ""
        let state = output.contains("discharging") ? "On battery" : "Charging"
        return [percent, state].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    private func readNetwork() {
        guard let output = command("/usr/sbin/netstat", ["-ibn"]) else { return }
        var received: UInt64 = 0
        var sent: UInt64 = 0
        for line in output.split(separator: "\n") {
            let fields = line.split(whereSeparator: \.isWhitespace)
            guard fields.count >= 11, fields[0].hasPrefix("en"), fields[2].hasPrefix("<Link#"),
                  let input = UInt64(fields[9]), let output = UInt64(fields[10]) else { continue }
            received += input
            sent += output
        }
        let now = Date()
        if let previousNetwork {
            let elapsed = max(now.timeIntervalSince(previousNetwork.2), 0.1)
            networkIn = Double(received >= previousNetwork.0 ? received - previousNetwork.0 : 0) / elapsed
            networkOut = Double(sent >= previousNetwork.1 ? sent - previousNetwork.1 : 0) / elapsed
        }
        previousNetwork = (received, sent, now)
    }

    private func scanProcesses() -> [SecurityFinding] {
        let indicators: [(type: String, names: [String])] = [
            ("Crypto-mining software", ["xmrig", "xmr-stak", "minerd", "cpuminer", "bfgminer", "cgminer", "ethminer", "lolminer", "nbminer", "phoenixminer", "kawpowminer", "teamredminer", "gminer", "nanominer", "wildrig", "srbminer"]),
            ("Remote-access software", ["anydesk", "teamviewer", "rustdesk", "screenconnect", "connectwisecontrol", "splashtop", "logmein", "gotoassist", "meshagent", "dwagent", "chrome remote desktop"])
        ]
        guard let output = command("/bin/ps", ["-axo", "pid=,comm="]) else { return [] }
        return output.split(separator: "\n").compactMap { line in
            let fields = line.split(maxSplits: 1, whereSeparator: \.isWhitespace)
            guard fields.count == 2 else { return nil }
            let name = URL(fileURLWithPath: String(fields[1])).lastPathComponent
            let normalized = name.lowercased()
            guard let match = indicators.first(where: { group in group.names.contains(where: normalized.contains) }) else { return nil }
            return SecurityFinding(type: match.type, process: name, pid: String(fields[0]))
        }
    }

    private func formatUptime(_ seconds: TimeInterval) -> String {
        let value = Int(seconds)
        let days = value / 86_400
        let hours = (value % 86_400) / 3_600
        let minutes = (value % 3_600) / 60
        if days > 0 { return "\(days)d \(hours)h" }
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
}

private extension ProcessInfo.ThermalState {
    var label: String {
        switch self {
        case .nominal: "Normal"
        case .fair: "Fair"
        case .serious: "Serious"
        case .critical: "Critical"
        @unknown default: "Unknown"
        }
    }
}

private extension Double {
    var gb: String { String(format: "%.1f", self / 1_000_000_000) }
    var mb: String { String(format: "%.1f", self / 1_000_000) }
}

struct DashboardView: View {
    @EnvironmentObject private var monitor: MonitorStore
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Mac Monitor").font(.system(size: 27, weight: .semibold, design: .rounded))
                    Text("Live system overview · Updated \(monitor.updated.formatted(date: .omitted, time: .standard))")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: monitor.refresh) { Label("Refresh", systemImage: "arrow.clockwise") }
                    .keyboardShortcut("r", modifiers: .command)
            }
            LazyVGrid(columns: columns, spacing: 12) {
                card("CPU", "\(Int(monitor.cpu))%", "Current total load", "cpu", monitor.cpu / 100, .blue)
                card("Memory", "\(monitor.memoryUsed.gb) / \(monitor.memoryTotal.gb) GB", "Active, wired, compressed", "memorychip", monitor.memoryUsed / max(monitor.memoryTotal, 1), .orange)
                card("Storage", "\(monitor.diskAvailable.gb) GB available", "\(monitor.diskUsed.gb) GB used / \(monitor.diskTotal.gb) GB", "internaldrive", monitor.diskUsed / max(monitor.diskTotal, 1), .green)
                card("Temperature", shownTemperature.map { "\(Int($0))°C" } ?? "Unavailable", temperatureDetail, "thermometer.medium", temperatureProgress, .red)
                card("Network", "↓ \(monitor.networkIn.mb)/s  ↑ \(monitor.networkOut.mb)/s", "Live throughput", "arrow.left.arrow.right", nil, .teal)
                card("Battery", monitor.battery, "Thermal pressure: \(monitor.thermal)", "battery.100", nil, .mint)
            }
            securitySection
            HStack {
                Label("Uptime", systemImage: "clock").foregroundStyle(.secondary)
                Text(monitor.uptime).fontWeight(.medium)
                Spacer()
                Text("Refreshes every 3 seconds").foregroundStyle(.tertiary)
            }
            .font(.callout)
            Spacer(minLength: 0)
        }
        .padding(22)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var shownTemperature: Double? {
        monitor.temperature ?? monitor.batteryTemperature
    }

    private var temperatureDetail: String {
        if monitor.temperature != nil { return "CPU sensor" }
        if monitor.batteryTemperature != nil { return "Battery sensor; CPU unavailable" }
        return "No readable sensor data"
    }

    private var temperatureProgress: Double? {
        if let temperature = monitor.temperature { return min(temperature / 100, 1) }
        if let temperature = monitor.batteryTemperature { return min(temperature / 80, 1) }
        return nil
    }

    private func card(_ title: String, _ value: String, _ detail: String, _ symbol: String, _ progress: Double?, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: symbol).font(.subheadline.weight(.medium)).foregroundStyle(tint)
            Text(value).font(.system(size: 21, weight: .semibold, design: .rounded)).lineLimit(1).minimumScaleFactor(0.7)
            Text(detail).font(.caption).foregroundStyle(.secondary).lineLimit(1).minimumScaleFactor(0.75)
            if let progress { ProgressView(value: min(max(progress, 0), 1)).tint(tint) }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 128, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.quaternary, lineWidth: 1))
    }

    private var securitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Process monitor", systemImage: "shield.lefthalf.filled").font(.headline)
                Spacer()
                Text(monitor.findings.isEmpty ? "No known indicators" : "Review findings")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(monitor.findings.isEmpty ? .green : .orange)
            }
            if monitor.findings.isEmpty {
                Text("No known miner or remote-access process names matched. This heuristic cannot confirm a Mac is malware-free.")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(monitor.findings) { finding in
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                        Text(finding.type).fontWeight(.medium)
                        Text("\(finding.process) · PID \(finding.pid)").foregroundStyle(.secondary)
                    }
                    .font(.callout)
                }
                Text("These tools can be legitimate. Verify each process; the app does not stop or remove anything.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.quaternary, lineWidth: 1))
    }
}

struct MenuBarView: View {
    @EnvironmentObject private var monitor: MonitorStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Mac Monitor").font(.headline)
            Label("CPU  \(Int(monitor.cpu))%", systemImage: "cpu")
            Label("RAM  \(monitor.memoryUsed.gb) / \(monitor.memoryTotal.gb) GB", systemImage: "memorychip")
            Label("Temperature  \((monitor.temperature ?? monitor.batteryTemperature).map { "\(Int($0))°C" } ?? "Unavailable")", systemImage: "thermometer.medium")
            Label("Thermal pressure  \(monitor.thermal)", systemImage: "waveform.path.ecg")
            Label(monitor.findings.isEmpty ? "No known indicators" : "Review process findings", systemImage: monitor.findings.isEmpty ? "checkmark.circle" : "exclamationmark.triangle")
        }
        .font(.callout).padding(16).frame(width: 300, alignment: .leading)
    }
}
