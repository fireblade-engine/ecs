// swiftlint:disable all
// swiftformat:disable all
//
// GENERATED FILE, DO NOT EDIT.
// Regenerate with Scripts/generate-read-write-api.sh and commit the result.
//

extension Entity {
    /// Changes 1 component type of this entity in place, reading 0 component types.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    /// - Returns: `false` if this entity is destroyed or lacks one of the components; `body` is not called then.
    @discardableResult
    public func components<W1: Component>(
        writing wType1: W1.Type,
        _ body: (inout W1) throws -> Void
    ) rethrows -> Bool {
        guard has(W1.self) else {
            return reportMissingForAccess()
        }
        try modify(W1.self) { (write1: inout W1) in
            try body(&write1)
        }
        return true
    }

    /// Changes 2 component types of this entity in place, reading 0 component types.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    /// - Returns: `false` if this entity is destroyed or lacks one of the components; `body` is not called then.
    @discardableResult
    public func components<W1: Component, W2: Component>(
        writing wType1: W1.Type,
        _ wType2: W2.Type,
        _ body: (inout W1, inout W2) throws -> Void
    ) rethrows -> Bool {
        guard has(W1.self), has(W2.self) else {
            return reportMissingForAccess()
        }
        try modify(W1.self) { (write1: inout W1) in
            try modify(W2.self) { (write2: inout W2) in
                try body(&write1, &write2)
            }
        }
        return true
    }

    /// Changes 3 component types of this entity in place, reading 0 component types.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    /// - Returns: `false` if this entity is destroyed or lacks one of the components; `body` is not called then.
    @discardableResult
    public func components<W1: Component, W2: Component, W3: Component>(
        writing wType1: W1.Type,
        _ wType2: W2.Type,
        _ wType3: W3.Type,
        _ body: (inout W1, inout W2, inout W3) throws -> Void
    ) rethrows -> Bool {
        guard has(W1.self), has(W2.self), has(W3.self) else {
            return reportMissingForAccess()
        }
        try modify(W1.self) { (write1: inout W1) in
            try modify(W2.self) { (write2: inout W2) in
                try modify(W3.self) { (write3: inout W3) in
                    try body(&write1, &write2, &write3)
                }
            }
        }
        return true
    }

    /// Changes 4 component types of this entity in place, reading 0 component types.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    /// - Returns: `false` if this entity is destroyed or lacks one of the components; `body` is not called then.
    @discardableResult
    public func components<W1: Component, W2: Component, W3: Component, W4: Component>(
        writing wType1: W1.Type,
        _ wType2: W2.Type,
        _ wType3: W3.Type,
        _ wType4: W4.Type,
        _ body: (inout W1, inout W2, inout W3, inout W4) throws -> Void
    ) rethrows -> Bool {
        guard has(W1.self), has(W2.self), has(W3.self), has(W4.self) else {
            return reportMissingForAccess()
        }
        try modify(W1.self) { (write1: inout W1) in
            try modify(W2.self) { (write2: inout W2) in
                try modify(W3.self) { (write3: inout W3) in
                    try modify(W4.self) { (write4: inout W4) in
                        try body(&write1, &write2, &write3, &write4)
                    }
                }
            }
        }
        return true
    }

    /// Changes 0 component types of this entity in place, reading 1 component type.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    /// - Returns: `false` if this entity is destroyed or lacks one of the components; `body` is not called then.
    @discardableResult
    public func components<R1: Component>(
        _ rType1: R1.Type,
        _ body: (R1) throws -> Void
    ) rethrows -> Bool {
        guard has(R1.self) else {
            return reportMissingForAccess()
        }
        let read1 = get(R1.self).unsafelyUnwrapped
        try body(read1)
        return true
    }

