//
//  Foundation+Extensions.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 22.07.20.
//

#if canImport(Foundation) && canImport(CoreFoundation)
import class Foundation.JSONEncoder
import class Foundation.JSONDecoder

import class Foundation.PropertyListEncoder
import class Foundation.PropertyListDecoder

extension JSONEncoder: TopLevelEncoder { }
extension JSONDecoder: TopLevelDecoder { }

extension PropertyListEncoder: TopLevelEncoder { }
extension PropertyListDecoder: TopLevelDecoder { }
#endif
