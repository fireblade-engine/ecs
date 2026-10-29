import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

enum HostFacts {
    static func current() throws -> ResultHost {
        let info = ProcessInfo.processInfo
        let version = info.operatingSystemVersion
        var name = utsname()
        _ = uname(&name)
        let machine = withUnsafeBytes(of: &name.machine) { String(cString: $0.bindMemory(to: CChar.self).baseAddress!) }
        #if os(macOS)
        let osName = "macOS"
        #elseif os(Linux)
        let osName = "Linux"
        #else
        let osName = "unknown"
        #endif
        guard let cpu = cpuModel() else { throw ResultError("cannot determine the CPU model of this host") }
        return ResultHost(
            osName: osName,
            osVersion: "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)",
            architecture: machine,
            cpuModel: cpu,
            coreCount: info.processorCount,
            physicalMemoryBytes: info.physicalMemory
        )
    }

    private static func cpuModel() -> String? {
        #if canImport(Darwin)
        var size = 0
        guard sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0) == 0, size > 1 else { return nil }
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname("machdep.cpu.brand_string", &buffer, &size, nil, 0) == 0 else { return nil }
        return String(cString: buffer)
        #else
        guard let text = try? String(contentsOfFile: "/proc/cpuinfo", encoding: .utf8) else { return nil }
        for line in text.split(separator: "\n") where line.hasPrefix("model name") {
            return line.split(separator: ":", maxSplits: 1).last.map { $0.trimmingCharacters(in: .whitespaces) }
        }
        return nil
        #endif
    }
}
