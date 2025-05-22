import SwiftUI

@available(iOS 16.0, *)
struct ContentView: View {
    private let notebookSpreadVC = NotebookSpreadViewController()
    
    var body: some View {
        VStack(spacing: 0) {
            NotebookViewContainer(notebookSpreadVC: notebookSpreadVC)
                .frame(width: 1200, height: 800) // 👈 你想要的大小
                .clipped() // 防止超出边界
                .border(Color.red) // 调试时画边框看效果
            
            Divider()
            
            ToolBarView(notebookSpreadVC: notebookSpreadVC)
        }
    }
    
    @available(iOS 16.0, *)
    struct ToolBarView: View {
        let notebookSpreadVC: NotebookSpreadViewController
        
        var body: some View {
            HStack {
                Button("⬅ Prev") {
                    notebookSpreadVC.goToPrevPage()
                }
                
                Button("Undo") {
                    notebookSpreadVC.undo()
                }
                
                Button("Redo") {
                    notebookSpreadVC.redo()
                }
                
                Button("Add Page") {
                    notebookSpreadVC.addNewPagePair()
                }
                
                Button("➡ Next") {
                    notebookSpreadVC.goToNextPage()
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
        }
    }}