    /// Changes components of this entity in place, reading others.
    ///
    /// The read components are passed as copies, the written ones are changed in place in the nexus (see
    /// ``modify(_:_:)``): `body` receives the read components first, then the written ones as `inout`.
    /// Nothing runs if the entity lacks one of the components. A ``ComponentModified`` event is delivered for each
    /// written component. The written types must differ from each other, else the access traps. Overloads exist for
    /// 0 to 4 read and 0 to 4 written types, and a parameter pack overload covers more.
    ///
    /// ```swift
    /// entity.components(Velocity.self, writing: Position.self) { velocity, position in
    ///     position.x += velocity.dx
    /// }
    /// ```
    /// - Returns: `false` if this entity is destroyed or lacks one of the components; `body` is not called then.
    @discardableResult
    public func components<R1: Component, W1: Component>(
        _ rType1: R1.Type,
        writing wType1: W1.Type,
        _ body: (R1, inout W1) throws -> Void
    ) rethrows -> Bool {
        guard has(R1.self), has(W1.self) else {
            return reportMissingForAccess()
        }
        let read1 = get(R1.self).unsafelyUnwrapped
        try modify(W1.self) { (write1: inout W1) in
            try body(read1, &write1)
        }
        return true
    }

    /// Changes 2 component types of this entity in place, reading 1 component type.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    /// - Returns: `false` if this entity is destroyed or lacks one of the components; `body` is not called then.
    @discardableResult
    public func components<R1: Component, W1: Component, W2: Component>(
        _ rType1: R1.Type,
        writing wType1: W1.Type,
        _ wType2: W2.Type,
        _ body: (R1, inout W1, inout W2) throws -> Void
    ) rethrows -> Bool {
        guard has(R1.self), has(W1.self), has(W2.self) else {
            return reportMissingForAccess()
        }
        let read1 = get(R1.self).unsafelyUnwrapped
        try modify(W1.self) { (write1: inout W1) in
            try modify(W2.self) { (write2: inout W2) in
                try body(read1, &write1, &write2)
            }
        }
        return true
    }

    /// Changes 3 component types of this entity in place, reading 1 component type.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    /// - Returns: `false` if this entity is destroyed or lacks one of the components; `body` is not called then.
    @discardableResult
    public func components<R1: Component, W1: Component, W2: Component, W3: Component>(
        _ rType1: R1.Type,
        writing wType1: W1.Type,
        _ wType2: W2.Type,
        _ wType3: W3.Type,
        _ body: (R1, inout W1, inout W2, inout W3) throws -> Void
    ) rethrows -> Bool {
        guard has(R1.self), has(W1.self), has(W2.self), has(W3.self) else {
            return reportMissingForAccess()
        }
        let read1 = get(R1.self).unsafelyUnwrapped
        try modify(W1.self) { (write1: inout W1) in
            try modify(W2.self) { (write2: inout W2) in
                try modify(W3.self) { (write3: inout W3) in
                    try body(read1, &write1, &write2, &write3)
                }
            }
        }
        return true
    }

    /// Changes 4 component types of this entity in place, reading 1 component type.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    /// - Returns: `false` if this entity is destroyed or lacks one of the components; `body` is not called then.
    @discardableResult
    public func components<R1: Component, W1: Component, W2: Component, W3: Component, W4: Component>(
        _ rType1: R1.Type,
        writing wType1: W1.Type,
        _ wType2: W2.Type,
        _ wType3: W3.Type,
        _ wType4: W4.Type,
        _ body: (R1, inout W1, inout W2, inout W3, inout W4) throws -> Void
    ) rethrows -> Bool {
        guard has(R1.self), has(W1.self), has(W2.self), has(W3.self), has(W4.self) else {
            return reportMissingForAccess()
        }
        let read1 = get(R1.self).unsafelyUnwrapped
        try modify(W1.self) { (write1: inout W1) in
            try modify(W2.self) { (write2: inout W2) in
                try modify(W3.self) { (write3: inout W3) in
                    try modify(W4.self) { (write4: inout W4) in
                        try body(read1, &write1, &write2, &write3, &write4)
                    }
                }
            }
        }
        return true
    }

