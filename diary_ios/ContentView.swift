import SwiftUI

@available(iOS 16.0, *)
struct ContentView: View {
    var body: some View {
        NotebookViewContainer()
            .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    ContentView()
}