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
        // Shuffle tokens deterministically by id so chips aren't in answer order.
        let chips = item.tokens.sorted { a, b in
            (a.hashValue ^ item.id.hashValue) < (b.hashValue ^ item.id.hashValue)
        }
        return VStack(alignment: .leading, spacing: 16) {
            Text("\(idx + 1) / \(items.count)").font(.subheadline).foregroundColor(Theme.textMuted)
            Text(item.translationKo).font(.title3.bold()).foregroundColor(Theme.text)
            Text(item.prompt).font(.body).foregroundColor(Theme.textMuted)

            // Built sentence area.
            FlowChips(picked.isEmpty ? ["___"] : picked, color: Theme.accent) { token in
                if !checked, let i = picked.firstIndex(of: token) { picked.remove(at: i) }
            }

            Divider().background(Theme.border)

            // Token bank.
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

            Button(checked ? "다음" : "확인") {
                if checked { next() } else { checked = true; Tts.shared.speak(item.fullSentence) }
            }
            .font(.headline.bold()).foregroundColor(.white)
            .frame(maxWidth: .infinity).padding().background(Theme.accent).cornerRadius(12)
        }
        .padding(16)
    }

    // A token may legitimately repeat; only hide as many as were picked.
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
        // Indexed so duplicate tokens are distinct tappable chips.
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
