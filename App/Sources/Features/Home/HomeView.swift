import SwiftUI

/// Home screen (RN `app/index.tsx`): auth bar, 취약유형 donut, review card,
/// LC/RC part grids, 문장쓰기·쉐도잉 section.
struct HomeView: View {
    @EnvironmentObject var auth: AuthStore
    @Environment(\.horizontalSizeClass) private var hSize
    @State private var analysis: Analysis?
    @State private var due = 0

    private var lc: [PartInfo] { TOEIC_PARTS.filter { $0.p <= 4 } }
    private var rc: [PartInfo] { TOEIC_PARTS.filter { $0.p >= 5 } }
    // iPad/regular width → 4 columns; iPhone/compact → 2 (적응형 레이아웃).
    private var cols: [GridItem] {
        let n = hSize == .regular ? 4 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: n)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    authBar
                    analysisCard
                    section("오늘의 학습")
                    reviewCard
                    bookmarksCard
                    section("LC · 듣기")
                    grid(lc) { p in NavigationLink(value: Route.learn("part-\(p.p)")) { PartCard(part: p) } }
                    section("RC · 독해")
                    grid(rc) { p in NavigationLink(value: Route.learn("part-\(p.p)")) { PartCard(part: p) } }
                    section("문장쓰기 · 쉐도잉")
                    grid(lc) { p in
                        NavigationLink(value: Route.write(p.p)) {
                            WriteCard(part: p)
                        }
                    }
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("VNB4 TOEIC")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .learn(let id): LearnView(lessonId: id)
                case .write(let part): WriteView(part: part)
                case .login: LoginView()
                case .bookmarks: BookmarksView()
                }
            }
            .task(id: auth.status == .authed) { await reload() }
        }
        .tint(Theme.accent)
    }

    private func reload() async {
        analysis = try? await Repo.analysis()
        due = (try? await Repo.dueCount()) ?? 0
    }

    // MARK: subviews

    @ViewBuilder private var authBar: some View {
        if auth.isAuthed {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(auth.user?.name ?? auth.user?.email ?? "로그인됨")
                        .font(.headline).foregroundColor(Theme.text)
                    Text("서버와 동기화 중 · 복습·분석 결과 저장")
                        .font(.caption).foregroundColor(Theme.textMuted)
                }
                Spacer()
                Button("로그아웃") { Task { await auth.logout(); await reload() } }
                    .font(.subheadline.bold()).foregroundColor(Theme.textMuted)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .overlay(Capsule().stroke(Theme.border))
            }
            .padding(12).background(Theme.bgCard).cornerRadius(12)
        } else {
            NavigationLink(value: Route.login) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("게스트 모드").font(.headline).foregroundColor(Theme.text)
                        Text("로그인하면 최신 단어·문장 + 복습/분석 동기화")
                            .font(.caption).foregroundColor(Theme.textMuted)
                    }
                    Spacer()
                    Text("로그인").font(.subheadline.bold()).foregroundColor(.white)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(Theme.accent).clipShape(Capsule())
                }
                .padding(12).background(Theme.bgCard).cornerRadius(12)
            }
        }
    }

    private var analysisCard: some View {
        VStack(spacing: 12) {
            Text("😓 취약유형결과").font(.headline.bold()).foregroundColor(Color(hex: 0x1E3A8A))
            ScoreDonut(avgScore: analysis?.avgScore ?? 0,
                       targetScore: analysis?.targetScore ?? 900,
                       segments: analysis?.segments ?? [])
            if let segs = analysis?.segments, !segs.isEmpty {
                HStack(spacing: 14) {
                    ForEach(segs, id: \.label) { s in
                        HStack(spacing: 6) {
                            Circle().fill(Color(css: s.color)).frame(width: 10, height: 10)
                            Text(s.label).font(.subheadline).foregroundColor(Color(hex: 0x475569))
                        }
                    }
                }
            }
            if !(analysis?.tested ?? false) {
                Text("* 분석결과는 테스트 완료 후 확인 가능합니다.")
                    .font(.caption).foregroundColor(Color(hex: 0x94A3B8))
            }
        }
        .frame(maxWidth: .infinity).padding(20).background(Color.white).cornerRadius(16)
    }

    private var reviewCard: some View {
        NavigationLink(value: Route.learn("due")) {
            HStack(spacing: 12) {
                Text("\(due)").font(.headline.bold()).foregroundColor(.white)
                    .frame(width: 40, height: 40).background(Color.white.opacity(0.25)).clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("복습 시작").font(.headline.bold()).foregroundColor(.white)
                    Text("복습 큐 \(due)개 대기 중").font(.subheadline).foregroundColor(.white.opacity(0.85))
                }
                Spacer()
                Text("›").font(.title).foregroundColor(.white)
            }
            .padding(16).background(Theme.accent).cornerRadius(16)
        }
    }

    private var bookmarksCard: some View {
        NavigationLink(value: Route.bookmarks) {
            HStack(spacing: 12) {
                Text("🔖").font(.title2)
                    .frame(width: 40, height: 40).background(Color.white.opacity(0.25)).clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("북마크 모아보기").font(.headline.bold()).foregroundColor(Theme.text)
                    Text("저장한 단어·문장 확인").font(.subheadline).foregroundColor(Theme.textMuted)
                }
                Spacer()
                Text("›").font(.title).foregroundColor(Theme.textMuted)
            }
            .padding(16).background(Theme.bgCard).cornerRadius(16)
        }
    }

    private func section(_ t: String) -> some View {
        Text(t).font(.title3.bold()).foregroundColor(Theme.text)
    }

    private func grid<V: View>(_ parts: [PartInfo], @ViewBuilder cell: @escaping (PartInfo) -> V) -> some View {
        LazyVGrid(columns: cols, spacing: 12) {
            ForEach(parts) { p in cell(p) }
        }
    }
}

/// Navigation routes (value-based NavigationStack).
enum Route: Hashable {
    case learn(String)
    case write(Int)
    case login
    case bookmarks
}

private struct PartCard: View {
    let part: PartInfo
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) { Text(part.icon).font(.title3); Text(part.title).font(.headline.bold()).foregroundColor(.white) }
            Text(part.desc).font(.subheadline).foregroundColor(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        .padding(16).background(part.color).cornerRadius(16)
    }
}

private struct WriteCard: View {
    let part: PartInfo
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) { Text("✍️").font(.title3); Text(part.title).font(.headline.bold()).foregroundColor(.white) }
            Text("받아쓰기 · 쉐도잉").font(.subheadline).foregroundColor(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        .padding(16).background(Color(hex: 0x0EA5E9)).cornerRadius(16)
    }
}
