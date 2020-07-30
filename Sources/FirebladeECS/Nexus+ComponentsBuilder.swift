//
//  Nexus+ComponentsBuilder.swift
//
//
//  Created by Christian Treffs on 30.07.20.
//

#if swift(<5.3)
@_functionBuilder
public enum ComponentsBuilderPreview { }
public typealias ComponentsBuilder = ComponentsBuilderPreview
#else
@functionBuilder
public enum ComponentsBuilder { }
#endif

extension ComponentsBuilder {
    public static func buildBlock(_ components: Component...) -> [Component] {
        components
    }

    public struct Context {
        public let index: Int
    }
}

extension Nexus {
    @discardableResult
    public func createEntity(@ComponentsBuilder using componentBuilder: () -> Component) -> Entity {
        self.createEntity(with: componentBuilder())
    }

    @discardableResult
    public func createEntity(@ComponentsBuilder using componentBuilder: () -> [Component]) -> Entity {
        self.createEntity(with: componentBuilder())
    }

    @discardableResult
    public func createEntities(count: Int, @ComponentsBuilder using componentBuilder: (ComponentsBuilder.Context) -> Component) -> [Entity] {
        (0..<count).map { self.createEntity(with: componentBuilder(ComponentsBuilder.Context(index: $0))) }
    }

    @discardableResult
    public func createEntities(count: Int, @ComponentsBuilder using componentBuilder: (ComponentsBuilder.Context) -> [Component]) -> [Entity] {
        (0..<count).map { self.createEntity(with: componentBuilder(ComponentsBuilder.Context(index: $0))) }
    }
}
