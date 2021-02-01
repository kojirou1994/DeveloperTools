import SwiftUI

struct TextView: NSViewControllerRepresentable {
    typealias NSViewControllerType = TextViewController
    @Binding var text: String
    let editable: Bool

    func makeCoordinator() -> TextView.Coordinator {
        .init(text: $text)
    }

    func makeNSViewController(context: NSViewControllerRepresentableContext<TextView>) -> TextViewController {
        let c = TextViewController()
        c.coordicator = context.coordinator
        return c
    }

    func updateNSViewController(_ nsViewController: TextViewController, context: NSViewControllerRepresentableContext<TextView>) {
        print(#function)
        nsViewController.textView.isEditable = editable
        nsViewController.textView?.string = text
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        @Binding var text: String

        weak var textView: NSTextView?

        init(text: Binding<String>) {
            _text = text
        }

        func textDidChange(_ notification: Notification) {
//            print(#function)
            text = textView!.string
        }
    }
}

class TextViewController: NSViewController {
    @IBOutlet var textView: NSTextView!

    weak var coordicator: TextView.Coordinator?

    override func viewDidLoad() {
        super.viewDidLoad()

        textView.delegate = coordicator
        coordicator?.textView = textView
    }
}
