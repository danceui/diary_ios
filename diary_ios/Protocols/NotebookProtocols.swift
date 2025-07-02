import UIKit

protocol NotebookSpreadLayoutDelegate: AnyObject {
    func currentSpreadContentSize() -> CGSize
}

protocol NotebookZoomStateDelegate: AnyObject {
    func isNotebookZoomedIn() -> Bool
}

