import SwiftUI

/// 북마크 모아보기 (RN `app/bookmarks.tsx`): bookmarked words + sentences from LocalStore.
struct BookmarksView: View {
    @ObservedObject private var store = LocalStore.shared

    var body: some View {
        List {
            Section("단어 북마크 (\(store.bookmarkedWords.count))") {
                if store.bookmarkedWords.isEmpty {
                    Text("북마크한 단어가 없습니다.").foregroundColor(Theme.textMuted)
                } else {
                    ForEach(store.bookmarkedWords) { word in
                        WordBookmarkRow(word: word)
                    }
                    .onDelete { offsets in
                        for i in offsets { store.toggleFavorite(store.bookmarkedWords[i]) }
                    }
                }
            }

            Section("문장 북마크 (\(store.bookmarkedSentences.count))") {
                if store.bookmarkedSentences.isEmpty {
                    Text("북마크한 문장이 없습니다.").foregroundColor(Theme.textMuted)
                } else {
                    ForEach(store.bookmarkedSentences) { sentence in
                        SentenceBookmarkRow(sentence: sentence)
                    }
                    .onDelete { offsets in
                        for i in offsets { store.toggleSentenceFavorite(store.bookmarkedSentences[i]) }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("북마크")
        .navigationBarTitleDisplayMode(.inline)
        .background(Theme.bg.ignoresSafeArea())
    }
}

private struct WordBookmarkRow: View {
    let word: Word
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(word.word).font(.headline).foregroundColor(Theme.text)
            Text(word.meaningKo).font(.subheadline).foregroundColor(Theme.textMuted)
        }
        .padding(.vertical, 4)
    }
}

private struct SentenceBookmarkRow: View {
    let sentence: SentenceItem
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(sentence.fullSentence).font(.subheadline).foregroundColor(Theme.text)
            Text(sentence.translationKo).font(.caption).foregroundColor(Theme.textMuted)
        }
        .padding(.vertical, 4)
    }
}
