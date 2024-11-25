import UIKit
import SwiftUI

extension UIColor {
    func hexString(alpha: Bool = false) -> String {
        Color(uiColor: self).hexString(alpha: alpha)
    }
}
