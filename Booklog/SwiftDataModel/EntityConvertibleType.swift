import CoreTransferable

typealias EntityConvertibleType = Codable & Equatable & Hashable & Identifiable & Sendable
protocol EntityConvertible {
    associatedtype Entity: EntityConvertibleType

    func toEntity() -> Entity
}
