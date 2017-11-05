//
//  UUID.swift
//  FirebladeECSPackageDescription
//
//  Created by Christian Treffs on 04.11.17.
//

#if os(macOS) || os(iOS) || os(tvOS)
	import Darwin.C.stdlib
#else
	// TODO: support linux and other platforms
#endif

public struct UUID {
	public static let count: Int = 16 // https://tools.ietf.org/html/rfc4122#section-4.1
	private let bytes: ContiguousArray<UInt8>

	public init(_ bytes: ContiguousArray<UInt8>) {
		assert(bytes.count == UUID.count, "An UUID must have a count of exactly \(UUID.count).")
		self.bytes = bytes
	}
	public init() {
		self.init(UUID.generateUUID())
	}
	public init(_ bytes: [UInt8]) {
		self.init(ContiguousArray(bytes))
	}
	public init?(uuidString: String) {
		guard uuidString.count == 2*UUID.count+4 else {
			// "An UUID string must have a count of exactly 36."
			return nil
		}

		var uuid: ContiguousArray<UInt8> = ContiguousArray<UInt8>(repeating: 0, count: UUID.count)
		let contiguousString: String = uuidString.split(separator: "-").joined()
		guard contiguousString.count == 2*UUID.count else {
			// An UUID string must have exactly 4 separators
			return nil
		}
		var endIdx: String.Index = contiguousString.startIndex
		for i in 0..<UUID.count {
			let startIdx: String.Index = endIdx
			endIdx = contiguousString.index(endIdx, offsetBy: 2)
			let substring: Substring = contiguousString[startIdx..<endIdx]  // take 2 characters as one byte
			guard let byte: UInt8 = UInt8(substring, radix: UUID.count) else {
				return nil
			}
			uuid[i] = byte
		}
		self.init(uuid)
	}

	private static func generateUUID() -> ContiguousArray<UInt8> {
		var uuid: ContiguousArray<UInt8> = ContiguousArray<UInt8>(repeating: 0, count: UUID.count)
		uuid.withUnsafeMutableBufferPointer { (uuidPtr: inout UnsafeMutableBufferPointer<UInt8>) -> Void in
			// TODO: use /dev/urandom
			arc4random_buf(uuidPtr.baseAddress, UUID.count) // TODO: linux
		}
		makeRFC4122compliant(uuid: &uuid)
		return uuid
	}

	private static func makeRFC4122compliant(uuid: inout ContiguousArray<UInt8>) {
		uuid[6] = (uuid[6] & 0x0F) | 0x40 // version https://tools.ietf.org/html/rfc4122#section-4.1.3
		uuid[8] = (uuid[8] & 0x3f) | 0x80 // variant https://tools.ietf.org/html/rfc4122#section-4.1.1
	}
}

extension UUID: Equatable {
	public static func == (lhs: UUID, rhs: UUID) -> Bool {
		return lhs.bytes == rhs.bytes
	}
}

extension UUID: Hashable {
	/// One-at-a-Time hash
	/// http://eternallyconfuzzled.com/tuts/algorithms/jsw_tut_hashing.aspx
	private var oat_hash: Int {
		var hash: Int = 0

		for i: Int in 0..<UUID.count {
			hash = hash &+ numericCast(bytes[i])
			hash = hash &+ (hash << 10)
			hash ^= (hash >> 6)
		}

		hash = hash &+ (hash << 3)
		hash ^= (hash << 11)
		hash = hash &+ (hash << 15)
		return hash
	}
	public var hashValue: Int { return oat_hash }
}

extension UUID: CustomStringConvertible, CustomDebugStringConvertible {
	public var uuidString: String {
		var out: String = String()
		out.reserveCapacity(UUID.count)
		let separatorLayout: [Int] = [0, 0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0]
		let separator: String = "-"
		var idx: Int = 0
		for byte in bytes {
			let char = String(byte, radix: UUID.count, uppercase: true)
			switch char.count {
			case 2:
				out.append(char)
			default:
				out.append("0" + char)
			}
			if separatorLayout[idx] == 1 {
				out.append(separator)
			}
			idx += 1
		}

		assert(idx == UUID.count)
		assert(out.count == 36)
		return out
	}
	public var description: String { return uuidString	}
	public var debugDescription: String { return uuidString }
}
