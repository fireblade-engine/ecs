//
//  Foundation+Extensions.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 22.07.20.
//

#if canImport(Foundation)
import Foundation
#endif
#if canImport(CoreFoundation)
import CoreFoundation
#endif
#if canImport(SwiftFoundation)
import SwiftFoundation
#endif

#if canImport(Foundation) || canImport(CoreFoundation) || canImport(SwiftFoundation)
extension JSONEncoder: TopLevelEncoder { }
extension JSONDecoder: TopLevelDecoder { }

extension PropertyListEncoder: TopLevelEncoder { }
extension PropertyListDecoder: TopLevelDecoder { }
#endif
