import CoreTransferable

protocol SwiftDataTransferable: Transferable {
    associatedtype CodableModel: Codable

    func toCodableModel() -> CodableModel
    static func toOriginalModel(from codableModel: CodableModel) -> Self
}

extension SwiftDataTransferable {
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .json) { model in
            try JSONEncoder().encode(model.toCodableModel())
        } importing: { data in
            let codableModel = try JSONDecoder().decode(CodableModel.self, from: data)
            return Self.toOriginalModel(from: codableModel)
        }
    }
}