    /// Changes 0 component types of this entity in place, reading 2 component types.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    /// - Returns: `false` if this entity is destroyed or lacks one of the components; `body` is not called then.
    @discardableResult
    public func components<R1: Component, R2: Component>(
        _ rType1: R1.Type,
        _ rType2: R2.Type,
        _ body: (R1, R2) throws -> Void
    ) rethrows -> Bool {
        guard has(R1.self), has(R2.self) else {
            return reportMissingForAccess()
        }
        let read1 = get(R1.self).unsafelyUnwrapped
        let read2 = get(R2.self).unsafelyUnwrapped
        try body(read1, read2)
        return true
    }

    /// Changes 1 component type of this entity in place, reading 2 component types.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    /// - Returns: `false` if this entity is destroyed or lacks one of the components; `body` is not called then.
    @discardableResult
    public func components<R1: Component, R2: Component, W1: Component>(
        _ rType1: R1.Type,
        _ rType2: R2.Type,
        writing wType1: W1.Type,
        _ body: (R1, R2, inout W1) throws -> Void
    ) rethrows -> Bool {
        guard has(R1.self), has(R2.self), has(W1.self) else {
            return reportMissingForAccess()
        }
        let read1 = get(R1.self).unsafelyUnwrapped
        let read2 = get(R2.self).unsafelyUnwrapped
        try modify(W1.self) { (write1: inout W1) in
            try body(read1, read2, &write1)
        }
        return true
    }

    /// Changes 2 component types of this entity in place, reading 2 component types.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    /// - Returns: `false` if this entity is destroyed or lacks one of the components; `body` is not called then.
    @discardableResult
    public func components<R1: Component, R2: Component, W1: Component, W2: Component>(
        _ rType1: R1.Type,
        _ rType2: R2.Type,
        writing wType1: W1.Type,
        _ wType2: W2.Type,
        _ body: (R1, R2, inout W1, inout W2) throws -> Void
    ) rethrows -> Bool {
        guard has(R1.self), has(R2.self), has(W1.self), has(W2.self) else {
            return reportMissingForAccess()
        }
        let read1 = get(R1.self).unsafelyUnwrapped
        let read2 = get(R2.self).unsafelyUnwrapped
        try modify(W1.self) { (write1: inout W1) in
            try modify(W2.self) { (write2: inout W2) in
                try body(read1, read2, &write1, &write2)
            }
        }
        return true
    }

    /// Changes 3 component types of this entity in place, reading 2 component types.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    /// - Returns: `false` if this entity is destroyed or lacks one of the components; `body` is not called then.
    @discardableResult
    public func components<R1: Component, R2: Component, W1: Component, W2: Component, W3: Component>(
        _ rType1: R1.Type,
        _ rType2: R2.Type,
        writing wType1: W1.Type,
        _ wType2: W2.Type,
        _ wType3: W3.Type,
        _ body: (R1, R2, inout W1, inout W2, inout W3) throws -> Void
    ) rethrows -> Bool {
        guard has(R1.self), has(R2.self), has(W1.self), has(W2.self), has(W3.self) else {
            return reportMissingForAccess()
        }
        let read1 = get(R1.self).unsafelyUnwrapped
        let read2 = get(R2.self).unsafelyUnwrapped
        try modify(W1.self) { (write1: inout W1) in
            try modify(W2.self) { (write2: inout W2) in
                try modify(W3.self) { (write3: inout W3) in
                    try body(read1, read2, &write1, &write2, &write3)
                }
            }
        }
        return true
    }

    /// Changes 4 component types of this entity in place, reading 2 component types.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    /// - Returns: `false` if this entity is destroyed or lacks one of the components; `body` is not called then.
    @discardableResult
    public func components<R1: Component, R2: Component, W1: Component, W2: Component, W3: Component, W4: Component>(
        _ rType1: R1.Type,
        _ rType2: R2.Type,
        writing wType1: W1.Type,
        _ wType2: W2.Type,
        _ wType3: W3.Type,
        _ wType4: W4.Type,
        _ body: (R1, R2, inout W1, inout W2, inout W3, inout W4) throws -> Void
    ) rethrows -> Bool {
        guard has(R1.self), has(R2.self), has(W1.self), has(W2.self), has(W3.self), has(W4.self) else {
            return reportMissingForAccess()
        }
        let read1 = get(R1.self).unsafelyUnwrapped
        let read2 = get(R2.self).unsafelyUnwrapped
        try modify(W1.self) { (write1: inout W1) in
            try modify(W2.self) { (write2: inout W2) in
                try modify(W3.self) { (write3: inout W3) in
                    try modify(W4.self) { (write4: inout W4) in
                        try body(read1, read2, &write1, &write2, &write3, &write4)
                    }
                }
            }
        }
        return true
    }

