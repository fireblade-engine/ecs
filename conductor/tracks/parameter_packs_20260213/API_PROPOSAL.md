# API Proposal: Parameter Pack Refactoring

## Overview
This document outlines the proposed changes to the Fireblade ECS API to support Swift Parameter Packs (SE-0393). The goal is to replace the code-generated `FamilyN` types with a single, variadic `Family<each Component>` type.

## 1. Core Types

### 1.1 `Family`
The `Family` struct will be updated to use parameter packs directly, removing the need for the `FamilyRequirementsManaging` protocol (or significantly simplifying it).

**Proposed Definition:**
```swift
public struct Family<each C: Component> {
    public let nexus: Nexus
    public let traits: FamilyTraitSet

    public init(nexus: Nexus, requiresAll: repeat (each C).Type, excludesAll: [Component.Type]) {
        self.nexus = nexus
        // Implementation to extract identifiers from types
        // ...
        self.traits = FamilyTraitSet(...)
        nexus.onFamilyInit(traits: traits)
    }
    
    // ... Iterator implementation ...
}
```

### 1.2 `Nexus` Extensions
The `Nexus` methods for creating/retrieving families will be updated to use variadic generics.

**Proposed Definition:**
```swift
extension Nexus {
    public func family<each C: Component>(
        requiresAll componentTypes: repeat (each C).Type,
        excludesAll excludedComponents: Component.Type...
    ) -> Family<repeat each C> {
        Family(nexus: self, requiresAll: repeat each componentTypes, excludesAll: excludedComponents)
    }
}
```

## 2. Removals
- **`FamilyRequirementsManaging` Protocol:** This protocol acts as a bridge for the generated code. With parameter packs, the logic can likely be moved directly into `Family` or a specialized helper, making this protocol obsolete in its current form.
- **`Family1`, `Family2`, ... `FamilyN` Type Aliases:** These will be removed.
- **`Requires1`, `Requires2`, ... `RequiresN` Structs:** These will be removed.
- **`Family.generated.swift`:** The entire generated file will be deleted.
- **Sourcery Config:** `.sourcery.yml` and templates will be removed.
- **Mintfile:** Remove Sourcery dependency.

## 3. Impact on Existing Code

### 3.1 Family Creation
**Old:**
```swift
let family = nexus.family(requires: Position.self, Velocity.self)
```

**New:**
```swift
let family = nexus.family(requiresAll: Position.self, Velocity.self)
```
*Note: The API is largely compatible, but the return type changes from `Family2<Position, Velocity>` to `Family<Position, Velocity>`.*

### 3.2 Iteration
**Old:**
```swift
family.forEach { (position, velocity) in
   // position is Position, velocity is Velocity
}
```

**New:**
```swift
family.forEach { (position: Position, velocity: Velocity) in
   // position is Position, velocity is Velocity
}
```
*Note: Due to current Swift compiler limitations (crashes when wrapping variadic tuples in `Optional`), `Family` will NOT conform to `Sequence` initially to avoid any wrapper classes or allocations. Iteration will be exclusively supported via `forEach` which allows for high-performance, allocation-free iteration.*

### 3.3 Entity Creation
`Entity.assign` and `Entity.create` will also be updated to accept parameter packs, allowing for type-safe assignment of multiple components without overloads.

## 4. Migration Strategy
1.  Implement `Family<each C>`.
2.  Update `Nexus` to use the new `Family`.
3.  Remove generated code.
4.  Update tests and internal usage.
