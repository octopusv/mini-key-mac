import SwiftUI
import Foundation

// ───────────────────────────────────────────────────────────────────────────
// mini-key 設定 — 0x514c:8851 (3キー + ノブ) 用 GUI
// 既存の CLI (ch57x-keyboard-tool) を内部で呼び出し、本体フラッシュに書き込む。
// ───────────────────────────────────────────────────────────────────────────

enum Paths {
    /// CLI の場所: ①アプリに同梱したもの → ②環境変数 MINIKEY_TOOL → ③リポジトリ内ビルド
    static var tool: String {
        if let p = Bundle.main.url(forResource: "ch57x-keyboard-tool", withExtension: nil)?.path {
            return p
        }
        if let env = ProcessInfo.processInfo.environment["MINIKEY_TOOL"], !env.isEmpty {
            return env
        }
        return Bundle.main.bundleURL
            .deletingLastPathComponent()   // build/
            .deletingLastPathComponent()   // gui/
            .deletingLastPathComponent()   // <repo>/
            .appendingPathComponent("ch57x-keyboard-tool/target/release/ch57x-keyboard-tool")
            .path
    }

    /// 設定・プロファイルの保存先（ユーザーごと）: ~/Library/Application Support/mini-key/
    static var supportDir: String {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("mini-key", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.path
    }
    static var config: String { supportDir + "/keypad.yaml" }
    static var profilesFile: String { supportDir + "/profiles.json" }
}

let kCustom = "__custom__"
let kNone   = "__none__"

struct Opt: Identifiable, Hashable {
    let id: String       // = token（通常）/ kNone / kCustom
    let title: String
    init(_ id: String, _ title: String) { self.id = id; self.title = title }
}

struct OptGroup: Identifiable {
    var id: String { title }
    let title: String
    let opts: [Opt]
}

let otherGroup = OptGroup(title: "その他", opts: [
    Opt(kNone, "なし"),
    Opt(kCustom, "カスタム…"),
])

// キー（キーボード操作）の候補テンプレート
let buttonGroups: [OptGroup] = [
    OptGroup(title: "編集", opts: [
        Opt("cmd-c", "コピー  ⌘C"),
        Opt("cmd-x", "切り取り  ⌘X"),
        Opt("cmd-v", "ペースト  ⌘V"),
        Opt("cmd-shift-alt-v", "プレーンテキストで貼付  ⌥⇧⌘V"),
        Opt("cmd-z", "取り消し  ⌘Z"),
        Opt("cmd-shift-z", "やり直し  ⇧⌘Z"),
        Opt("cmd-a", "全選択  ⌘A"),
        Opt("cmd-d", "複製  ⌘D"),
        Opt("cmd-f", "検索  ⌘F"),
        Opt("cmd-g", "次を検索  ⌘G"),
        Opt("cmd-s", "保存  ⌘S"),
        Opt("cmd-p", "印刷  ⌘P"),
    ]),
    OptGroup(title: "ファイル・ウィンドウ", opts: [
        Opt("cmd-n", "新規  ⌘N"),
        Opt("cmd-t", "新規タブ  ⌘T"),
        Opt("cmd-o", "開く  ⌘O"),
        Opt("cmd-w", "閉じる  ⌘W"),
        Opt("cmd-shift-t", "閉じたタブを復元  ⇧⌘T"),
        Opt("cmd-m", "最小化  ⌘M"),
        Opt("cmd-h", "隠す  ⌘H"),
        Opt("cmd-q", "アプリを終了  ⌘Q"),
    ]),
    OptGroup(title: "システム・操作", opts: [
        Opt("cmd-tab", "アプリ切替  ⌘Tab"),
        Opt("cmd-space", "Spotlight  ⌘Space"),
        Opt("ctrl-up", "Mission Control  ⌃↑"),
        Opt("ctrl-down", "アプリウィンドウ  ⌃↓"),
        Opt("ctrl-left", "左のデスクトップ  ⌃←"),
        Opt("ctrl-right", "右のデスクトップ  ⌃→"),
        Opt("ctrl-cmd-q", "画面をロック  ⌃⌘Q"),
        Opt("cmd-alt-escape", "強制終了  ⌥⌘Esc"),
    ]),
    OptGroup(title: "スクリーンショット", opts: [
        Opt("cmd-shift-3", "全画面を撮影  ⇧⌘3"),
        Opt("cmd-shift-4", "範囲を撮影  ⇧⌘4"),
        Opt("cmd-shift-5", "撮影ツール  ⇧⌘5"),
    ]),
    OptGroup(title: "ブラウザ", opts: [
        Opt("cmd-leftbracket", "戻る  ⌘["),
        Opt("cmd-rightbracket", "進む  ⌘]"),
        Opt("cmd-r", "再読み込み  ⌘R"),
        Opt("cmd-l", "アドレスバー  ⌘L"),
        Opt("ctrl-tab", "次のタブ  ⌃Tab"),
        Opt("ctrl-shift-tab", "前のタブ  ⌃⇧Tab"),
    ]),
    OptGroup(title: "キー", opts: [
        Opt("enter", "Enter  ↩"),
        Opt("escape", "Esc"),
        Opt("tab", "Tab  ⇥"),
        Opt("space", "Space  ␣"),
        Opt("backspace", "Delete  ⌫"),
        Opt("delete", "前方削除  ⌦"),
        Opt("up", "↑"),
        Opt("down", "↓"),
        Opt("left", "←"),
        Opt("right", "→"),
        Opt("cmd-left", "行頭  ⌘←"),
        Opt("cmd-right", "行末  ⌘→"),
    ]),
    OptGroup(title: "アプリ", opts: [
        Opt("ctrl-alt-cmd-a", "Aqua Voice  ⌃⌥⌘A"),
    ]),
    otherGroup,
]

// ノブ（回転・押し込み）の候補テンプレート
let knobGroups: [OptGroup] = [
    OptGroup(title: "音量", opts: [
        Opt("volumedown", "音量ダウン"),
        Opt("volumeup", "音量アップ"),
        Opt("mute", "ミュート"),
    ]),
    OptGroup(title: "メディア", opts: [
        Opt("play", "再生 / 一時停止"),
        Opt("next", "次の曲"),
        Opt("prev", "前の曲"),
        Opt("stop", "停止"),
    ]),
    OptGroup(title: "表示・編集", opts: [
        Opt("cmd-equal", "拡大  ⌘+"),
        Opt("cmd-minus", "縮小  ⌘−"),
        Opt("cmd-z", "取り消し  ⌘Z"),
        Opt("cmd-shift-z", "やり直し  ⌘⇧Z"),
    ]),
    OptGroup(title: "移動", opts: [
        Opt("up", "↑"),
        Opt("down", "↓"),
        Opt("left", "←"),
        Opt("right", "→"),
        Opt("ctrl-tab", "次のタブ  ⌃Tab"),
        Opt("ctrl-shift-tab", "前のタブ  ⌃⇧Tab"),
        Opt("cmd-leftbracket", "戻る  ⌘["),
        Opt("cmd-rightbracket", "進む  ⌘]"),
    ]),
    otherGroup,
]

func resolveToken(_ id: String, custom: String) -> String? {
    if id == kNone { return nil }
    if id == kCustom {
        let t = custom.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
    return id   // 通常テンプレートは id がそのまま token
}

// ── 起動時に現在の設定(keypad.yaml)を読み込んでデフォルトにする ──────────────

let buttonIDSet: Set<String> = Set(buttonGroups.flatMap { $0.opts.map { $0.id } })
let knobIDSet: Set<String> = Set(knobGroups.flatMap { $0.opts.map { $0.id } })

struct LoadedDefaults {
    var k1 = "cmd-c", k2 = "cmd-v", k3 = "cmd-z"
    var ccw = "volumedown", prs = "mute", cw = "volumeup"
    var k1c = "", k2c = "", k3c = ""
    var ccwc = "", prsc = "", cwc = ""
}

private func cleanYamlValue(_ s: String) -> String? {
    var v = s.trimmingCharacters(in: .whitespaces)
    if v.count >= 2, v.hasPrefix("\""), v.hasSuffix("\"") {
        v = String(v.dropFirst().dropLast())
    }
    v = v.trimmingCharacters(in: .whitespaces)
    return (v.isEmpty || v == "null") ? nil : v
}

private func parseKeypadConfig() -> (buttons: [String?], ccw: String?, press: String?, cw: String?)? {
    guard let text = try? String(contentsOfFile: Paths.config, encoding: .utf8) else { return nil }
    var buttons: [String?] = []
    var ccw: String?, press: String?, cw: String?
    var foundButtons = false
    for raw in text.components(separatedBy: .newlines) {
        var t = raw.trimmingCharacters(in: .whitespaces)
        if t.hasPrefix("- ") { t = String(t.dropFirst(2)).trimmingCharacters(in: .whitespaces) }
        if t.hasPrefix("["), t.hasSuffix("]") {
            let inner = String(t.dropFirst().dropLast())
            buttons = inner.components(separatedBy: ",").map { cleanYamlValue($0) }
            foundButtons = true
        } else if t.hasPrefix("ccw:") {
            ccw = cleanYamlValue(String(t.dropFirst(4)))
        } else if t.hasPrefix("press:") {
            press = cleanYamlValue(String(t.dropFirst(6)))
        } else if t.hasPrefix("cw:") {
            cw = cleanYamlValue(String(t.dropFirst(3)))
        }
    }
    return foundButtons ? (buttons, ccw, press, cw) : nil
}

private func mapToken(_ token: String?, ids: Set<String>) -> (id: String, custom: String) {
    guard let tok = token, !tok.isEmpty else { return (kNone, "") }
    return ids.contains(tok) ? (tok, "") : (kCustom, tok)
}

func loadDefaults() -> LoadedDefaults {
    var d = LoadedDefaults()
    guard let cfg = parseKeypadConfig() else { return d }
    let b = cfg.buttons
    func btn(_ i: Int) -> (String, String) { mapToken(i < b.count ? b[i] : nil, ids: buttonIDSet) }
    (d.k1, d.k1c) = btn(0)
    (d.k2, d.k2c) = btn(1)
    (d.k3, d.k3c) = btn(2)
    (d.ccw, d.ccwc) = mapToken(cfg.ccw, ids: knobIDSet)
    (d.prs, d.prsc) = mapToken(cfg.press, ids: knobIDSet)
    (d.cw, d.cwc) = mapToken(cfg.cw, ids: knobIDSet)
    return d
}

// ── プロファイル（割り当てセット）の保存／読み込み ────────────────────────────

struct Profile: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var k1 = "cmd-c", k2 = "cmd-v", k3 = "cmd-z"
    var ccw = "volumedown", prs = "mute", cw = "volumeup"
    var k1c = "", k2c = "", k3c = ""
    var ccwc = "", prsc = "", cwc = ""
}

struct ProfileStore: Codable {
    var profiles: [Profile] = []
    var selectedID: UUID?
}

func loadStore() -> ProfileStore? {
    guard let data = try? Data(contentsOf: URL(fileURLWithPath: Paths.profilesFile)) else { return nil }
    return try? JSONDecoder().decode(ProfileStore.self, from: data)
}

func saveStore(_ s: ProfileStore) {
    let enc = JSONEncoder()
    enc.outputFormatting = [.prettyPrinted, .sortedKeys]
    if let data = try? enc.encode(s) {
        try? data.write(to: URL(fileURLWithPath: Paths.profilesFile))
    }
}

// 初回起動時の初期プロファイル（現在の設定＋よく使う例）
func seedProfiles() -> [Profile] {
    let d = loadDefaults()
    let current = Profile(name: "現在の設定",
        k1: d.k1, k2: d.k2, k3: d.k3, ccw: d.ccw, prs: d.prs, cw: d.cw,
        k1c: d.k1c, k2c: d.k2c, k3c: d.k3c, ccwc: d.ccwc, prsc: d.prsc, cwc: d.cwc)
    let copyPaste = Profile(name: "コピペ",
        k1: "cmd-c", k2: "cmd-v", k3: "cmd-z",
        ccw: "volumedown", prs: "mute", cw: "volumeup")
    let browser = Profile(name: "ブラウザ",
        k1: "cmd-leftbracket", k2: "cmd-rightbracket", k3: "cmd-r",
        ccw: "ctrl-shift-tab", prs: "cmd-r", cw: "ctrl-tab")
    return [current, copyPaste, browser]
}

func yamlValue(_ token: String?) -> String {
    guard let t = token, !t.isEmpty else { return "null" }
    return "\"\(t)\""
}

// プロセス実行（非管理者）
func runProcess(_ launch: String, _ args: [String]) -> (code: Int32, out: String, err: String) {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: launch)
    p.arguments = args
    let o = Pipe(); let e = Pipe()
    p.standardOutput = o; p.standardError = e
    do { try p.run() } catch { return (-1, "", error.localizedDescription) }
    let outData = o.fileHandleForReading.readDataToEndOfFile()
    let errData = e.fileHandleForReading.readDataToEndOfFile()
    p.waitUntilExit()
    return (p.terminationStatus,
            String(data: outData, encoding: .utf8) ?? "",
            String(data: errData, encoding: .utf8) ?? "")
}