    /// Changes 0 component types of this entity in place, reading 3 component types.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    /// - Returns: `false` if this entity is destroyed or lacks one of the components; `body` is not called then.
    @discardableResult
    public func components<R1: Component, R2: Component, R3: Component>(
        _ rType1: R1.Type,
        _ rType2: R2.Type,
        _ rType3: R3.Type,
        _ body: (R1, R2, R3) throws -> Void
    ) rethrows -> Bool {
        guard has(R1.self), has(R2.self), has(R3.self) else {
            return reportMissingForAccess()
        }
        let read1 = get(R1.self).unsafelyUnwrapped
        let read2 = get(R2.self).unsafelyUnwrapped
        let read3 = get(R3.self).unsafelyUnwrapped
        try body(read1, read2, read3)
        return true
    }

    /// Changes 1 component type of this entity in place, reading 3 component types.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    /// - Returns: `false` if this entity is destroyed or lacks one of the components; `body` is not called then.
    @discardableResult
    public func components<R1: Component, R2: Component, R3: Component, W1: Component>(
        _ rType1: R1.Type,
        _ rType2: R2.Type,
        _ rType3: R3.Type,
        writing wType1: W1.Type,
        _ body: (R1, R2, R3, inout W1) throws -> Void
    ) rethrows -> Bool {
        guard has(R1.self), has(R2.self), has(R3.self), has(W1.self) else {
            return reportMissingForAccess()
        }
        let read1 = get(R1.self).unsafelyUnwrapped
        let read2 = get(R2.self).unsafelyUnwrapped
        let read3 = get(R3.self).unsafelyUnwrapped
        try modify(W1.self) { (write1: inout W1) in
            try body(read1, read2, read3, &write1)
        }
        return true
    }

    /// Changes 2 component types of this entity in place, reading 3 component types.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    /// - Returns: `false` if this entity is destroyed or lacks one of the components; `body` is not called then.
    @discardableResult
    public func components<R1: Component, R2: Component, R3: Component, W1: Component, W2: Component>(
        _ rType1: R1.Type,
        _ rType2: R2.Type,
        _ rType3: R3.Type,
        writing wType1: W1.Type,
        _ wType2: W2.Type,
        _ body: (R1, R2, R3, inout W1, inout W2) throws -> Void
    ) rethrows -> Bool {
        guard has(R1.self), has(R2.self), has(R3.self), has(W1.self), has(W2.self) else {
            return reportMissingForAccess()
        }
        let read1 = get(R1.self).unsafelyUnwrapped
        let read2 = get(R2.self).unsafelyUnwrapped
        let read3 = get(R3.self).unsafelyUnwrapped
        try modify(W1.self) { (write1: inout W1) in
            try modify(W2.self) { (write2: inout W2) in
                try body(read1, read2, read3, &write1, &write2)
            }
        }
        return true
    }

    /// Changes 3 component types of this entity in place, reading 3 component types.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    /// - Returns: `false` if this entity is destroyed or lacks one of the components; `body` is not called then.
    @discardableResult
    public func components<R1: Component, R2: Component, R3: Component, W1: Component, W2: Component, W3: Component>(
        _ rType1: R1.Type,
        _ rType2: R2.Type,
        _ rType3: R3.Type,
        writing wType1: W1.Type,
        _ wType2: W2.Type,
        _ wType3: W3.Type,
        _ body: (R1, R2, R3, inout W1, inout W2, inout W3) throws -> Void
    ) rethrows -> Bool {
        guard has(R1.self), has(R2.self), has(R3.self), has(W1.self), has(W2.self), has(W3.self) else {
            return reportMissingForAccess()
        }
        let read1 = get(R1.self).unsafelyUnwrapped
        let read2 = get(R2.self).unsafelyUnwrapped
        let read3 = get(R3.self).unsafelyUnwrapped
        try modify(W1.self) { (write1: inout W1) in
            try modify(W2.self) { (write2: inout W2) in
                try modify(W3.self) { (write3: inout W3) in
                    try body(read1, read2, read3, &write1, &write2, &write3)
                }
            }
        }
        return true
    }

