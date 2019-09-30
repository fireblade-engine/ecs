//
//  SceneGraphTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 30.09.19.
//

import XCTest
import FirebladeECS

class SceneGraphTests: XCTestCase {

    var nexus: Nexus!
    
    override func setUp() {
        super.setUp()
        nexus = Nexus()
    }

    override func tearDown() {
        super.tearDown()
        nexus = nil
    }

    func testParent() {
        let nttParrent = nexus.createEntity(with: Position(x: 1, y: 1))
    
        let nttChild1 = nexus.createEntity(with: Position(x: 2, y: 2))
        let nttChild2 = nexus.createEntity(with: Position(x: 3, y: 3))
    
        nttParrent.addChild(nttChild1)
        nttParrent.removeChild(nttChild1)
        nttParrent.addChild(nttChild1)
        
        let family = nexus.family(requires: Position.self)
        
        
        family
            .descendRelatives.forEach { (parent: Position, child: Position) in
                
        }
        
        let family2 = nexus.family(requiresAll: Position.self, Name.self)
        
        family2
            .descendRelatives
            .forEach { (parent, child) in
                let (pPos, pName) = parent
                let (cPos, cName) = child
                
                
            }
        
    }

}