// 管理者権限で実行（macOS標準のパスワードダイアログが出る）
func runAdmin(shellCommand: String) -> (code: Int32, out: String, err: String) {
    let script = "do shell script \"\(shellCommand)\" with administrator privileges"
    return runProcess("/usr/bin/osascript", ["-e", script])
}

enum Phase { case idle, working, success, failure, canceled }

struct ContentView: View {
    @State private var k1 = "cmd-c"
    @State private var k2 = "cmd-v"
    @State private var k3 = "cmd-z"
    @State private var k1c = ""
    @State private var k2c = ""
    @State private var k3c = ""

    @State private var ccw  = "volumedown"
    @State private var prs  = "mute"
    @State private var cw   = "volumeup"
    @State private var ccwc = ""
    @State private var prsc = ""
    @State private var cwc = ""

    @State private var phase: Phase = .idle
    @State private var message = "割り当てを選んで「本体に書き込む」を押してください。"

    // プロファイル
    @State private var profiles: [Profile] = []
    @State private var selectedID: UUID?
    @State private var showNameDialog = false
    @State private var nameInput = ""
    @State private var nameMode: NameMode = .new
    enum NameMode { case new, rename }

    init() {
        var store = loadStore() ?? ProfileStore()
        if store.profiles.isEmpty {
            store.profiles = seedProfiles()
            store.selectedID = store.profiles.first?.id
            saveStore(store)
        }
        let sel = store.profiles.first(where: { $0.id == store.selectedID }) ?? store.profiles[0]
        _profiles = State(initialValue: store.profiles)
        _selectedID = State(initialValue: sel.id)
        _k1 = State(initialValue: sel.k1);   _k1c = State(initialValue: sel.k1c)
        _k2 = State(initialValue: sel.k2);   _k2c = State(initialValue: sel.k2c)
        _k3 = State(initialValue: sel.k3);   _k3c = State(initialValue: sel.k3c)
        _ccw = State(initialValue: sel.ccw); _ccwc = State(initialValue: sel.ccwc)
        _prs = State(initialValue: sel.prs); _prsc = State(initialValue: sel.prsc)
        _cw = State(initialValue: sel.cw);   _cwc = State(initialValue: sel.cwc)
        _message = State(initialValue: "プロファイル「\(sel.name)」を読み込みました。")
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            profileBar
            Divider()

            VStack(alignment: .leading, spacing: 18) {
                GroupBox {
                    VStack(spacing: 12) {
                        keyRow(badge: "KEY1", color: .blue,   sel: $k1, custom: $k1c)
                        Divider()
                        keyRow(badge: "KEY2", color: .indigo, sel: $k2, custom: $k2c)
                        Divider()
                        keyRow(badge: "KEY3", color: .purple, sel: $k3, custom: $k3c)
                    }
                    .padding(8)
                } label: {
                    sectionLabel("キー", systemImage: "keyboard")
                }

                GroupBox {
                    VStack(spacing: 12) {
                        knobRow(icon: "arrow.counterclockwise", title: "左に回す", sel: $ccw, custom: $ccwc)
                        Divider()
                        knobRow(icon: "circle.circle",          title: "押し込む", sel: $prs, custom: $prsc)
                        Divider()
                        knobRow(icon: "arrow.clockwise",        title: "右に回す", sel: $cw,  custom: $cwc)
                    }
                    .padding(8)
                } label: {
                    sectionLabel("ノブ（ダイヤル）", systemImage: "dial.medium")
                }

                Spacer(minLength: 0)
            }
            .padding(20)

            Divider()
            footer
        }
        .frame(width: 480, height: 700)
        .background(Color(nsColor: .windowBackgroundColor))
        .onChange(of: selectedID) { _, newID in
            if let p = profiles.first(where: { $0.id == newID }) {
                applyProfileToUI(p)
                message = "プロファイル「\(p.name)」を読み込みました。「本体に書き込む」で反映。"
            }
        }
        .alert(nameMode == .new ? "新しいプロファイル名" : "プロファイル名を変更",
               isPresented: $showNameDialog) {
            TextField("名前", text: $nameInput)
            Button("OK") {
                let n = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !n.isEmpty else { return }
                if nameMode == .new { newProfile(name: n) } else { renameProfile(n) }
            }
            Button("キャンセル", role: .cancel) {}
        }
    }

    // MARK: - Profiles

    private var profileBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "square.stack.3d.up.fill").foregroundStyle(.tint)
            Picker("", selection: $selectedID) {
                ForEach(profiles) { Text($0.name).tag(Optional($0.id)) }
            }
            .labelsHidden()
            .frame(maxWidth: 200)
            Spacer()
            Button {
                nameMode = .new
                nameInput = "プロファイル\(profiles.count + 1)"
                showNameDialog = true
            } label: { Image(systemName: "plus") }
            .help("現在の内容で新規プロファイルを作成")
            Button("保存") { saveCurrentProfile() }
                .help("選択中のプロファイルに上書き保存")
            Menu {
                Button("名前を変更…") {
                    nameMode = .rename
                    nameInput = selectedProfile?.name ?? ""
                    showNameDialog = true
                }
                Button("複製") { duplicateProfile() }
                Divider()
                Button("削除", role: .destructive) { deleteProfile() }
            } label: { Image(systemName: "ellipsis.circle") }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private var selectedProfile: Profile? { profiles.first { $0.id == selectedID } }

    private func applyProfileToUI(_ p: Profile) {
        k1 = p.k1; k2 = p.k2; k3 = p.k3; ccw = p.ccw; prs = p.prs; cw = p.cw
        k1c = p.k1c; k2c = p.k2c; k3c = p.k3c; ccwc = p.ccwc; prsc = p.prsc; cwc = p.cwc
    }

    private func currentAsProfile(name: String, id: UUID) -> Profile {
        Profile(id: id, name: name, k1: k1, k2: k2, k3: k3, ccw: ccw, prs: prs, cw: cw,
                k1c: k1c, k2c: k2c, k3c: k3c, ccwc: ccwc, prsc: prsc, cwc: cwc)
    }

    private func persist() {
        saveStore(ProfileStore(profiles: profiles, selectedID: selectedID))
    }

    private func saveCurrentProfile() {
        guard let id = selectedID, let idx = profiles.firstIndex(where: { $0.id == id }) else { return }
        let name = profiles[idx].name
        profiles[idx] = currentAsProfile(name: name, id: id)
        persist()
        message = "プロファイル「\(name)」を保存しました。"
    }

    private func newProfile(name: String) {
        let p = currentAsProfile(name: name, id: UUID())
        profiles.append(p)
        selectedID = p.id
        persist()
        message = "プロファイル「\(name)」を作成しました。"
    }

    private func renameProfile(_ name: String) {
        guard let id = selectedID, let idx = profiles.firstIndex(where: { $0.id == id }) else { return }
        profiles[idx].name = name
        persist()
        message = "名前を「\(name)」に変更しました。"
    }

    private func duplicateProfile() {
        guard let src = selectedProfile else { return }
        let p = currentAsProfile(name: src.name + " のコピー", id: UUID())
        profiles.append(p)
        selectedID = p.id
        persist()
        message = "「\(src.name)」を複製しました。"
    }

    private func deleteProfile() {
        guard let id = selectedID, let idx = profiles.firstIndex(where: { $0.id == id }) else { return }
        let removed = profiles[idx].name
        profiles.remove(at: idx)
        if profiles.isEmpty { profiles = [Profile(name: "プロファイル1")] }
        selectedID = profiles.first?.id
        if let p = selectedProfile { applyProfileToUI(p) }
        persist()
        message = "「\(removed)」を削除しました。"
    }

    private func sectionLabel(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline)
            .padding(.bottom, 6)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LinearGradient(colors: [.blue, .purple],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 52, height: 52)
                Image(systemName: "keyboard.badge.ellipsis")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("mini-key 設定").font(.title2).bold()
                Text("3キー + ノブ ・ 0x514c:8851")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(20)
    }

    // MARK: - Footer (status + apply)

    private var footer: some View {
        HStack(spacing: 12) {
            statusView
            Spacer()
            Button {
                apply()
            } label: {
                HStack(spacing: 6) {
                    if phase == .working {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "square.and.arrow.down.on.square")
                    }
                    Text(phase == .working ? "書き込み中…" : "本体に書き込む")
                }
                .frame(minWidth: 130)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(phase == .working)
            .keyboardShortcut(.defaultAction)
        }
        .padding(16)
    }

    private var statusView: some View {
        let (icon, color): (String, Color) = {
            switch phase {
            case .idle:     return ("info.circle", .secondary)
            case .working:  return ("hourglass", .secondary)
            case .success:  return ("checkmark.circle.fill", .green)
            case .failure:  return ("xmark.octagon.fill", .red)
            case .canceled: return ("hand.raised.fill", .orange)
            }
        }()
        return Label {
            Text(message).font(.callout).foregroundStyle(phase == .idle ? .secondary : .primary)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: icon).foregroundStyle(color)
        }
        .frame(maxWidth: 260, alignment: .leading)
    }

    // MARK: - Rows

    @ViewBuilder
    private func optionMenu(_ groups: [OptGroup], _ sel: Binding<String>) -> some View {
        Picker("", selection: sel) {
            ForEach(groups) { g in
                Section(g.title) {
                    ForEach(g.opts) { Text($0.title).tag($0.id) }
                }
            }
        }
        .labelsHidden()
        .frame(width: 236)
    }

    private func keyRow(badge: String, color: Color, sel: Binding<String>,
                        custom: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(badge)
                    .font(.system(.callout, design: .rounded)).bold()
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(color, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                Spacer()
                optionMenu(buttonGroups, sel)
            }
            if sel.wrappedValue == kCustom {
                TextField("例: cmd-shift-4 / ctrl-alt-t / a", text: custom)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.callout, design: .monospaced))
            }
        }
        .padding(.vertical, 2)
    }

    private func knobRow(icon: String, title: String, sel: Binding<String>,
                         custom: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(title, systemImage: icon)
                Spacer()
                optionMenu(knobGroups, sel)
            }
            if sel.wrappedValue == kCustom {
                TextField("例: volumeup / play / cmd-z", text: custom)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.callout, design: .monospaced))
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Apply

    private func buildYAML() -> String {
        let b1 = yamlValue(resolveToken(k1, custom: k1c))
        let b2 = yamlValue(resolveToken(k2, custom: k2c))
        let b3 = yamlValue(resolveToken(k3, custom: k3c))
        let kc = yamlValue(resolveToken(ccw, custom: ccwc))
        let kp = yamlValue(resolveToken(prs, custom: prsc))
        let kw = yamlValue(resolveToken(cw,  custom: cwc))
        return """
        # mini-key (3KV1 / 0x514c:8851) — GUIで生成
        model: ch57x-1
        orientation: normal
        rows: 1
        columns: 3
        knobs: 1
        layers:
          - buttons:
              - [\(b1), \(b2), \(b3)]
            knobs:
              - ccw: \(kc)
                press: \(kp)
                cw: \(kw)
        """
    }

    private func apply() {
        let yaml = buildYAML()
        phase = .working
        message = "デバイスに書き込んでいます…"
        Task {
            let result = await Task.detached(priority: .userInitiated) { () -> (Phase, String) in
                // 1) 設定ファイルを書き出す
                do {
                    try yaml.write(toFile: Paths.config, atomically: true, encoding: .utf8)
                } catch {
                    return (.failure, "設定ファイルの書き出しに失敗: \(error.localizedDescription)")
                }
                // 2) 検証（管理者不要）
                let v = runProcess(Paths.tool, ["validate", Paths.config])
                if v.code != 0 {
                    let detail = (v.err + v.out).trimmingCharacters(in: .whitespacesAndNewlines)
                    return (.failure, "設定が不正です:\n\(detail)")
                }
                // 3) 書き込み（管理者権限・パスワードダイアログ）
                let cmd = "'\(Paths.tool)' upload '\(Paths.config)'"
                let r = runAdmin(shellCommand: cmd)
                if r.code == 0 {
                    return (.success, "書き込み完了！ キーを押して確認してください。")
                }
                let err = (r.err + r.out)
                if err.contains("-128") || err.lowercased().contains("cancel") {
                    return (.canceled, "キャンセルされました。")
                }
                return (.failure, "書き込みに失敗:\n\(err.trimmingCharacters(in: .whitespacesAndNewlines))")
            }.value
            phase = result.0
            message = result.1
        }
    }
}

struct MiniKeyApp: App {
    var body: some Scene {
        Window("mini-key 設定", id: "main") {
            ContentView()
        }
        .windowResizability(.contentSize)
    }
}
