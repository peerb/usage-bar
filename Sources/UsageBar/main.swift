import AppKit
import Foundation

// MARK: - Custom Menu Item Views

private let kMenuWidth: CGFloat = 270

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
            tl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            tl.centerYAnchor.constraint(equalTo: centerYAnchor),
            tl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
}

/// Secondary gray text row (like "Power Source: Power Adapter")
final class MenuSubtitleItemView: NSView {
    init(_ text: String) {
        let lbl = NSTextField(labelWithString: text)
        lbl.font = .systemFont(ofSize: 13)
        lbl.textColor = .labelColor.withAlphaComponent(0.75)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        super.init(frame: NSRect(x: 0, y: 0, width: kMenuWidth, height: 18))
        addSubview(lbl)
        NSLayoutConstraint.activate([
            lbl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            lbl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
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

        let pctField = NSTextField(labelWithString: String(format: "%.0f %%", pct))
        pctField.font = .monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        pctField.textColor = .labelColor
        pctField.alignment = .right

        let fillColor: NSColor = pct > 90 ? .systemRed : pct > 70 ? .systemOrange : .labelColor
        let bar = ProgressBarView(progress: CGFloat(pct / 100.0), fillColor: fillColor)

        let detailField = NSTextField(labelWithString: detail)
        detailField.font = .systemFont(ofSize: 11)
        detailField.textColor = .secondaryLabelColor

        for v in [labelField, pctField, bar, detailField] {
            v.translatesAutoresizingMaskIntoConstraints = false
            addSubview(v)
        }

        NSLayoutConstraint.activate([
            // Top row: label left, pct right
            labelField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            labelField.topAnchor.constraint(equalTo: topAnchor, constant: 7),
            pctField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            pctField.topAnchor.constraint(equalTo: topAnchor, constant: 7),
            pctField.leadingAnchor.constraint(greaterThanOrEqualTo: labelField.trailingAnchor, constant: 8),

            // Progress bar below label row
            bar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            bar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            bar.topAnchor.constraint(equalTo: labelField.bottomAnchor, constant: 5),
            bar.heightAnchor.constraint(equalToConstant: 3),

            // Detail text below bar
            detailField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            detailField.topAnchor.constraint(equalTo: bar.bottomAnchor, constant: 3),
            detailField.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Data Models

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

        enum CodingKeys: String, CodingKey {
            case displayName = "display_name"
        }
    }

    struct ContextWindow: Codable {
        let usedPercentage: Double?

        enum CodingKeys: String, CodingKey {
            case usedPercentage = "used_percentage"
        }
    }

    struct CostInfo: Codable {
        let totalCostUsd: Double?

        enum CodingKeys: String, CodingKey {
            case totalCostUsd = "total_cost_usd"
        }
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

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "◆"
        if !launchAgent.isEnabled {
            launchAgent.enable(binaryPath: ProcessInfo.processInfo.arguments[0])
        }
        refreshUI()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.refreshUI()
        }
    }
}

// MARK: - Status Bar

extension AppDelegate {
    @objc func refreshUI() {
        let status = cache.load()
        updateTitle(from: status)
        statusItem.menu = makeMenu(status: status)
    }

    func updateTitle(from status: CachedStatus?) {
        let fhPct = status?.rateLimits?.fiveHour?.usedPercentage
        let sdPct = status?.rateLimits?.sevenDay?.usedPercentage

        guard fhPct != nil || sdPct != nil else {
            statusItem.button?.image = nil
            statusItem.button?.title = "◆"
            return
        }

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
    func makeMenu(status: CachedStatus?) -> NSMenu {
        let menu = NSMenu()

        if let status {
            if let rl = status.rateLimits {
                menu.addItem(viewItem(MenuHeaderItemView(title: "Claude Usage")))

                if let fh = rl.fiveHour {
                    let detail = "5h window · resets \(timeUntil(Date(timeIntervalSince1970: fh.resetsAt)))"
                    menu.addItem(viewItem(MenuRateLimitItemView(label: "5-Hour Window", pct: fh.usedPercentage, detail: detail)))
                }
                if let sd = rl.sevenDay {
                    let detail = "7d window · resets \(timeUntil(Date(timeIntervalSince1970: sd.resetsAt)))"
                    menu.addItem(viewItem(MenuRateLimitItemView(label: "7-Day Window", pct: sd.usedPercentage, detail: detail)))
                }
                menu.addItem(.separator())
            } else {
                menu.addItem(viewItem(MenuHeaderItemView(title: "Claude Usage")))
                menu.addItem(viewItem(MenuSubtitleItemView("No rate limit data yet")))
                menu.addItem(.separator())
            }

            if let model = status.model?.displayName,
               let ctxPct = status.contextWindow?.usedPercentage {
                menu.addItem(sectionHeader("Last Session"))
                menu.addItem(viewItem(MenuSubtitleItemView(model)))
                if let cost = status.cost?.totalCostUsd {
                    menu.addItem(viewItem(MenuSubtitleItemView(String(format: "Context %.0f%%  ·  $%.4f", ctxPct, cost))))
                } else {
                    menu.addItem(viewItem(MenuSubtitleItemView(String(format: "Context %.0f%%", ctxPct))))
                }
                menu.addItem(.separator())
            }

            if let updatedAt = status.updatedAt {
                let fmt = RelativeDateTimeFormatter()
                fmt.unitsStyle = .full
                let timeStr = fmt.localizedString(for: Date(timeIntervalSince1970: updatedAt), relativeTo: Date())
                menu.addItem(viewItem(MenuSubtitleItemView("Updated \(timeStr)")))
                menu.addItem(.separator())
            }
        } else {
            menu.addItem(viewItem(MenuHeaderItemView(title: "Claude Usage")))
            menu.addItem(viewItem(MenuSubtitleItemView("No data yet — run Claude Code first")))
            menu.addItem(.separator())
        }

        let launchItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchItem.target = self
        launchItem.state = launchAgent.isEnabled ? .on : .off
        menu.addItem(launchItem)
        menu.addItem(.separator())

        let refresh = NSMenuItem(title: "Refresh", action: #selector(refreshUI), keyEquivalent: "r")
        refresh.target = self
        menu.addItem(refresh)
        let quit = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        return menu
    }

    private func viewItem(_ view: NSView) -> NSMenuItem {
        let item = NSMenuItem()
        item.view = view
        item.isEnabled = false
        return item
    }

    private func sectionHeader(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        item.isEnabled = false
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: NSFont.smallSystemFontSize + 1),
            .foregroundColor: NSColor.labelColor,
        ]
        item.attributedTitle = NSAttributedString(string: title, attributes: attrs)
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

// Prevent multiple instances
let runningInstances = NSRunningApplication.runningApplications(withBundleIdentifier: "com.usagebar")
if runningInstances.count > 1 {
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
