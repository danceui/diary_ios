import SwiftUI

@available(iOS 16.0, *)
struct ContentView: View {
    private let notebookSpreadViewController = NotebookSpreadViewController()
    
    var body: some View {
        VStack(spacing: 0) {
            NotebookViewContainer(notebookSpreadViewController: notebookSpreadViewController)
            ToolBarView(notebookSpreadViewController: notebookSpreadViewController)
        }
    }
    
    @available(iOS 16.0, *)
    struct ToolBarView: View {
        let notebookSpreadViewController: NotebookSpreadViewController
        @State private var selectedTool: Tool = ToolManager.shared.currentTool
        
        var body: some View {
            HStack(spacing: 20) {
                // 工具选择
                Picker("", selection: $selectedTool) {
                    Text("Pen").tag(Tool.pen)
                    Text("Eraser").tag(Tool.eraser)
                    Text("Highlighter").tag(Tool.highlighter)
                    Text("Sticker").tag(Tool.sticker)
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: selectedTool) { newTool in
                    ToolManager.shared.currentTool = newTool
                    switch newTool {
                    case .pen:
                        ToolManager.shared.strokeColor = .black
                        ToolManager.shared.strokeWidth = 5.0
                    case .highlighter:
                        ToolManager.shared.strokeColor = UIColor.yellow.withAlphaComponent(0.5)
                        ToolManager.shared.strokeWidth = 10.0
                    case .eraser:
                        break // 颜色／粗细在 HandwritingLayer 忽略
                    case .sticker:
                        break // 颜色／粗细忽略
                    }
                }

                Divider().frame(height: 20)
                
                // 撤销／重做／加页
                Button("Undo") {
                    notebookSpreadViewController.undo()
                }
                Button("Redo") {
                    notebookSpreadViewController.redo()
                }
                Button("Add Page") {
                    notebookSpreadViewController.addNewPagePair()
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
        }
    }
}
