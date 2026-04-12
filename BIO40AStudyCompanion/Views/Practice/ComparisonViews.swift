import SwiftUI

// MARK: - Comparison View (Single Page)

struct ComparisonListView: View {
    @Environment(ContentService.self) private var content

    @State private var selectedGroup: String?
    @State private var selectedTable: ComparisonTable?

    private var chapterGroups: [String] {
        var seen: Set<String> = []
        return content.comparisons.compactMap { section in
            let group = section.chapterGroup
            if seen.contains(group) { return nil }
            seen.insert(group)
            return group
        }
    }

    private var tablesForGroup: [ComparisonTable] {
        content.comparisons
            .filter { selectedGroup == nil || $0.chapterGroup == selectedGroup }
            .flatMap(\.tables)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Chapter group pills
                chapterGroupPills

                // Topic pills
                topicPills

                // Venn diagram
                if let table = selectedTable ?? tablesForGroup.first {
                    if table.terms.count == 2 {
                        TwoTermVennView(table: table)
                    } else {
                        ThreeTermVennView(table: table)
                    }
                }

                // Footer
                Text("\(tablesForGroup.count) diagrams across all \(chapterGroups.count) sections. Use the section buttons at the top to jump between chapters, then the smaller pills to pick the specific comparison.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Comparisons")
        .onAppear {
            if selectedGroup == nil, let first = chapterGroups.first {
                selectedGroup = first
            }
            if selectedTable == nil {
                selectedTable = tablesForGroup.first
            }
        }
    }

    // MARK: - Chapter Group Pills

