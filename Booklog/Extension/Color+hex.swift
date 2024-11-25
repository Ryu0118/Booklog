import SwiftUI

extension Color {
    init(hexString: String, opacity: Double = 1.0) {
        let scanner = Scanner(string: hexString)

        var color: UInt64 = 0
        if scanner.scanHexInt64(&color) {
            let red = CGFloat((color & 0xFF0000) >> 16) / 255.0
            let green = CGFloat((color & 0x00FF00) >> 8) / 255.0
            let blue = CGFloat(color & 0x0000FF) / 255.0
            self.init(red: red, green: green, blue: blue, opacity: opacity)
        } else {
            self.init(red: 0, green: 0, blue: 0, opacity: opacity)
        }
    }

    init(hexString: String, opacity: OpacityLevel) {
        self.init(hexString: hexString, opacity: opacity.rawValue)
    }

    func hexString(alpha: Bool = false) -> String {
        guard let components = cgColor?.components, components.count >= 3 else {
            return "FFFFFF"
        }

        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)

        if components.count >= 4 {
            a = Float(components[3])
        }

        return if alpha {
            String(
                format: "%02lX%02lX%02lX%02lX",
                lroundf(r * 255),
                lroundf(g * 255),
                lroundf(b * 255),
                lroundf(a * 255)
            )
        } else {
            String(
                format: "%02lX%02lX%02lX",
                lroundf(r * 255),
                lroundf(g * 255),
                lroundf(b * 255)
            )
        }
    }
}
