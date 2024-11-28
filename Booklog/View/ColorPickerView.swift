import SwiftUI
import UIKit

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
