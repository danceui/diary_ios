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
        route = .presets(tool: tool)
    }
    func openDetails(for tool: Tool, index: Int) {
        route = .details(tool: tool, presetIndex: index)
    }
    func closeDetailsToPresets() {
        guard case .details(let t, _) = route else { return }
        withAnimation(.snappy) { route = .presets(tool: t) }
    }
    func backToTools() {
        route = .toolsOnly
    }
}

struct ToolAnchorKey: PreferenceKey {
    static var defaultValue: [Tool: Anchor<CGRect>] = [:]
    static func reduce(value: inout [Tool: Anchor<CGRect>], nextValue: () -> [Tool: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct PresetID: Hashable {
    let tool: Tool
    let index: Int
}

struct PresetAnchorKey: PreferenceKey {
    static var defaultValue: [PresetID: Anchor<CGRect>] = [:]
    static func reduce(value: inout [PresetID: Anchor<CGRect>], nextValue: () -> [PresetID: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}