import SwiftUI

// pos is free-form; map known values (incl. abbreviations) to Korean, else raw.
private let POS_KO: [String: String] = [
    "noun": "명사", "verb": "동사", "adjective": "형용사", "adj": "형용사",
    "adverb": "부사", "adv": "부사", "preposition": "전치사", "prep": "전치사",
    "conjunction": "접속사", "conj": "접속사", "pronoun": "대명사", "wh-word": "의문사",
    "determiner": "한정사", "det": "한정사", "modal": "조동사", "phrase": "표현",
    "abbr": "약어", "interjection": "감탄사",
]
private func posLabel(_ pos: String?) -> String {
    guard let pos, !pos.isEmpty else { return "" }
    return POS_KO[pos] ?? pos
}

private let GRADE_KNOWN = 4
private let GRADE_UNKNOWN = 1

/// Word learning card (RN `app/learn/[lessonId].tsx`): image → POS → word+TTS →
/// IPA·한글발음 → locale chips → (tap) meaning → example (target bold)+TTS.
struct LearnView: View {
    let lessonId: String

    @State private var words: [Word] = []
    @State private var loading = true
    @State private var idx = 0
    @State private var reveal = false
    @ObservedObject private var store = LocalStore.shared

    var body: some View {
        Group {
            if loading {
                ProgressView().tint(Theme.accent)
            } else if words.isEmpty {
                Text("학습할 단어가 없습니다.").foregroundColor(Theme.textMuted)
            } else if idx >= words.count {
                VStack(spacing: 20) {
                    Text("완료! 🎉").font(.title).foregroundColor(Theme.text)
                    Button("다시 시작") {
                        idx = 0
                        reveal = false
                        store.saveProgress(lessonId: lessonId, idx: 0)
                    }
                    .font(.headline.bold()).foregroundColor(.white)
                    .padding(.horizontal, 32).padding(.vertical, 12)
                    .background(Theme.accent).cornerRadius(12)
                }
            } else {
                content(words[idx])
                    .gesture(
                        DragGesture(minimumDistance: 40)
                            .onEnded { value in
                                let dx = value.translation.width
                                let dy = value.translation.height
                                guard abs(dx) > abs(dy) else { return }
                                if dx < 0, idx < words.count - 1 {
                                    advance(GRADE_KNOWN, words[idx])
                                } else if dx > 0, idx > 0 {
                                    reveal = false
                                    idx -= 1
                                    store.saveProgress(lessonId: lessonId, idx: idx)
                                }
                            }
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func load() async {
        words = (try? await Repo.learnQueue(lessonId)) ?? []
        loading = false
        let saved = store.loadProgress(lessonId: lessonId)
        if saved < words.count { idx = saved }
    }

    private var usLocale: String {
        guard idx < words.count else { return "en-US" }
        let a = words[idx].audio
        return (a.first { $0.locale == "en_US" } ?? a.first)?.bcp47 ?? "en-US"
    }

    private func content(_ cur: Word) -> some View {
        VStack(spacing: 0) {
            Text("\(idx + 1) / \(words.count)")
                .font(.subheadline).foregroundColor(Theme.textMuted)
                .frame(maxWidth: .infinity, alignment: .leading).padding([.horizontal, .top], 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    AsyncImage(url: URL(string: imageURL(cur))) { img in
                        img.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle().fill(Color(hex: 0xE2E8F0))
                    }
                    .frame(height: 200).frame(maxWidth: .infinity).clipped()

                    VStack(alignment: .leading, spacing: 8) {
                        if !posLabel(cur.pos).isEmpty {
                            Text(posLabel(cur.pos)).font(.subheadline).foregroundColor(Color(hex: 0x64748B))
                        }
                        HStack(spacing: 10) {
                            Text(cur.word).font(.system(size: 34, weight: .heavy)).foregroundColor(Color(hex: 0x0F172A))
                            Button { Tts.shared.speak(cur.word, locale: usLocale) } label: {
                                Text("🔊").frame(width: 36, height: 36).background(Color(hex: 0xF1F5F9)).clipShape(Circle())
                            }
                            .accessibilityLabel("발음 듣기")
                            .accessibilityIdentifier("tts-word")
                        }
                        let phon = [cur.ipa, cur.pronKo].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: "  ·  ")
                        if !phon.isEmpty { Text(phon).foregroundColor(Color(hex: 0x64748B)) }

                        HStack(spacing: 6) {
                            ForEach(cur.audio, id: \.locale) { a in
                                Button { Tts.shared.speak(cur.word, locale: a.bcp47) } label: {
                                    Text(a.bcp47).font(.caption.weight(.semibold)).foregroundColor(Color(hex: 0x64748B))
                                        .padding(.horizontal, 8).padding(.vertical, 4)
                                        .background(Color(hex: 0xF1F5F9)).cornerRadius(6)
                                }
                            }
                        }.padding(.top, 4)

                        if reveal {
                            Text(cur.meaningKo).font(.title3.bold()).foregroundColor(Color(hex: 0x0F172A)).padding(.top, 12)
                            if let ex = cur.exampleEn, !ex.isEmpty {
                                Divider().padding(.vertical, 12)
                                HStack(alignment: .top, spacing: 10) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        exampleText(ex, target: cur.word)
                                        if let ko = cur.exampleKo, !ko.isEmpty {
                                            Text(ko).foregroundColor(Color(hex: 0x64748B))
                                        }
                                    }
                                    Spacer()
                                    Button { Tts.shared.speak(ex, locale: usLocale) } label: {
                                        Text("🔊").frame(width: 32, height: 32).background(Color(hex: 0xF1F5F9)).clipShape(Circle())
                                    }
                                    .accessibilityLabel("예문 듣기")
                                }
                            }
                        } else {
                            Text("탭하여 뜻 보기").foregroundColor(Color(hex: 0x64748B))
                                .frame(maxWidth: .infinity).padding(.top, 24)
                        }
                    }
                    .padding(20)
                }
                .background(Color.white).cornerRadius(16)
                .padding(16)
                .contentShape(Rectangle())
                .onTapGesture {
                    if !reveal { reveal = true; Tts.shared.speak(cur.word, locale: usLocale) }
                }
            }

            toolbar(cur)
        }
    }

