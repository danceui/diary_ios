import SwiftUI

enum MenuRoute: Equatable {
    case toolsOnly
    case presets(tool: Tool)                    // 二级
    case details(tool: Tool, presetIndex: Int)  // 三级
}

@MainActor
final class MenuStore: ObservableObject {
    @Published var route: MenuRoute = .toolsOnly

    func openPresets(for tool: Tool) {
        withAnimation(.snappy) { route = .presets(tool: tool) }
    }
    func openDetails(for tool: Tool, index: Int) {
        withAnimation(.snappy) { route = .details(tool: tool, presetIndex: index) }
    }
    func closeDetailsToPresets() {
        if case .details(let t, _) = route {
            withAnimation(.snappy) { route = .presets(tool: t) }
        }
    }
    func backToTools() {
        withAnimation(.snappy) { route = .toolsOnly }
    }
}

struct ToolAnchorKey: PreferenceKey {
    static var defaultValue: [Tool: Anchor<CGRect>] = [:]
    static func reduce(value: inout [Tool: Anchor<CGRect>], nextValue: () -> [Tool: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}