import AppKit
import Foundation
import Security

// MARK: - Custom Menu Item Views

private let kMenuWidth: CGFloat = 270
private let kMenuPadding: CGFloat = 17

private func colorForUsage(_ pct: Double) -> NSColor {
    if pct > 90 { return .systemRed }
    if pct > 70 { return .systemOrange }
    return .labelColor
}

/// Simple progress bar drawn via drawRect to avoid layer timing issues
final class ProgressBarView: NSView {
    private let progress: CGFloat
    private let fillColor: NSColor

    init(progress: CGFloat, fillColor: NSColor) {
        self.progress = progress
        self.fillColor = fillColor
        super.init(frame: .zero)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.labelColor.withAlphaComponent(0.12).setFill()
        NSBezierPath(roundedRect: bounds, xRadius: 1.5, yRadius: 1.5).fill()
        if progress > 0 {
            let fillRect = NSRect(x: 0, y: 0, width: bounds.width * min(progress, 1.0), height: bounds.height)
            fillColor.withAlphaComponent(0.8).setFill()
            NSBezierPath(roundedRect: fillRect, xRadius: 1.5, yRadius: 1.5).fill()
        }
    }
}

/// Top header row: bold title
final class MenuHeaderItemView: NSView {
    init(title: String) {
        super.init(frame: NSRect(x: 0, y: 0, width: kMenuWidth, height: 50))
        let tl = NSTextField(labelWithString: title)
        tl.font = .boldSystemFont(ofSize: 14)
        tl.textColor = .labelColor
        tl.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tl)
        NSLayoutConstraint.activate([
            tl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: kMenuPadding),
            tl.centerYAnchor.constraint(equalTo: centerYAnchor),
            tl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -kMenuPadding),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
}

/// Secondary gray text row
final class MenuSubtitleItemView: NSView {
    init(_ text: String) {
        let lbl = NSTextField(labelWithString: text)
        lbl.font = .systemFont(ofSize: 13)
        lbl.textColor = .labelColor.withAlphaComponent(0.75)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        super.init(frame: NSRect(x: 0, y: 0, width: kMenuWidth, height: 18))
        addSubview(lbl)
        NSLayoutConstraint.activate([
            lbl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: kMenuPadding),
            lbl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -kMenuPadding),
            lbl.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
}

/// Rate limit row: label + % right-aligned, then progress bar, then small detail text
final class MenuRateLimitItemView: NSView {
    init(label: String, pct: Double, detail: String) {
        super.init(frame: NSRect(x: 0, y: 0, width: kMenuWidth, height: 54))

        let labelField = NSTextField(labelWithString: label)
        labelField.font = .systemFont(ofSize: 13)
        labelField.textColor = .labelColor

        let pctField = NSTextField(labelWithString: String(format: "%.0f%%", pct))
        pctField.font = .monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        pctField.textColor = .labelColor
        pctField.alignment = .right

        let fillColor = colorForUsage(pct)
        let bar = ProgressBarView(progress: CGFloat(pct / 100.0), fillColor: fillColor)

        let detailField = NSTextField(labelWithString: detail)
        detailField.font = .systemFont(ofSize: 11)
        detailField.textColor = .secondaryLabelColor

        for v in [labelField, pctField, bar, detailField] {
            v.translatesAutoresizingMaskIntoConstraints = false
            addSubview(v)
        }

        NSLayoutConstraint.activate([
            labelField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: kMenuPadding),
            labelField.topAnchor.constraint(equalTo: topAnchor, constant: 7),
            pctField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -kMenuPadding),
            pctField.topAnchor.constraint(equalTo: topAnchor, constant: 7),
            pctField.leadingAnchor.constraint(greaterThanOrEqualTo: labelField.trailingAnchor, constant: 8),

            bar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: kMenuPadding),
            bar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -kMenuPadding),
            bar.topAnchor.constraint(equalTo: labelField.bottomAnchor, constant: 5),
            bar.heightAnchor.constraint(equalToConstant: 3),

            detailField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: kMenuPadding),
            detailField.topAnchor.constraint(equalTo: bar.bottomAnchor, constant: 3),
            detailField.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Cache Data Models

struct RateLimitWindow: Codable {
    let usedPercentage: Double
    let resetsAt: TimeInterval

    enum CodingKeys: String, CodingKey {
        case usedPercentage = "used_percentage"
        case resetsAt = "resets_at"
    }
}

struct RateLimits: Codable {
    let fiveHour: RateLimitWindow?
    let sevenDay: RateLimitWindow?

    enum CodingKeys: String, CodingKey {
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
    }
}

