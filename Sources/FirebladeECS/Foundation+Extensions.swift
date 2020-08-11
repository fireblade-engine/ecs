//
//  Foundation+Extensions.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 22.07.20.
//

#if canImport(Foundation)
import Foundation

extension JSONEncoder: TopLevelEncoder { }
extension JSONDecoder: TopLevelDecoder { }
#endif
