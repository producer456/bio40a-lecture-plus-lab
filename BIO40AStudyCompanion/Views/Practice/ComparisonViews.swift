import SwiftUI

// MARK: - Comparison List View

struct ComparisonListView: View {
    @Environment(ContentService.self) private var content

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Compare & Contrast", systemImage: "circle.grid.cross.fill")
                        .font(.headline)
                    Text("Visual comparison tables to help you distinguish similar concepts. Tap any table to see the full breakdown.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }

            if content.comparisons.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No comparison tables available yet.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                }
            } else {
                ForEach(content.comparisons) { section in
                    Section(section.sectionTitle) {
                        ForEach(section.tables) { table in
                            NavigationLink(destination: ComparisonDetailView(table: table, sectionTitle: section.sectionTitle)) {
                                VStack(alignment: .leading, spacing: 6) {
                                    FlowLayout(spacing: 6) {
                                        ForEach(Array(table.terms.enumerated()), id: \.offset) { index, term in
                                            Text(term)
                                                .font(.caption2)
                                                .fontWeight(.medium)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(stableTermColor(index).opacity(0.15), in: Capsule())
                                                .foregroundStyle(stableTermColor(index))
                                        }
                                    }
                                    Text("\(table.rows.count) comparison \(table.rows.count == 1 ? "feature" : "features")")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Comparisons")
    }
}

// MARK: - Comparison Detail View

struct ComparisonDetailView: View {
    let table: ComparisonTable
    let sectionTitle: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                vennHeader

                ForEach(Array(table.rows.enumerated()), id: \.offset) { _, row in
                    comparisonCard(row: row)
                }
            }
            .padding()
        }
        .navigationTitle("Compare")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Venn Header

    private var vennHeader: some View {
        VStack(spacing: 12) {
            Text(sectionTitle)
                .font(.caption)
                .foregroundStyle(.secondary)

            if table.terms.count <= 4 {
                vennCircles
            } else {
                termPills
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var vennCircles: some View {
        ZStack {
            ForEach(Array(table.terms.enumerated()), id: \.offset) { index, term in
                let offset = vennOffset(index: index, count: table.terms.count)
                Circle()
                    .fill(stableTermColor(index).opacity(0.15))
                    .stroke(stableTermColor(index).opacity(0.4), lineWidth: 2)
                    .frame(width: 110, height: 110)
                    .overlay {
                        Text(term)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(stableTermColor(index))
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.6)
                            .lineLimit(3)
                            .padding(12)
                    }
                    .offset(x: offset.x, y: offset.y)
            }
        }
        .frame(height: vennHeight)
    }

    private var vennHeight: CGFloat {
        switch table.terms.count {
        case 1: return 130
        case 2: return 130
        case 3: return 160
        case 4: return 180
        default: return 130
        }
    }

    private func vennOffset(index: Int, count: Int) -> (x: CGFloat, y: CGFloat) {
        switch count {
        case 1: return (0, 0)
        case 2: return index == 0 ? (-35, 0) : (35, 0)
        case 3:
            switch index {
            case 0: return (-35, 15)
            case 1: return (35, 15)
            default: return (0, -20)
            }
        case 4:
            switch index {
            case 0: return (-35, -20)
            case 1: return (35, -20)
            case 2: return (-35, 25)
            default: return (35, 25)
            }
        default: return (0, 0)
        }
    }

    private var termPills: some View {
        FlowLayout(spacing: 8) {
            ForEach(Array(table.terms.enumerated()), id: \.offset) { index, term in
                Text(term)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(stableTermColor(index).opacity(0.15), in: Capsule())
                    .foregroundStyle(stableTermColor(index))
            }
        }
    }

    // MARK: - Comparison Card

    private func comparisonCard(row: ComparisonRow) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.left.and.right")
                    .font(.caption)
                    .foregroundStyle(.blue)
                Text(row.feature)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            ForEach(Array(zip(table.terms, row.values).enumerated()), id: \.offset) { index, pair in
                let (term, value) = pair
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(stableTermColor(index))
                        .frame(width: 8, height: 8)
                        .padding(.top, 5)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(term)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(stableTermColor(index))
                        Text(value)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: cardShadowColor, radius: 4, y: 2)
    }

    private var cardShadowColor: Color {
        colorScheme == .dark ? .white.opacity(0.04) : .black.opacity(0.08)
    }
}

// MARK: - Stable Term Colors

/// Deterministic color based on index position, consistent across launches and views.
private func stableTermColor(_ index: Int) -> Color {
    let colors: [Color] = [.blue, .purple, .orange, .green, .pink, .teal]
    return colors[index % colors.count]
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return (positions, CGSize(width: maxX, height: y + rowHeight))
    }
}
