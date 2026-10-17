import SwiftUI

/// What one envelope scan found: the medicine, the raw lines Vision read, and whether times were guessed.
struct EnvelopeScan {
    var info: PillInfo
    var lines: [String]
    var timesGuessed: Bool

    init(lines: [String]) {
        self.lines = lines
        info = LabelParser.parse(lines)
        timesGuessed = LabelParser.timesAreGuessed(in: lines)
    }
}

/// The big, easy-to-read card after scanning: what, how many, when. Can read itself aloud in Thai.
struct ScanResultCard: View {
    let scan: EnvelopeScan
    let onAdd: () -> Void
    let onEdit: () -> Void
    let onScanAgain: () -> Void

    @State private var speaker = SpeechReader()
    @State private var showingScannedText = false
    @ScaledMetric(relativeTo: .largeTitle) private var amountSize: CGFloat = 46

    private var info: PillInfo { scan.info }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Label("อ่านในเครื่อง · Read on this device", systemImage: "lock.shield.fill")
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .foregroundStyle(Theme.red)
                .background(Theme.red.opacity(0.12), in: Capsule())

            nameBlock

            Text(info.amountLine)
                .font(.system(size: amountSize, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.red)
                .accessibilityLabel(info.amountLine)

            whenBlock

            if !info.mealTiming.thai.isEmpty {
                Label("\(info.mealTiming.thai) · \(mealEnglish)", systemImage: "fork.knife")
                    .font(.title3.weight(.semibold))
            }

            ForEach(info.warnings, id: \.self) { warning in
                Label(warning, systemImage: "exclamationmark.triangle.fill")
                    .font(.headline)
                    .foregroundStyle(.orange)
            }

            buttons

            DisclosureGroup("ดูข้อความที่อ่านได้ · Show scanned text", isExpanded: $showingScannedText) {
                Text(scan.lines.joined(separator: "\n"))
                    .font(.callout.monospaced())
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
            }
            .tint(Theme.red)

            Label("ตรวจกับฉลากจริงทุกครั้ง · ไม่ใช่คำแนะนำทางการแพทย์\nAlways check the real label. Not medical advice.",
                  systemImage: "info.circle")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .onDisappear { speaker.stop() }
    }

    private var nameBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label {
                Text(info.drugName.isEmpty ? "ไม่พบชื่อยา (no name found)" : info.drugName)
            } icon: {
                Image(systemName: "pills.fill").foregroundStyle(Theme.red)
            }
            .font(.largeTitle.bold())
            if !info.strength.isEmpty {
                Text(info.strength)
                    .font(.title2.weight(.semibold))
            }
            if let friendly = DrugDictionary.friendlyName(for: info.drugName) {
                Text(friendly)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var whenBlock: some View {
        if info.asNeeded {
            chip(title: "เมื่อมีอาการ · When needed", symbol: "hand.raised.fill")
        } else if info.slots.isEmpty {
            Label("ไม่พบเวลาทานยา · No time found. Tap Edit to add one.", systemImage: "clock.badge.questionmark")
                .font(.headline)
                .foregroundStyle(.orange)
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10, alignment: .leading)],
                      alignment: .leading, spacing: 10) {
                ForEach(info.slots, id: \.self) { slot in
                    chip(title: "\(slot.thai) · \(slot.time.label)", symbol: slot.symbol)
                }
            }
            if scan.timesGuessed {
                Label("เดาเวลาจาก \"วันละ … ครั้ง\" · โปรดตรวจสอบ (times guessed, please check)",
                      systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.orange)
            }
        }
    }

    private func chip(title: String, symbol: String) -> some View {
        Label(title, systemImage: symbol)
            .font(.title3.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .foregroundStyle(.white)
            .background(Theme.card, in: Capsule())
    }

    private var buttons: some View {
        VStack(spacing: 12) {
            Button {
                speaker.speak(info.spokenThai)
            } label: {
                bigLabel("อ่านออกเสียง · Read aloud", symbol: "speaker.wave.2.fill", filled: false)
            }
            Button(action: onAdd) {
                bigLabel("เพิ่มในยาของฉัน · Add to my medicines", symbol: "plus.circle.fill", filled: true)
            }
            HStack(spacing: 12) {
                Button(action: onEdit) {
                    bigLabel("แก้ไข · Edit", symbol: "pencil", filled: false)
                }
                Button(action: onScanAgain) {
                    bigLabel("สแกนใหม่ · Again", symbol: "arrow.counterclockwise", filled: false)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func bigLabel(_ title: String, symbol: String, filled: Bool) -> some View {
        Label(title, systemImage: symbol)
            .font(.headline)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 60)
            .padding(.horizontal, 8)
            .foregroundStyle(filled ? Color.white : Theme.red)
            .background(filled ? Theme.card : Theme.red.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var mealEnglish: String {
        switch info.mealTiming {
        case .before: "Before meals"
        case .after: "After meals"
        case .with: "With meals"
        case .anytime: ""
        }
    }
}

#Preview("Metformin") {
    ScrollView {
        ScanResultCard(scan: EnvelopeScan(lines: SampleLabels.all[1].lines),
                       onAdd: {}, onEdit: {}, onScanAgain: {})
            .padding()
    }
    .background(Theme.background)
}

#Preview("When needed") {
    ScrollView {
        ScanResultCard(scan: EnvelopeScan(lines: SampleLabels.all[4].lines),
                       onAdd: {}, onEdit: {}, onScanAgain: {})
            .padding()
    }
    .background(Theme.background)
}
