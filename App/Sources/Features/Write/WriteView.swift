import SwiftUI

/// 문장쓰기·쉐도잉 (RN `app/write/[part].tsx`): 한글 힌트 → 단어칩 골라 문장 완성
/// → 확인 → 정답 + 전체문장 🔊(쉐도잉). Part 1–4.
struct WriteView: View {
    let part: Int

    @State private var items: [SentenceItem] = []
    @State private var loading = true
    @State private var idx = 0
    @State private var picked: [String] = []
    @State private var checked = false
    @State private var showHint = false
    @ObservedObject private var store = LocalStore.shared

    var body: some View {
        Group {
            if loading {
                ProgressView().tint(Theme.accent)
            } else if items.isEmpty {
                Text("문항이 없습니다.").foregroundColor(Theme.textMuted)
            } else if idx >= items.count {
                Text("완료! 🎉").font(.title).foregroundColor(Theme.text)
            } else {
                content(items[idx])
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Part \(part) · 문장쓰기")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func load() async {
        items = (try? await Repo.sentences(part: part)) ?? []
        loading = false
    }

    private func content(_ item: SentenceItem) -> some View {
        let chips = item.tokens.sorted { a, b in
            (a.hashValue ^ item.id.hashValue) < (b.hashValue ^ item.id.hashValue)
        }
        return VStack(alignment: .leading, spacing: 16) {
            Text("\(idx + 1) / \(items.count)").font(.subheadline).foregroundColor(Theme.textMuted)
            Text(item.translationKo).font(.title3.bold()).foregroundColor(Theme.text)
            Text(item.prompt).font(.body).foregroundColor(Theme.textMuted)

            if showHint {
                Text(item.fullSentence)
                    .font(.body).foregroundColor(Color(hex: 0x92400E))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: 0xFEF3C7))
                    .cornerRadius(10)
            }

            FlowChips(picked.isEmpty ? ["___"] : picked, color: Theme.accent) { token in
                if !checked, let i = picked.firstIndex(of: token) { picked.remove(at: i) }
            }

            Divider().background(Theme.border)

            FlowChips(chips.filter { !usedUp($0, in: chips) }, color: Theme.bgElev) { token in
                if !checked { picked.append(token) }
            }

            if checked {
                VStack(alignment: .leading, spacing: 8) {
                    Text(isCorrect(item) ? "정답! ✅" : "정답 보기")
                        .font(.headline).foregroundColor(isCorrect(item) ? .green : Theme.text)
                    HStack {
                        Text(item.fullSentence).font(.body.bold()).foregroundColor(Theme.text)
                        Button { Tts.shared.speak(item.fullSentence) } label: { Text("🔊") }
                    }
                }
            }

            Spacer()

            // Toolbar: 이전 | 힌트 | 북마크 | 확인/다음
            HStack(spacing: 10) {
                toolbarBtn("‹ 이전", enabled: idx > 0) { goPrev() }

                toolbarBtn("💡 힌트", enabled: !checked) { showHint.toggle() }

                toolbarBtn(store.isSentenceFavorite(item.id) ? "🔖" : "🏷", enabled: true) {
                    store.toggleSentenceFavorite(item)
                }

                Button(checked ? "다음 →" : "확인") {
                    if checked { next() } else { checked = true; Tts.shared.speak(item.fullSentence) }
                }
                .font(.headline.bold()).foregroundColor(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(Theme.accent).cornerRadius(10)
            }
        }
        .padding(16)
    }

    private func usedUp(_ token: String, in bank: [String]) -> Bool {
        let inBank = bank.filter { $0 == token }.count
        let inPicked = picked.filter { $0 == token }.count
        return inPicked >= inBank
    }

    private func isCorrect(_ item: SentenceItem) -> Bool {
        picked.joined(separator: " ") == item.answer
    }

    private func next() {
        idx += 1
        picked = []
        checked = false
        showHint = false
    }

    private func goPrev() {
        guard idx > 0 else { return }
        idx -= 1
        picked = []
        checked = false
        showHint = false
    }

    private func toolbarBtn(_ label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(.subheadline.bold()).foregroundColor(enabled ? Theme.text : Theme.textMuted)
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(Theme.bgElev).cornerRadius(10)
        }
        .disabled(!enabled)
    }
}

/// Simple wrapping chip row (lightweight flow layout for token chips).
private struct FlowChips: View {
    let tokens: [String]
    let color: Color
    let onTap: (String) -> Void

    init(_ tokens: [String], color: Color, onTap: @escaping (String) -> Void) {
        self.tokens = tokens; self.color = color; self.onTap = onTap
    }

    var body: some View {
        let cols = [GridItem(.adaptive(minimum: 70), spacing: 8)]
        LazyVGrid(columns: cols, alignment: .leading, spacing: 8) {
            ForEach(Array(tokens.enumerated()), id: \.offset) { _, token in
                Button { onTap(token) } label: {
                    Text(token).font(.subheadline).foregroundColor(.white)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(color).cornerRadius(8)
                }
            }
        }
    }
}