struct CachedStatus: Codable {
    let rateLimits: RateLimits?
    let model: ModelInfo?
    let contextWindow: ContextWindow?
    let cost: CostInfo?
    let updatedAt: TimeInterval?

    enum CodingKeys: String, CodingKey {
        case rateLimits = "rate_limits"
        case model
        case contextWindow = "context_window"
        case cost
        case updatedAt = "updated_at"
    }

    struct ModelInfo: Codable {
        let displayName: String?
        enum CodingKeys: String, CodingKey { case displayName = "display_name" }
    }
    struct ContextWindow: Codable {
        let usedPercentage: Double?
        enum CodingKeys: String, CodingKey { case usedPercentage = "used_percentage" }
    }
    struct CostInfo: Codable {
        let totalCostUsd: Double?
        enum CodingKeys: String, CodingKey { case totalCostUsd = "total_cost_usd" }
    }
}

// MARK: - Cache

final class StatusCache {
    private let url = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".claude/rate_limits_cache.json")

    func load() -> CachedStatus? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(CachedStatus.self, from: data)
    }
}

// MARK: - Keychain

final class KeychainReader {
    struct Credentials: Decodable {
        let claudeAiOauth: OAuthToken
        struct OAuthToken: Decodable {
            let accessToken: String
            let subscriptionType: String?
        }
    }

    static func load() -> Credentials? {
        var item: CFTypeRef?
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: "Claude Code-credentials",
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne,
        ]
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return try? JSONDecoder().decode(Credentials.self, from: data)
    }
}

// MARK: - Unified Usage Model

struct UsageWindow {
    let usedPercentage: Double
    let resetsAt: Date
}

struct UsageData {
    let fiveHour: UsageWindow?
    let sevenDay: UsageWindow?
    let sevenDaySonnet: UsageWindow?
    let fetchedAt: Date
}

extension CachedStatus {
    func toUsageData() -> UsageData? {
        guard let rl = rateLimits,
              (rl.fiveHour != nil || rl.sevenDay != nil) else { return nil }
        return UsageData(
            fiveHour: rl.fiveHour.map { UsageWindow(usedPercentage: $0.usedPercentage, resetsAt: Date(timeIntervalSince1970: $0.resetsAt)) },
            sevenDay: rl.sevenDay.map { UsageWindow(usedPercentage: $0.usedPercentage, resetsAt: Date(timeIntervalSince1970: $0.resetsAt)) },
            sevenDaySonnet: nil,
            fetchedAt: updatedAt.map { Date(timeIntervalSince1970: $0) } ?? Date()
        )
    }
}

final class OAuthUsageFetcher {
    private struct Response: Decodable {
        let fiveHour: Window?
        let sevenDay: Window?
        let sevenDaySonnet: Window?
        struct Window: Decodable {
            let utilization: Double
            let resetsAt: String
            enum CodingKeys: String, CodingKey {
                case utilization
                case resetsAt = "resets_at"
            }
        }
        enum CodingKeys: String, CodingKey {
            case fiveHour = "five_hour"
            case sevenDay = "seven_day"
            case sevenDaySonnet = "seven_day_sonnet"
        }
    }

    private let dateFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    func fetch(accessToken: String, completion: @escaping (UsageData?) -> Void) {
        var request = URLRequest(url: URL(string: "https://api.anthropic.com/api/oauth/usage")!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            guard let self, let data,
                  let resp = try? JSONDecoder().decode(Response.self, from: data) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            func parse(_ w: Response.Window?) -> UsageWindow? {
                guard let w else { return nil }
                let date = self.dateFormatter.date(from: w.resetsAt) ?? Date()
                return UsageWindow(usedPercentage: w.utilization, resetsAt: date)
            }
            let usage = UsageData(
                fiveHour: parse(resp.fiveHour),
                sevenDay: parse(resp.sevenDay),
                sevenDaySonnet: parse(resp.sevenDaySonnet),
                fetchedAt: Date()
            )
            DispatchQueue.main.async { completion(usage) }
        }.resume()
    }
}

// MARK: - Launch Agent Manager

final class LaunchAgentManager {
    private let plistURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/LaunchAgents/com.usagebar.plist")

    var isEnabled: Bool {
        FileManager.default.fileExists(atPath: plistURL.path)
    }

