import SwiftUI

@available(iOS 16.0, *)
struct ContentView: View {
    private let notebookSpreadVC = NotebookSpreadViewController()
    
    var body: some View {
        VStack(spacing: 0) {
            NotebookViewContainer(notebookSpreadVC: notebookSpreadVC)
            ToolBarView(notebookSpreadVC: notebookSpreadVC)
        }
    }
    
    @available(iOS 16.0, *)
    struct ToolBarView: View {
        let notebookSpreadVC: NotebookSpreadViewController
        
        var body: some View {
            HStack {
                
                Button("Undo") {
                    notebookSpreadVC.undo()
                }
                
                Button("Redo") {
                    notebookSpreadVC.redo()
                }
                
               Button("Add Page") {
                   notebookSpreadVC.addNewPagePair()
               }
                
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
        }
    }}