    /// Changes 4 component types of this entity in place, reading 3 component types.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    /// - Returns: `false` if this entity is destroyed or lacks one of the components; `body` is not called then.
    @discardableResult
    public func components<R1: Component, R2: Component, R3: Component, W1: Component, W2: Component, W3: Component, W4: Component>(
        _ rType1: R1.Type,
        _ rType2: R2.Type,
        _ rType3: R3.Type,
        writing wType1: W1.Type,
        _ wType2: W2.Type,
        _ wType3: W3.Type,
        _ wType4: W4.Type,
        _ body: (R1, R2, R3, inout W1, inout W2, inout W3, inout W4) throws -> Void
    ) rethrows -> Bool {
        guard has(R1.self), has(R2.self), has(R3.self), has(W1.self), has(W2.self), has(W3.self), has(W4.self) else {
            return reportMissingForAccess()
        }
        let read1 = get(R1.self).unsafelyUnwrapped
        let read2 = get(R2.self).unsafelyUnwrapped
        let read3 = get(R3.self).unsafelyUnwrapped
        try modify(W1.self) { (write1: inout W1) in
            try modify(W2.self) { (write2: inout W2) in
                try modify(W3.self) { (write3: inout W3) in
                    try modify(W4.self) { (write4: inout W4) in
                        try body(read1, read2, read3, &write1, &write2, &write3, &write4)
                    }
                }
            }
        }
        return true
    }

    /// Changes 0 component types of this entity in place, reading 4 component types.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    /// - Returns: `false` if this entity is destroyed or lacks one of the components; `body` is not called then.
    @discardableResult
    public func components<R1: Component, R2: Component, R3: Component, R4: Component>(
        _ rType1: R1.Type,
        _ rType2: R2.Type,
        _ rType3: R3.Type,
        _ rType4: R4.Type,
        _ body: (R1, R2, R3, R4) throws -> Void
    ) rethrows -> Bool {
        guard has(R1.self), has(R2.self), has(R3.self), has(R4.self) else {
            return reportMissingForAccess()
        }
        let read1 = get(R1.self).unsafelyUnwrapped
        let read2 = get(R2.self).unsafelyUnwrapped
        let read3 = get(R3.self).unsafelyUnwrapped
        let read4 = get(R4.self).unsafelyUnwrapped
        try body(read1, read2, read3, read4)
        return true
    }

    /// Changes 1 component type of this entity in place, reading 4 component types.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    /// - Returns: `false` if this entity is destroyed or lacks one of the components; `body` is not called then.
    @discardableResult
    public func components<R1: Component, R2: Component, R3: Component, R4: Component, W1: Component>(
        _ rType1: R1.Type,
        _ rType2: R2.Type,
        _ rType3: R3.Type,
        _ rType4: R4.Type,
        writing wType1: W1.Type,
        _ body: (R1, R2, R3, R4, inout W1) throws -> Void
    ) rethrows -> Bool {
        guard has(R1.self), has(R2.self), has(R3.self), has(R4.self), has(W1.self) else {
            return reportMissingForAccess()
        }
        let read1 = get(R1.self).unsafelyUnwrapped
        let read2 = get(R2.self).unsafelyUnwrapped
        let read3 = get(R3.self).unsafelyUnwrapped
        let read4 = get(R4.self).unsafelyUnwrapped
        try modify(W1.self) { (write1: inout W1) in
            try body(read1, read2, read3, read4, &write1)
        }
        return true
    }