    func enable(binaryPath: String) {
        let logPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/usagebar.log").path
        let plist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>com.usagebar</string>
            <key>ProgramArguments</key>
            <array>
                <string>\(binaryPath)</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>StandardErrorPath</key>
            <string>\(logPath)</string>
        </dict>
        </plist>
        """
        try? plist.write(to: plistURL, atomically: true, encoding: .utf8)
        launchctl("load", plistURL.path)
    }

    func disable() {
        launchctl("unload", plistURL.path)
        try? FileManager.default.removeItem(at: plistURL)
    }

    private func launchctl(_ args: String...) {
        let p = Process()
        p.launchPath = "/bin/launchctl"
        p.arguments = args
        try? p.run()
        p.waitUntilExit()
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var timer: Timer?

    private let cache = StatusCache()
    private let launchAgent = LaunchAgentManager()
    private let oauthFetcher = OAuthUsageFetcher()
    private var credentials: KeychainReader.Credentials?
    private var oauthUsage: UsageData?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "◆"
        if !launchAgent.isEnabled {
            launchAgent.enable(binaryPath: ProcessInfo.processInfo.arguments[0])
        }
        credentials = KeychainReader.load()
        refreshUI()
        // OAuth every 5 min, cache fallback reads happen inside refreshUI
        timer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.refreshUI()
        }
    }
}

// MARK: - Status Bar

extension AppDelegate {
    @objc func refreshUI() {
        credentials = KeychainReader.load()

        // Show last known data immediately
        applyUsage(oauthUsage)

        // Fetch fresh OAuth data in background, fall back to cache if unavailable
        guard let token = credentials?.claudeAiOauth.accessToken else {
            oauthUsage = nil
            applyUsage(nil)
            return
        }
        oauthFetcher.fetch(accessToken: token) { [weak self] usage in
            guard let self else { return }
            self.oauthUsage = usage
            self.applyUsage(usage)
        }
    }

    private func applyUsage(_ usage: UsageData?) {
        let effective = usage ?? cache.load()?.toUsageData()
        updateTitle(fhPct: effective?.fiveHour?.usedPercentage,
                    sdPct: effective?.sevenDay?.usedPercentage)
        statusItem.menu = makeMenu(usage: effective, cachedStatus: usage == nil ? cache.load() : nil)
    }

    func updateTitle(fhPct: Double?, sdPct: Double?) {
        guard fhPct != nil || sdPct != nil else {
            statusItem.button?.image = nil
            statusItem.button?.title = "◆"
            statusItem.button?.contentTintColor = nil
            return
        }
        let maxPct = [fhPct, sdPct].compactMap { $0 }.max() ?? 0
        statusItem.button?.contentTintColor = maxPct > 70 ? colorForUsage(maxPct) : nil
        statusItem.button?.title = ""
        statusItem.button?.image = makeStatusImage(fhPct: fhPct, sdPct: sdPct)
        statusItem.button?.imagePosition = .imageOnly
    }

    func makeStatusImage(fhPct: Double?, sdPct: Double?) -> NSImage {
        let barW: CGFloat = 4
        let barH: CGFloat = 13
        let gap: CGFloat = 5
        let imgH: CGFloat = NSStatusBar.system.thickness

        let count: CGFloat = (fhPct != nil && sdPct != nil) ? 2 : 1
        let totalW = count * barW + (count - 1) * gap

        let image = NSImage(size: CGSize(width: totalW, height: imgH), flipped: false) { _ in
            let barY = (imgH - barH) / 2

            func drawBar(at x: CGFloat, pct: Double?) {
                let trackRect = CGRect(x: x, y: barY, width: barW, height: barH)
                NSColor.labelColor.withAlphaComponent(0.15).setFill()
                NSBezierPath(roundedRect: trackRect, xRadius: 1.5, yRadius: 1.5).fill()

                if let pct, pct > 0 {
                    let fillH = barH * CGFloat(min(pct, 100) / 100.0)
                    let fillRect = CGRect(x: x, y: barY, width: barW, height: fillH)
                    NSGraphicsContext.saveGraphicsState()
                    NSBezierPath(roundedRect: trackRect, xRadius: 1.5, yRadius: 1.5).setClip()
                    NSColor.labelColor.withAlphaComponent(0.85).setFill()
                    NSBezierPath(rect: fillRect).fill()
                    NSGraphicsContext.restoreGraphicsState()
                }
            }

            var x: CGFloat = 0
            if fhPct != nil { drawBar(at: x, pct: fhPct); x += barW + gap }
            if sdPct != nil  { drawBar(at: x, pct: sdPct) }

            return true
        }

        image.isTemplate = true
        return image
    }
}

// MARK: - Menu

extension AppDelegate {
    func makeMenu(usage: UsageData?, cachedStatus: CachedStatus?) -> NSMenu {
        let menu = NSMenu()
        menu.addItem(viewItem(MenuHeaderItemView(title: planName())))

        if let usage {
            addWindowRows(to: menu, usage: usage)
            addStaleItem(to: menu, updatedAt: usage.fetchedAt)

            // Show session metadata from cache when OAuth doesn't provide it
            if let status = cachedStatus {
                addSessionInfo(to: menu, status: status)
            }
        } else if let status = cachedStatus {
            menu.addItem(viewItem(MenuSubtitleItemView("No rate limit data yet")))
            addSessionInfo(to: menu, status: status)
            if let updatedAt = status.updatedAt {
                addStaleItem(to: menu, updatedAt: Date(timeIntervalSince1970: updatedAt))
            }
        } else {
            menu.addItem(viewItem(MenuSubtitleItemView("No data yet — run Claude Code first")))
        }

        menu.addItem(.separator())
        let refresh = NSMenuItem(title: "Refresh", action: #selector(refreshUI), keyEquivalent: "r")
        refresh.target = self
        menu.addItem(refresh)
        let quit = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        menu.addItem(.separator())
        let launchItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchItem.target = self
        launchItem.state = launchAgent.isEnabled ? .on : .off
        menu.addItem(launchItem)

        return menu
    }

    private func addWindowRows(to menu: NSMenu, usage: UsageData) {
        if let w = usage.fiveHour {
            menu.addItem(viewItem(MenuRateLimitItemView(
                label: "5-Hour Window", pct: w.usedPercentage,
                detail: "resets \(timeUntil(w.resetsAt))"
            )))
        }
        if let w = usage.sevenDay {
            var detail = "resets \(timeUntil(w.resetsAt))"
            if let sp = usage.sevenDaySonnet?.usedPercentage, abs(sp - w.usedPercentage) >= 1 {
                detail += " · Sonnet \(Int(sp))%"
            }
            menu.addItem(viewItem(MenuRateLimitItemView(label: "7-Day Window", pct: w.usedPercentage, detail: detail)))
        }
    }

    private func addSessionInfo(to menu: NSMenu, status: CachedStatus) {
        guard let model = status.model?.displayName,
              let ctxPct = status.contextWindow?.usedPercentage else { return }
        menu.addItem(.separator())
        menu.addItem(viewItem(MenuSubtitleItemView("Last Session")))
        menu.addItem(viewItem(MenuSubtitleItemView(model)))
        if let cost = status.cost?.totalCostUsd {
            menu.addItem(viewItem(MenuSubtitleItemView(String(format: "Context %.0f%%  ·  $%.4f", ctxPct, cost))))
        } else {
            menu.addItem(viewItem(MenuSubtitleItemView(String(format: "Context %.0f%%", ctxPct))))
        }
    }

    private func addStaleItem(to menu: NSMenu, updatedAt: Date) {
        guard Date().timeIntervalSince(updatedAt) > 300 else { return }
        let fmt = RelativeDateTimeFormatter()
        fmt.unitsStyle = .full
        menu.addItem(.separator())
        menu.addItem(viewItem(MenuSubtitleItemView("Updated \(fmt.localizedString(for: updatedAt, relativeTo: Date()))")))
    }

    private func planName() -> String {
        guard let sub = credentials?.claudeAiOauth.subscriptionType else { return "Claude Usage" }
        switch sub {
        case "pro": return "Claude Pro"
        case "max": return "Claude Max"
        case "team": return "Claude Team"
        case "enterprise": return "Claude Enterprise"
        default: return "Claude \(sub.capitalized)"
        }
    }

    private func viewItem(_ view: NSView) -> NSMenuItem {
        let item = NSMenuItem()
        item.view = view
        item.isEnabled = false
        return item
    }

    func timeUntil(_ date: Date) -> String {
        let interval = date.timeIntervalSinceNow
        if interval <= 0 { return "now" }
        let days    = Int(interval) / 86400
        let hours   = (Int(interval) % 86400) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if days  > 0 { return "in \(days)d \(hours)h" }
        if hours > 0 { return "in \(hours)h \(minutes)m" }
        return "in \(minutes)m"
    }
}

// MARK: - Launch at Login

extension AppDelegate {
    @objc func toggleLaunchAtLogin() {
        if launchAgent.isEnabled {
            launchAgent.disable()
        } else {
            launchAgent.enable(binaryPath: ProcessInfo.processInfo.arguments[0])
        }
        refreshUI()
    }

    @objc func quitApp() { NSApp.terminate(nil) }
}

// MARK: - Entry Point

let runningInstances = NSRunningApplication.runningApplications(withBundleIdentifier: "com.usagebar")
if runningInstances.count > 1 {
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
