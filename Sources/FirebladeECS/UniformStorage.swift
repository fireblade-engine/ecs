//
//  UniformStorage.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 14.02.19.
//

public protocol UniformStorage: class {
    associatedtype Element
    associatedtype Index

    var count: Int { get }

    @discardableResult
    func insert(_ element: Element, at index: Index) -> Bool
    func contains(_ index: Index) -> Bool
    func get(at index: Index) -> Element?
    @discardableResult
    func remove(at index: Index) -> Bool
}
