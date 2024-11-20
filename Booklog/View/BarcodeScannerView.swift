import SwiftUI
@preconcurrency import Vision
@preconcurrency import VisionKit

struct BarcodeScannerView: UIViewControllerRepresentable {
    private let onRecognize: (RecognizedItem.Barcode) -> Void
    private let symbologies: [VNBarcodeSymbology]

    init(symbologies: [VNBarcodeSymbology] = [.ean13], onRecognize: @escaping (RecognizedItem.Barcode) -> Void) {
        self.onRecognize = onRecognize
        self.symbologies = symbologies
    }

    func makeUIViewController(context: Context) -> some UIViewController {
        let viewController = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: symbologies)],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isHighlightingEnabled: true
        )
        viewController.delegate = context.coordinator

        try? viewController.startScanning()
        return viewController
    }

    func updateUIViewController(_: UIViewControllerType, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let parent: BarcodeScannerView

        fileprivate init(parent: BarcodeScannerView) {
            self.parent = parent
        }

        func dataScanner(_: DataScannerViewController, didAdd _: [RecognizedItem], allItems: [RecognizedItem]) {
            guard let item = allItems.first else { return }
            switch item {
            case let .barcode(recognizedCode):
                parent.onRecognize(recognizedCode)
            default:
                break
            }
        }
    }
}
