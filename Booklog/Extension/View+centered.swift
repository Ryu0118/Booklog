import SwiftUI

extension View {
    func centered(_ stackType: CenteredModifier.StackType) -> some View {
        modifier(CenteredModifier(stackType: stackType))
    }
}

struct CenteredModifier: ViewModifier {
    enum StackType {
        case vertical, horizontal
    }

    let stackType: StackType

    func body(content: Content) -> some View {
        switch stackType {
        case .vertical:
            VStack {
                Spacer()
                content
                Spacer()
            }
        case .horizontal:
            HStack {
                Spacer()
                content
                Spacer()
            }
        }
    }
}
