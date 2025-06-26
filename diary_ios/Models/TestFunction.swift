import UIKit

func addTestBorder(for view: UIView, color: UIColor = .red, width: CGFloat = 2.0) {
    view.layer.borderColor = color.cgColor
    view.layer.borderWidth = width
}


func printLifeCycleInfo(context: String, for view: UIView){
    print("⚙️ \(context)")
    print("   📌 view.frame: \(formatRect(view.frame))")
    print("   📌 view.bounds: \(formatRect(view.bounds))")
}