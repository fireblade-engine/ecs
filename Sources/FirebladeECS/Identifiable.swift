//
//  Identifiable.swift
//
//
//  Created by Christian Treffs on 05.10.19.
//

//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
#if swift(<5.1)
/// A class of types whose instances hold the value of an entity with stable identity.
public protocol Identifiable {
    /// A type representing the stable identity of the entity associated with `self`.
    associatedtype ID: Hashable

    /// The stable identity of the entity associated with `self`.
    var id: ID { get }
}

extension Identifiable where Self: AnyObject {
    public var id: ObjectIdentifier {
        return ObjectIdentifier(self)
    }
}
#endif
