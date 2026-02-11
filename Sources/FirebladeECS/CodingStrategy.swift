//
//  CodingStrategy.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 05.08.20.
//

public protocol CodingStrategy: Sendable {
    func codingKey<C: Component>(for componentType: C.Type) -> DynamicCodingKey
}

public struct DynamicCodingKey: CodingKey, Sendable {
    public var intValue: Int?
    public var stringValue: String

    public init?(intValue: Int) {
        self.intValue = intValue; stringValue = "\(intValue)"
    }

    public init?(stringValue: String) {
        self.stringValue = stringValue
    }
}
