import CoreTransferable

typealias EntityConvertibleType = Codable & Equatable & Hashable & Identifiable
protocol EntityConvertible {
    associatedtype Entity: EntityConvertibleType

    func toEntity() -> Entity
}
