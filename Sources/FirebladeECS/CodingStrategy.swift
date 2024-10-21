//
//  CodingStrategy.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 05.08.20.
//

public protocol CodingStrategy: Codable {
    func codingKey<C>(for componentType: C.Type) -> DynamicCodingKey where C: Component
}

public struct DynamicCodingKey: CodingKey {
    public var intValue: Int?
    public var stringValue: String

    public init?(intValue: Int) { self.intValue = intValue; stringValue = "\(intValue)" }
    public init?(stringValue: String) { self.stringValue = stringValue }
}
