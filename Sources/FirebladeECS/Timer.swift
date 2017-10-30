//
//  Timer.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 28.10.17.
//

import Darwin.Mach.mach_time

struct Timer {
	private let numerator: UInt64
	private let denominator: UInt64
	private var startTime: UInt64 = 0
	private var stopTime: UInt64 = 0

	init() {
		var timeBaseInfo = mach_timebase_info.init(numer: 0, denom: 0 )
		let success: kern_return_t = mach_timebase_info(&timeBaseInfo)
		assert(KERN_SUCCESS == success)
		numerator = UInt64(timeBaseInfo.numer)
		denominator = UInt64(timeBaseInfo.denom)
	}

	mutating func start() {
		startTime = mach_absolute_time()
	}
	mutating func stop() {
		stopTime = mach_absolute_time()
	}
	mutating func reset() {
		startTime = 0
		stopTime = 0
	}

	var nanoSeconds: UInt64 {
		return ((stopTime - startTime) * numerator) / denominator
	}

	var microSeconds: Double {
		return Double(nanoSeconds) / 1.0e3
	}

	var milliSeconds: Double {
		return Double(nanoSeconds) / 1.0e6
	}

	var seconds: Double {
		return Double(nanoSeconds) / 1.0e9
	}
}
