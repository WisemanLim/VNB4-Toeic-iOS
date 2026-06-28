import SwiftUI

/// 취약유형결과 donut (RN `ScoreDonut.tsx`, react-native-svg → SwiftUI).
/// Guest (untested) shows an empty gray track + CTA; tested shows LC/RC segments.
/// iOS 16-safe (trimmed Circle strokes, not Swift Charts SectorMark which is iOS 17+).
struct ScoreDonut: View {
    let avgScore: Double
    let targetScore: Double
    let segments: [AnalysisSegment]

    private let size: CGFloat = 180
    private let lineWidth: CGFloat = 22

    private var total: Double { max(segments.reduce(0) { $0 + $1.value }, 0.0001) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.bgElev.opacity(0.35), lineWidth: lineWidth)

            if segments.isEmpty {
                VStack(spacing: 4) {
                    Text("테스트 후 확인").font(.subheadline).foregroundColor(Theme.textMuted)
                }
            } else {
                ForEach(Array(segmentRanges().enumerated()), id: \.offset) { _, item in
                    Circle()
                        .trim(from: item.start, to: item.end)
                        .stroke(Color(css: item.seg.color),
                                style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
                        .rotationEffect(.degrees(-90))
                }
                VStack(spacing: 2) {
                    Text("\(Int(avgScore))").font(.system(size: 34, weight: .heavy)).foregroundColor(Theme.text)
                    Text("목표 \(Int(targetScore))").font(.caption).foregroundColor(Theme.textMuted)
                }
            }
        }
        .frame(width: size, height: size)
    }

    private func segmentRanges() -> [(seg: AnalysisSegment, start: CGFloat, end: CGFloat)] {
        var acc: CGFloat = 0
        return segments.map { seg in
            let frac = CGFloat(seg.value / total)
            let start = acc
            acc += frac
            return (seg, start, acc)
        }
    }
}
