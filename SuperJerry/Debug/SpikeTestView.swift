import SwiftUI
import PhotosUI
import Vision
import FoundationModels
import AVFoundation

/// TEMPORARY test screen: "what works on this iPad?" Run it on the team iPad, share the report,
/// then pick Plan A / B / C (claude-plan section 6.3). Delete this folder before submitting.
struct SpikeTestView: View {
    @State private var results: [SpikeResult] = []
    @State private var isRunning = false
    @State private var photoItem: PhotosPickerItem?
    @State private var photoReport = "Take a photo of a printed fake envelope with the Camera app, then pick it here."
    @State private var speech = ThaiSpeaker()

    private let aiSample = SampleLabels.all[1]   // Metformin, morning + evening

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        Task { await runAll() }
                    } label: {
                        Label(isRunning ? "Running…" : "Run spike test", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isRunning)

                    if !results.isEmpty {
                        ShareLink(item: report) {
                            Label("Share report", systemImage: "square.and.arrow.up")
                        }
                    }
                }

                if !results.isEmpty {
                    Section("Results") {
                        ForEach(results) { ResultRow(result: $0) }
                    }
                }

                Section("7. Real photo test") {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label("Pick a photo of an envelope", systemImage: "photo")
                    }
                    Text(photoReport)
                        .font(.callout.monospaced())
                        .textSelection(.enabled)
                }

                Section("Thai voice") {
                    Button {
                        speech.speak("ยา Metformin กินครั้งละ 1 เม็ด ตอนเช้า และตอนเย็น หลังอาหาร")
                    } label: {
                        Label("ลองฟังเสียง (play Thai sample)", systemImage: "speaker.wave.2.fill")
                    }
                }
            }
            .navigationTitle("Spike test")
        }
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task { await readPhoto(item) }
        }
    }

    /// Everything as plain text, for the group chat.
    private var report: String {
        let device = "Device: \(UIDevice.current.model), iOS \(UIDevice.current.systemVersion), language \(Locale.current.identifier)"
        let lines = results.map { "[\($0.status.rawValue)] \($0.title)\n\($0.detail)" }
        return ([device] + lines + ["7. Photo test:\n\(photoReport)"]).joined(separator: "\n\n")
    }

    private func runAll() async {
        isRunning = true
        results = []
        results.append(deviceInfo())
        results.append(testVision())
        results.append(testOnDeviceAvailability())
        results.append(testOnDeviceThaiSupport())
        results.append(await testOnDeviceUnderstanding())
        results.append(await testThaiVoice())
        results.append(testRules())
        results.append(await privateCloudComputeResult())
        isRunning = false
    }

    // MARK: - The tests

    private func deviceInfo() -> SpikeResult {
        SpikeResult(title: "0. Device", status: .info,
                    detail: "\(UIDevice.current.model) · iOS \(UIDevice.current.systemVersion) · system language \(Locale.current.identifier)\n(Foundation Models can refuse to run if the system language isn't supported.)")
    }

    private func testVision() -> SpikeResult {
        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        let languages = request.supportedRecognitionLanguages
        let hasThai = languages.contains { $0.languageCode?.identifier == "th" }
        return SpikeResult(title: "1. Vision can read Thai?", status: hasThai ? .pass : .fail,
                           detail: languages.map(\.minimalIdentifier).joined(separator: ", "))
    }

    private func testOnDeviceAvailability() -> SpikeResult {
        switch SystemLanguageModel.default.availability {
        case .available:
            return SpikeResult(title: "2. On-device AI available?", status: .pass, detail: "available")
        case .unavailable(let reason):
            return SpikeResult(title: "2. On-device AI available?", status: .fail, detail: "unavailable: \(reason)")
        }
    }

    private func testOnDeviceThaiSupport() -> SpikeResult {
        let model = SystemLanguageModel.default
        let thai = model.supportsLocale(Locale(identifier: "th_TH"))
        let languages = model.supportedLanguages.map(\.minimalIdentifier).sorted().joined(separator: ", ")
        return SpikeResult(title: "3. On-device AI supports Thai?", status: thai ? .pass : .fail,
                           detail: "supportsLocale(th_TH) = \(thai)\nlanguages: \(languages)")
    }

    private func testOnDeviceUnderstanding() async -> SpikeResult {
        let title = "4. On-device AI understands a Thai label?"
        guard case .available = SystemLanguageModel.default.availability else {
            return SpikeResult(title: title, status: .fail, detail: "skipped: on-device AI is unavailable")
        }
        let session = LanguageModelSession(instructions: PillInfo.extractionInstructions)
        return await askModel(title: title) {
            try await session.respond(to: aiSample.text, generating: PillInfo.self).content
        }
    }

    private func testThaiVoice() async -> SpikeResult {
        // speechVoices() freezes the app if called on the main thread, so ask from a background task.
        let voices = await Task.detached {
            AVSpeechSynthesisVoice.speechVoices()
                .filter { $0.language.hasPrefix("th") }
                .map { "\($0.name) (\($0.language))" }
        }.value
        return SpikeResult(title: "5. Thai voice installed?", status: voices.isEmpty ? .fail : .pass,
                           detail: voices.isEmpty ? "none: Settings ▸ Accessibility ▸ Spoken Content ▸ Voices ▸ Thai"
                                                  : voices.joined(separator: ", "))
    }

    private func testRules() -> SpikeResult {
        var lines: [String] = []
        var passed = 0
        for sample in SampleLabels.all {
            let got = LabelParser.parse(sample.lines)
            if got == sample.expected {
                passed += 1
                lines.append("✅ #\(sample.id) \(got.summary)")
            } else {
                lines.append("❌ #\(sample.id) got:      \(got.summary)\n      expected: \(sample.expected.summary)")
            }
        }
        return SpikeResult(title: "6. Thai rules: \(passed)/\(SampleLabels.all.count) labels correct",
                           status: passed == SampleLabels.all.count ? .pass : .fail,
                           detail: lines.joined(separator: "\n"))
    }

    private func privateCloudComputeResult() async -> SpikeResult {
        #if compiler(>=6.4)   // Swift 6.4 ships with Xcode 27
        if #available(iOS 27, *) {
            return await testPrivateCloudCompute()
        }
        return SpikeResult(title: "8. Private Cloud Compute", status: .info, detail: "skipped: needs iOS 27")
        #else
        return SpikeResult(title: "8. Private Cloud Compute", status: .info, detail: "skipped: built with Xcode 26")
        #endif
    }

    #if compiler(>=6.4)
    /// Apple's server-side model (iOS 27 only, needs internet).
    /// Only checks availability: calling it without the com.apple.developer.private-cloud-compute
    /// entitlement CRASHES the app (fatal error, not a catchable error). Adding that entitlement is a
    /// project-settings change, so the team has to approve it first.
    @available(iOS 27, *)
    private func testPrivateCloudCompute() async -> SpikeResult {
        let model = PrivateCloudComputeLanguageModel()
        let available: Bool
        if case .available = model.availability { available = true } else { available = false }
        return SpikeResult(
            title: "8. Private Cloud Compute available?",
            status: available ? .partly : .fail,
            detail: """
            availability: \(model.availability)
            Thai test skipped: using PCC needs the entitlement com.apple.developer.private-cloud-compute
            (target ▸ Signing & Capabilities). Without it the app crashes. It may not work with a free Personal Team.
            """)
    }
    #endif

    /// Times a model call and compares its answer with the expected one.
    private func askModel(title: String, _ call: () async throws -> PillInfo) async -> SpikeResult {
        let start = ContinuousClock.now
        do {
            let got = try await call()
            let seconds = seconds(since: start)
            let matches = got == aiSample.expected
            return SpikeResult(title: title, status: matches ? .pass : .partly,
                               detail: "\(seconds)\ngot:      \(got.summary)\nexpected: \(aiSample.expected.summary)")
        } catch {
            return SpikeResult(title: title, status: .fail, detail: "\(seconds(since: start))\nerror: \(error)")
        }
    }

    private func seconds(since start: ContinuousClock.Instant) -> String {
        let d = start.duration(to: .now)
        return String(format: "took %.1f s", Double(d.components.seconds) + Double(d.components.attoseconds) / 1e18)
    }

    // MARK: - Photo test

    private func readPhoto(_ item: PhotosPickerItem) async {
        photoReport = "กำลังอ่าน… (reading)"
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                photoReport = "Couldn't load that photo."
                return
            }
            let lines = try await readText(from: image)
            var text = "Vision read \(lines.count) lines:\n" + lines.joined(separator: "\n")
            text += "\n\nRules understood:\n" + LabelParser.parse(lines).summary
            if case .available = SystemLanguageModel.default.availability {
                let session = LanguageModelSession(instructions: PillInfo.extractionInstructions)
                do {
                    let ai = try await session.respond(to: lines.joined(separator: "\n"), generating: PillInfo.self).content
                    text += "\n\nOn-device AI understood:\n" + ai.summary
                } catch {
                    text += "\n\nOn-device AI error: \(error)"
                }
            }
            photoReport = text
        } catch {
            photoReport = "Error: \(error)"
        }
    }
}

// MARK: - Small helpers

struct SpikeResult: Identifiable {
    enum Status: String { case pass = "PASS", partly = "PARTLY", fail = "FAIL", info = "INFO" }

    let id = UUID()
    let title: String
    let status: Status
    let detail: String
}

private struct ResultRow: View {
    let result: SpikeResult

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(result.title, systemImage: symbol)
                .font(.headline)
                .foregroundStyle(color)
            Text(result.detail)
                .font(.callout.monospaced())
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
        .padding(.vertical, 4)
    }

    private var symbol: String {
        switch result.status {
        case .pass: "checkmark.circle.fill"
        case .partly: "exclamationmark.circle.fill"
        case .fail: "xmark.circle.fill"
        case .info: "info.circle.fill"
        }
    }

    private var color: Color {
        switch result.status {
        case .pass: .green
        case .partly: .orange
        case .fail: .red
        case .info: .blue
        }
    }
}

/// Keeps the synthesizer alive; if it's released, speech stops instantly.
final class ThaiSpeaker {
    private let synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "th-TH")
        utterance.rate = 0.42   // a bit slower than normal (0.5) for older listeners
        synthesizer.speak(utterance)
    }
}

#Preview {
    SpikeTestView()
}