    private func toolbar(_ cur: Word) -> some View {
        HStack(spacing: 20) {
            navButton("‹", label: "이전 단어", enabled: idx > 0) {
                reveal = false
                idx = max(0, idx - 1)
                store.saveProgress(lessonId: lessonId, idx: idx)
            }
            midButton("🗑", label: "모르겠어요") { advance(GRADE_UNKNOWN, cur) }
            midButton(store.isFavorite(cur.id) ? "🔖" : "🏷",
                      label: store.isFavorite(cur.id) ? "즐겨찾기 해제" : "즐겨찾기 추가") {
                store.toggleFavorite(cur)
            }
            navButton("›", label: "다음 단어 · 알아요", enabled: true) { advance(GRADE_KNOWN, cur) }
        }
        .padding(.top, 12).padding(.bottom, 24)
    }

    private func advance(_ g: Int, _ cur: Word) {
        store.recordGrade(wordId: cur.id, grade: g)
        Task { await Repo.grade(wordId: cur.id, grade: g) }
        reveal = false
        idx += 1
        store.saveProgress(lessonId: lessonId, idx: idx)
    }

    private func navButton(_ glyph: String, label: String, enabled: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(glyph).font(.system(size: 30, weight: .bold)).foregroundColor(Theme.text)
                .frame(width: 60, height: 60).background(Theme.bgElev).clipShape(Circle())
        }
        .disabled(!enabled).opacity(enabled ? 1 : 0.35)
        .accessibilityLabel(label)
    }

    private func midButton(_ glyph: String, label: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(glyph).font(.title3)
                .frame(width: 50, height: 50).background(Theme.bgCard)
                .overlay(Circle().stroke(Theme.border)).clipShape(Circle())
        }
        .accessibilityLabel(label)
    }

    /// Word-relevant image via loremflickr; falls back to imageUrl from backend.
    private func imageURL(_ w: Word) -> String {
        if let u = w.imageUrl, !u.isEmpty { return u }
        let slug = w.word.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? w.word
        return "https://loremflickr.com/640/420/\(slug)"
    }

    /// Example sentence with the target word bolded (RN ExampleSentence).
    private func exampleText(_ text: String, target: String) -> Text {
        let parts = text.components(separatedBy: target)
        var out = Text("")
        for (i, seg) in parts.enumerated() {
            out = out + Text(seg).foregroundColor(Color(hex: 0x0F172A))
            if i < parts.count - 1 {
                out = out + Text(target).fontWeight(.heavy).foregroundColor(Color(hex: 0x0F172A))
            }
        }
        return out
    }
}
