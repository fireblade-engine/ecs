// Fast read path for the report: result files are dominated by the dense `counts` arrays of the HdrHistograms (tens of thousands
// of mostly zero entries per metric). `JSONDecoder` decodes every element through generic `Decodable` machinery, which made
// decoding more than 85 percent of a report's CPU time (profiled with `sample`). The report only needs the mean and a few
// percentiles, so this reader lifts each counts array out of the raw bytes in one linear scan, keeps only its nonzero entries
// and hands `JSONDecoder` a copy of the file with empty counts arrays. Mean and percentiles are computed from the nonzero
// entries with the arithmetic of hdrhistogram-swift 0.2.0 (`Histogram.mean`, `Histogram.valueAtPercentile`), and the tests compare
// them with the real `Histogram` on the same data.
import Foundation

/// The parts of one stored HdrHistogram that the report reads, with the arithmetic of `Histogram` (hdrhistogram-swift 0.2.0).
struct StoredHistogram: Equatable {
    var totalCount: UInt64
    var maxValue: UInt64
    var minNonZeroValue: UInt64
    var subBucketHalfCountMagnitude: Int
    var unitMagnitude: Int
    var leadingZeroCountBase: Int
    var subBucketMask: UInt64
    /// Indices into the dense counts array with their nonzero counts, ascending.
    var indices: [Int]
    var counts: [UInt64]

    private var subBucketCount: Int { 1 << (subBucketHalfCountMagnitude + 1) }

    private func valueFromIndex(_ index: Int) -> UInt64 {
        var bucketIndex = (index >> subBucketHalfCountMagnitude) - 1
        var subBucketIndex = (index & ((1 << subBucketHalfCountMagnitude) - 1)) + (1 << subBucketHalfCountMagnitude)
        if bucketIndex < 0 {
            subBucketIndex -= 1 << subBucketHalfCountMagnitude
            bucketIndex = 0
        }
        return UInt64(subBucketIndex) << (bucketIndex + unitMagnitude)
    }

    /// Lowest value and size of the range of values equivalent to `value`.
    private func equivalentRange(_ value: UInt64) -> (lowest: UInt64, size: UInt64) {
        let bucketIndex = leadingZeroCountBase - (value | subBucketMask).leadingZeroBitCount
        let subBucketIndex = Int(value >> (bucketIndex + unitMagnitude))
        let adjustedBucket = subBucketIndex >= subBucketCount ? bucketIndex + 1 : bucketIndex
        return (UInt64(subBucketIndex) << (bucketIndex + unitMagnitude), UInt64(1) << (unitMagnitude + adjustedBucket))
    }

    private func highestEquivalent(_ value: UInt64) -> UInt64 {
        let range = equivalentRange(value)
        return range.lowest + range.size - 1
    }

    private func medianEquivalent(_ value: UInt64) -> UInt64 {
        let range = equivalentRange(value)
        return range.lowest + (range.size >> 1)
    }

    private var minimum: UInt64 {
        (indices.first == 0 || totalCount == 0) ? 0 : minNonZeroValue
    }

    var mean: Double {
        if totalCount == 0 { return 0 }
        var totalValue: Double = 0
        var reached: UInt64 = 0
        // The recorded-values iterator of Histogram stops as soon as the visited counts reach the total.
        for (index, count) in zip(indices, counts) {
            if reached >= totalCount { break }
            reached += count
            totalValue += Double(medianEquivalent(highestEquivalent(valueFromIndex(index)))) * Double(count)
        }
        return totalValue / Double(totalCount)
    }

    func valueAtPercentile(_ percentile: Double) -> UInt64 {
        guard percentile != 0.0 else { return minimum }
        guard percentile < 100.0 else { return maxValue }
        let requested = Swift.min(Swift.max(percentile.nextDown, 0.0), 100.0)
        let countAtPercentile = Swift.max(1, UInt64(((requested * Double(totalCount)) / 100.0).rounded(.up)))
        var reached: UInt64 = 0
        for (index, count) in zip(indices, counts) {
            reached += count
            if reached >= countAtPercentile {
                return Swift.max(Swift.min(highestEquivalent(valueFromIndex(index)), maxValue), minimum)
            }
        }
        return 0
    }
}

/// A result file's bytes with the counts arrays lifted out.
struct StrippedResultFile {
    /// The file with every `"counts":[...]` replaced by `"counts":[]` and every histogram's `highestTrackableValue` replaced by the
    /// ordinal of its entry in `histograms` (the decoded `Histogram` keeps that field and nothing in the report reads it).
    var data: Data
    var histograms: [UInt64: StoredHistogram]