    private var chapterGroupPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(chapterGroups, id: \.self) { group in
                    Button {
                        selectedGroup = group
                        selectedTable = content.comparisons
                            .filter { $0.chapterGroup == group }
                            .flatMap(\.tables)
                            .first
                    } label: {
                        Text(group)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                selectedGroup == group
                                    ? Color.blue
                                    : Color(.tertiarySystemFill),
                                in: RoundedRectangle(cornerRadius: 10)
                            )
                            .foregroundStyle(selectedGroup == group ? .white : .primary)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Topic Pills

    private var topicPills: some View {
        FlowLayout(spacing: 8) {
            ForEach(tablesForGroup) { table in
                Button {
                    selectedTable = table
                } label: {
                    Text(table.pillLabel)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            selectedTable?.id == table.id
                                ? Color.blue.opacity(0.2)
                                : Color(.tertiarySystemFill),
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                        .foregroundStyle(selectedTable?.id == table.id ? .blue : .primary)
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Two-Term Venn Diagram

struct TwoTermVennView: View {
    let table: ComparisonTable

    private let leftColor = Color.blue
    private let rightColor = Color.orange

    var body: some View {
        VStack(spacing: 0) {
            // Term labels
            HStack {
                Text(table.terms[0])
                    .font(.headline)
                    .foregroundStyle(leftColor)
                Spacer()
                Text("— shared —")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(table.terms[1])
                    .font(.headline)
                    .foregroundStyle(rightColor)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)

            // Venn circles
            GeometryReader { geo in
                let diameter = min(geo.size.width * 0.55, 280.0)
                let overlap = diameter * 0.35
                let totalWidth = diameter * 2 - overlap
                let startX = (geo.size.width - totalWidth) / 2

                ZStack(alignment: .topLeading) {
                    // Left circle
                    Circle()
                        .fill(leftColor.opacity(0.12))
                        .stroke(leftColor.opacity(0.3), lineWidth: 1.5)
                        .frame(width: diameter, height: diameter)
                        .position(x: startX + diameter / 2, y: diameter / 2)

                    // Right circle
                    Circle()
                        .fill(rightColor.opacity(0.12))
                        .stroke(rightColor.opacity(0.3), lineWidth: 1.5)
                        .frame(width: diameter, height: diameter)
                        .position(x: startX + totalWidth - diameter / 2, y: diameter / 2)

                    // Left unique text
                    VStack(spacing: 4) {
                        ForEach(table.unique[0], id: \.self) { trait in
                            Text(trait)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(leftColor)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(width: diameter - overlap - 16)
                    .position(x: startX + (diameter - overlap) / 2, y: diameter / 2)

                    // Shared text (center overlap)
                    VStack(spacing: 4) {
                        ForEach(table.shared, id: \.self) { trait in
                            Text(trait)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(width: overlap - 8)
                    .position(x: startX + diameter - overlap / 2, y: diameter / 2)

                    // Right unique text
                    VStack(spacing: 4) {
                        ForEach(table.unique[1], id: \.self) { trait in
                            Text(trait)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(rightColor)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(width: diameter - overlap - 16)
                    .position(x: startX + totalWidth - (diameter - overlap) / 2, y: diameter / 2)
                }
            }
            .frame(height: min(UIScreen.main.bounds.width * 0.55, 280))
        }
        .padding()
    }
}

// MARK: - Three-Term Venn Diagram

struct ThreeTermVennView: View {
    let table: ComparisonTable

    private let colors: [Color] = [.blue, .purple, .orange]

    var body: some View {
        VStack(spacing: 12) {
            // Term labels
            HStack {
                ForEach(Array(table.terms.enumerated()), id: \.offset) { index, term in
                    if index > 0 { Spacer() }
                    Text(term)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(colors[index])
                    if index < table.terms.count - 1 { Spacer() }
                }
            }
            .padding(.horizontal, 24)

            // Venn circles
            GeometryReader { geo in
                let diameter = min(geo.size.width * 0.48, 200.0)
                let centerX = geo.size.width / 2
                let offsetX: CGFloat = diameter * 0.28
                let offsetY: CGFloat = diameter * 0.2

                ZStack {
                    // Top circle
                    Circle()
                        .fill(colors[0].opacity(0.12))
                        .stroke(colors[0].opacity(0.3), lineWidth: 1.5)
                        .frame(width: diameter, height: diameter)
                        .position(x: centerX - offsetX, y: diameter / 2)

                    // Bottom-left unique text
                    VStack(spacing: 3) {
                        ForEach(table.unique[0], id: \.self) { trait in
                            Text(trait)
                                .font(.system(size: 9))
                                .fontWeight(.medium)
                                .foregroundStyle(colors[0])
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(width: diameter * 0.4)
                    .position(x: centerX - offsetX - diameter * 0.18, y: diameter * 0.35)

                    // Right circle
                    Circle()
                        .fill(colors[1].opacity(0.12))
                        .stroke(colors[1].opacity(0.3), lineWidth: 1.5)
                        .frame(width: diameter, height: diameter)
                        .position(x: centerX + offsetX, y: diameter / 2)

                    // Right unique text
                    VStack(spacing: 3) {
                        ForEach(table.unique[1], id: \.self) { trait in
                            Text(trait)
                                .font(.system(size: 9))
                                .fontWeight(.medium)
                                .foregroundStyle(colors[1])
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(width: diameter * 0.4)
                    .position(x: centerX + offsetX + diameter * 0.18, y: diameter * 0.35)

                    // Bottom circle
                    Circle()
                        .fill(colors[2].opacity(0.12))
                        .stroke(colors[2].opacity(0.3), lineWidth: 1.5)
                        .frame(width: diameter, height: diameter)
                        .position(x: centerX, y: diameter / 2 + offsetY * 1.5)

                    // Bottom unique text
                    VStack(spacing: 3) {
                        ForEach(table.unique[2], id: \.self) { trait in
                            Text(trait)
                                .font(.system(size: 9))
                                .fontWeight(.medium)
                                .foregroundStyle(colors[2])
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(width: diameter * 0.4)
                    .position(x: centerX, y: diameter / 2 + offsetY * 1.5 + diameter * 0.22)

                    // Shared text (center)
                    VStack(spacing: 2) {
                        Text("shared")
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                        ForEach(table.shared, id: \.self) { trait in
                            Text(trait)
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(width: diameter * 0.35)
                    .position(x: centerX, y: diameter / 2 + offsetY * 0.4)
                }
            }
            .frame(height: min(UIScreen.main.bounds.width * 0.65, 300))
        }
        .padding()
    }
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
