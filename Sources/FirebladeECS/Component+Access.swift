//
//  Component+Access.swift
//
//
//  Created by Christian Treffs on 25.06.19.
//

#if swift(>=5.1)
@dynamicMemberLookup
public struct ReadableOnly<Comp> where Comp: Component {
    @usableFromInline let component: Comp

    public init(_ component: Comp) {
        self.component = component
    }

    @inlinable public subscript<C>(dynamicMember keyPath: KeyPath<Comp, C>) -> C {
        return component[keyPath: keyPath]
    }
}

@dynamicMemberLookup
public struct Writable<Comp> where Comp: Component {
    @usableFromInline let component: Comp

    public init(_ component: Comp) {
        self.component = component
    }

    @inlinable public subscript<C>(dynamicMember keyPath: ReferenceWritableKeyPath<Comp, C>) -> C {
        nonmutating get { return component[keyPath: keyPath] }
        nonmutating set { component[keyPath: keyPath] = newValue }
    }
}
#endif