    /// Changes 2 component types of this entity in place, reading 4 component types.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    /// - Returns: `false` if this entity is destroyed or lacks one of the components; `body` is not called then.
    @discardableResult
    public func components<R1: Component, R2: Component, R3: Component, R4: Component, W1: Component, W2: Component>(
        _ rType1: R1.Type,
        _ rType2: R2.Type,
        _ rType3: R3.Type,
        _ rType4: R4.Type,
        writing wType1: W1.Type,
        _ wType2: W2.Type,
        _ body: (R1, R2, R3, R4, inout W1, inout W2) throws -> Void
    ) rethrows -> Bool {
        guard has(R1.self), has(R2.self), has(R3.self), has(R4.self), has(W1.self), has(W2.self) else {
            return reportMissingForAccess()
        }
        let read1 = get(R1.self).unsafelyUnwrapped
        let read2 = get(R2.self).unsafelyUnwrapped
        let read3 = get(R3.self).unsafelyUnwrapped
        let read4 = get(R4.self).unsafelyUnwrapped
        try modify(W1.self) { (write1: inout W1) in
            try modify(W2.self) { (write2: inout W2) in
                try body(read1, read2, read3, read4, &write1, &write2)
            }
        }
        return true
    }

    /// Changes 3 component types of this entity in place, reading 4 component types.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    /// - Returns: `false` if this entity is destroyed or lacks one of the components; `body` is not called then.
    @discardableResult
    public func components<R1: Component, R2: Component, R3: Component, R4: Component, W1: Component, W2: Component, W3: Component>(
        _ rType1: R1.Type,
        _ rType2: R2.Type,
        _ rType3: R3.Type,
        _ rType4: R4.Type,
        writing wType1: W1.Type,
        _ wType2: W2.Type,
        _ wType3: W3.Type,
        _ body: (R1, R2, R3, R4, inout W1, inout W2, inout W3) throws -> Void
    ) rethrows -> Bool {
        guard has(R1.self), has(R2.self), has(R3.self), has(R4.self), has(W1.self), has(W2.self), has(W3.self) else {
            return reportMissingForAccess()
        }
        let read1 = get(R1.self).unsafelyUnwrapped
        let read2 = get(R2.self).unsafelyUnwrapped
        let read3 = get(R3.self).unsafelyUnwrapped
        let read4 = get(R4.self).unsafelyUnwrapped
        try modify(W1.self) { (write1: inout W1) in
            try modify(W2.self) { (write2: inout W2) in
                try modify(W3.self) { (write3: inout W3) in
                    try body(read1, read2, read3, read4, &write1, &write2, &write3)
                }
            }
        }
        return true
    }

    /// Changes 4 component types of this entity in place, reading 4 component types.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    /// - Returns: `false` if this entity is destroyed or lacks one of the components; `body` is not called then.
    @discardableResult
    public func components<R1: Component, R2: Component, R3: Component, R4: Component, W1: Component, W2: Component, W3: Component, W4: Component>(
        _ rType1: R1.Type,
        _ rType2: R2.Type,
        _ rType3: R3.Type,
        _ rType4: R4.Type,
        writing wType1: W1.Type,
        _ wType2: W2.Type,
        _ wType3: W3.Type,
        _ wType4: W4.Type,
        _ body: (R1, R2, R3, R4, inout W1, inout W2, inout W3, inout W4) throws -> Void
    ) rethrows -> Bool {
        guard has(R1.self), has(R2.self), has(R3.self), has(R4.self), has(W1.self), has(W2.self), has(W3.self), has(W4.self) else {
            return reportMissingForAccess()
        }
        let read1 = get(R1.self).unsafelyUnwrapped
        let read2 = get(R2.self).unsafelyUnwrapped
        let read3 = get(R3.self).unsafelyUnwrapped
        let read4 = get(R4.self).unsafelyUnwrapped
        try modify(W1.self) { (write1: inout W1) in
            try modify(W2.self) { (write2: inout W2) in
                try modify(W3.self) { (write3: inout W3) in
                    try modify(W4.self) { (write4: inout W4) in
                        try body(read1, read2, read3, read4, &write1, &write2, &write3, &write4)
                    }
                }
            }
        }
        return true
    }
}