    init(_ original: Data) throws {
        var output = [UInt8]()
        var histograms: [UInt64: StoredHistogram] = [:]
        try original.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
            let bytes = raw.bindMemory(to: UInt8.self)
            output.reserveCapacity(bytes.count / 8)
            var copied = 0
            var cursor = 0
            let needle = Array(#""counts":["#.utf8)
            let highest = Array(#""highestTrackableValue":"#.utf8)
            while let hit = Self.find(needle, in: bytes, from: cursor) {
                let start = hit + needle.count
                var end = start
                while end < bytes.count, bytes[end] != UInt8(ascii: "]") { end += 1 }
                guard end < bytes.count else { throw ResultError("result file does not match the schema: unterminated histogram counts") }
                var objectStart = hit
                while objectStart > 0, bytes[objectStart] != UInt8(ascii: "{") { objectStart -= 1 }
                var objectEnd = end
                while objectEnd < bytes.count, bytes[objectEnd] != UInt8(ascii: "}") { objectEnd += 1 }
                guard objectEnd < bytes.count else { throw ResultError("result file does not match the schema: unterminated histogram") }

                func integer(_ key: String) throws -> UInt64 {
                    let name = Array("\"\(key)\":".utf8)
                    let at = Self.find(name, in: bytes, from: objectStart, to: hit) ?? Self.find(name, in: bytes, from: end, to: objectEnd)
                    guard let at, let value = Self.parseInteger(bytes, at + name.count) else {
                        throw ResultError("result file does not match the schema: histogram without \(key)")
                    }
                    return value
                }
                var indices: [Int] = []
                var counts: [UInt64] = []
                var index = 0
                var position = start
                while position < end {
                    var value: UInt64 = 0
                    while position < end, bytes[position] != UInt8(ascii: ",") {
                        value = value &* 10 &+ UInt64(bytes[position] &- UInt8(ascii: "0"))
                        position += 1
                    }
                    if value != 0 {
                        indices.append(index)
                        counts.append(value)
                    }
                    index += 1
                    position += 1
                }
                let ordinal = UInt64(histograms.count)
                histograms[ordinal] = try StoredHistogram(
                    totalCount: integer("_totalCount"), maxValue: integer("maxValue"), minNonZeroValue: integer("minNonZeroValue"),
                    subBucketHalfCountMagnitude: Int(integer("subBucketHalfCountMagnitude")), unitMagnitude: Int(integer("unitMagnitude")),
                    leadingZeroCountBase: Int(integer("leadingZeroCountBase")), subBucketMask: integer("subBucketMask"),
                    indices: indices, counts: counts
                )
                // Two edits in file order: the counts array and the highest trackable value number.
                var edits: [(range: Range<Int>, text: [UInt8])] = [((start ..< end), [])]
                let valueAt = Self.find(highest, in: bytes, from: objectStart, to: hit) ?? Self.find(highest, in: bytes, from: end, to: objectEnd)
                guard let valueAt else { throw ResultError("result file does not match the schema: histogram without highestTrackableValue") }
                var valueEnd = valueAt + highest.count
                while valueEnd < bytes.count, bytes[valueEnd] >= UInt8(ascii: "0"), bytes[valueEnd] <= UInt8(ascii: "9") { valueEnd += 1 }
                edits.append(((valueAt + highest.count ..< valueEnd), Array(String(ordinal).utf8)))
                edits.sort { $0.range.lowerBound < $1.range.lowerBound }
                for edit in edits {
                    output.append(contentsOf: UnsafeBufferPointer(rebasing: bytes[copied ..< edit.range.lowerBound]))
                    output.append(contentsOf: edit.text)
                    copied = edit.range.upperBound
                }
                cursor = max(end, objectEnd)
            }
            output.append(contentsOf: UnsafeBufferPointer(rebasing: bytes[copied...]))
        }
        data = Data(output)
        self.histograms = histograms
    }

    private static func find(_ needle: [UInt8], in bytes: UnsafeBufferPointer<UInt8>, from: Int, to: Int? = nil) -> Int? {
        let limit = to ?? bytes.count
        guard from < limit, let base = bytes.baseAddress else { return nil }
        return needle.withUnsafeBufferPointer { pattern in
            guard let found = memmem(base + from, limit - from, pattern.baseAddress, pattern.count) else { return nil }
            return base.distance(to: found.assumingMemoryBound(to: UInt8.self))
        }
    }

    private static func parseInteger(_ bytes: UnsafeBufferPointer<UInt8>, _ from: Int) -> UInt64? {
        var position = from
        var value: UInt64 = 0
        while position < bytes.count, bytes[position] >= UInt8(ascii: "0"), bytes[position] <= UInt8(ascii: "9") {
            value = value &* 10 &+ UInt64(bytes[position] &- UInt8(ascii: "0"))
            position += 1
        }
        return position > from ? value : nil
    }
}
