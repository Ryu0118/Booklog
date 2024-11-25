import SwiftUI
import UIKit

struct ColorPickerView: UIViewControllerRepresentable {
    @Environment(\.dismiss) fileprivate var dismiss
    let onColorSelected: (UIColor) -> Void
    private let selectedColor: UIColor

    init(selectedColor: Color, onColorSelected: @escaping (UIColor) -> Void) {
        self.onColorSelected = onColorSelected
        self.selectedColor = UIColor(selectedColor)
    }

    func makeCoordinator() -> Coodinator {
        Coodinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIColorPickerViewController {
        let picker = UIColorPickerViewController()
        picker.delegate = context.coordinator
//        picker.modalPresentationStyle = .formSheet
//        picker.
        picker.supportsAlpha = false
        picker.selectedColor = selectedColor
        picker.modalPresentationStyle = .popover
        return picker
    }

    func updateUIViewController(_: UIColorPickerViewController, context _: Context) {}

    final class Coodinator: NSObject, UIColorPickerViewControllerDelegate {
        private let parent: ColorPickerView

        fileprivate init(parent: ColorPickerView) {
            self.parent = parent
        }

        func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
            parent.onColorSelected(viewController.selectedColor)
            parent.dismiss()
        }

        func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect _: UIColor, continuously _: Bool) {
            parent.onColorSelected(viewController.selectedColor)
        }
    }
}

@MainActor
struct ColorPickerWellView: UIViewRepresentable {
    private var selectedColor: Color
    let onColorPicked: (UIColor) -> Void

    init(selectedColor: Color, onColorPicked: @escaping (UIColor) -> Void) {
        self.selectedColor = selectedColor
        self.onColorPicked = onColorPicked
    }

    func makeUIView(context: Context) -> UIView {
        let colorWell = UIColorWell(frame: CGRect(x: 0, y: 0, width: 100, height: 50))

        colorWell.title = "Select Color"
        colorWell.selectedColor = UIColor(selectedColor)
        colorWell.addTarget(context.coordinator, action: #selector(context.coordinator.colorWellChanged), for: .valueChanged)

        return colorWell
    }
    
    func updateUIView(_: UIView, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onColorPicked: self.onColorPicked
        )
    }

    final class Coordinator: NSObject {
        private let onColorPicked: (UIColor) -> Void

        init(onColorPicked: @escaping (UIColor) -> Void) {
            self.onColorPicked = onColorPicked
        }

        @MainActor @objc func colorWellChanged(_ sender: UIColorWell) {
            if let color = sender.selectedColor {
                self.onColorPicked(color)
            }
        }
    }
}
