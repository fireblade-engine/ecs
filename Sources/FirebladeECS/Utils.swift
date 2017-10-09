//
//  Utils.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 09.10.17.
//

#if os(macOS) || os(iOS) || os(tvOS)
	import CoreFoundation
#endif

#if os(macOS) || os(iOS) || os(tvOS)

	func retainCount<T: AnyObject>(_ ref: T?) -> Int {
		let retainCount: CFIndex = CFGetRetainCount(ref)
		return retainCount
	}

#else
	func retainCount<T: AnyObject>(_ ref: T?) -> Int { return -1 }

#endif
