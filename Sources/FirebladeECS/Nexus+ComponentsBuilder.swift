//
//  Nexus+ComponentsBuilder.swift
//
//
//  Created by Christian Treffs on 30.07.20.
//

@_functionBuilder
public enum ComponentsBuilderPreview { }
public typealias ComponentsBuilder = ComponentsBuilderPreview

extension ComponentsBuilder {
    public static func buildBlock(_ components: Component...) -> [Component] {
        components
    }

    public struct Context {
        /// The index of the newly created entity.
        ///
        /// This is **NOT** equal to the entity identifier.
        public let index: Int
    }
}

extension Nexus {
    /// Create an entity assigning one component.
    ///
    /// Usage:
    /// ```
    /// let newEntity = nexus.createEntity {
    ///    Position(x: 1, y: 2)
    /// }
    /// ```
    /// - Parameter builder: The component builder.
    /// - Returns: The newly created entity with the provided component assigned.
    @discardableResult
    public func createEntity(@ComponentsBuilder using builder: () -> Component) -> Entity {
        self.createEntity(with: builder())
    }

    /// Create an entity assigning multiple components.
    ///
    /// Usage:
    /// ```
    /// let newEntity = nexus.createEntity {
    ///    Position(x: 1, y: 2)
    ///    Name(name: "Some name")
    /// }
    ///
    /// // -- or --
    ///
    /// let compA = Position(x: 1, y: 2)
    /// let compB = Name(name: "Some name")
    ///
    /// let newEntity = nexus.createEntity { compA; compB }
    /// ```
    /// - Parameter builder: The component builder.
    /// - Returns: The newly created entity with the provided components assigned.
    @discardableResult
    public func createEntity(@ComponentsBuilder using builder: () -> [Component]) -> Entity {
        self.createEntity(with: builder())
    }

    /// Create multiple entities assigning one component each.
    ///
    /// Usage:
    /// ```
    /// let newEntities = nexus.createEntities(count: 100) { ctx in
    ///    Velocity(a: Float(ctx.index))
    /// }
    /// ```
    /// - Parameters:
    ///   - count: The count of entities to create.
    ///   - builder: The component builder providing context.
    /// - Returns: The newly created entities with the provided component assigned.
    @discardableResult
    public func createEntities(count: Int, @ComponentsBuilder using builder: (ComponentsBuilder.Context) -> Component) -> [Entity] {
        (0..<count).map { self.createEntity(with: builder(ComponentsBuilder.Context(index: $0))) }
    }

    /// Create multiple entities assigning multiple components each.
    ///
    /// Usage:
    /// ```
    /// let newEntities = nexus.createEntities(count: 100) { ctx in
    ///    Position(x: ctx.index, y: ctx.index)
    ///    Name(name: "\(ctx.index)")
    /// }
    /// ```
    /// - Parameters:
    ///   - count: The count of entities to create.
    ///   - builder: The component builder providing context.
    /// - Returns: The newly created entities with the provided components assigned.
    @discardableResult
    public func createEntities(count: Int, @ComponentsBuilder using builder: (ComponentsBuilder.Context) -> [Component]) -> [Entity] {
        (0..<count).map { self.createEntity(with: builder(ComponentsBuilder.Context(index: $0))) }
    }
}
