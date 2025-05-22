import SwiftUI

@available(iOS 16.0, *)
struct ContentView: View {
    private let notebookVC = NotebookSpreadViewController()
    
    var body: some View {
        VStack(spacing: 0) {
            NotebookViewContainer(controller: notebookVC)
                .edgesIgnoringSafeArea(.all)
            
            Divider()
            
            ToolBarView(notebookVC: notebookVC)
        }
    }
    
    @available(iOS 16.0, *)
    struct ToolBarView: View {
        let notebookVC: NotebookSpreadViewController
        
        var body: some View {
            HStack {
                Button("⬅ Prev") {
                    notebookVC.goToPrevPage()
                }
                
                Button("Undo") {
                    notebookVC.undo()
                }
                
                Button("Redo") {
                    notebookVC.redo()
                }
                
                Button("Add Page") {
                    notebookVC.addNewPagePair()
                }
                
                Button("➡ Next") {
                    notebookVC.goToNextPage()
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
        }
    }}
