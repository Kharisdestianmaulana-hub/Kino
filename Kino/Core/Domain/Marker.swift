import Foundation

public struct Marker: Codable, Identifiable {
    public let id: UUID
    public var time: Double
    public var name: String
    public var colorHex: String
    
    public init(id: UUID = UUID(), time: Double, name: String, colorHex: String = "#FFFFFF") {
        self.id = id
        self.time = time
        self.name = name
        self.colorHex = colorHex
    }
}
