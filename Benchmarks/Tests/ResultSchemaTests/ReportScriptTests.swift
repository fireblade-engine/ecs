import Foundation
import Testing
@testable import ECSBenchmarkResultSchema

/// Runs the inline script of the HTML report under `node`. Node is not a dependency of the package: these tests are skipped when it
/// is not installed.
enum NodeTool {
    static let path: String? = {
        var directories = (ProcessInfo.processInfo.environment["PATH"] ?? "").split(separator: ":").map(String.init)
        directories += ["/opt/homebrew/bin", "/usr/local/bin", "/usr/bin"]
        return directories.map { $0 + "/node" }.first { FileManager.default.isExecutableFile(atPath: $0) }
    }()

    static var available: Bool { path != nil }

    /// Runs `node` with `arguments` in `directory`; returns the exit status and the combined output.
    static func run(_ arguments: [String], in directory: URL) throws -> (status: Int32, output: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path!)
        process.arguments = arguments
        process.currentDirectoryURL = directory
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return (process.terminationStatus, String(decoding: data, as: UTF8.self))
    }
}

@Suite
struct ReportScriptTests {
    @Test(.enabled(if: NodeTool.available))
    func scriptAndTheInlineCopyInAReportPassNodeCheck() throws {
        let directory = try Support.scratchDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try Data(ReportScript.source.utf8).write(to: directory.appendingPathComponent("script.js"))
        let result = try NodeTool.run(["--check", "script.js"], in: directory)
        #expect(result.status == 0, Comment(rawValue: result.output))
        // The script of a rendered page is the same text.
        let html = try BenchmarkReport.render(GuideFixtures.replicated(), options: ReportOptions(baseline: "1.4.3")).html
        let inline = try #require(html.firstMatch(of: #/<script>\n(.*?)<\/script>/#.dotMatchesNewlines()))
        try Data(String(inline.output.1).utf8).write(to: directory.appendingPathComponent("inline.js"))
        let checked = try NodeTool.run(["--check", "inline.js"], in: directory)
        #expect(checked.status == 0, Comment(rawValue: checked.output))
    }

    @Test(.enabled(if: NodeTool.available))
    func plotModelBehavesUnderNode() throws {
        let directory = try Support.scratchDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try Data(ReportScript.source.utf8).write(to: directory.appendingPathComponent("script.js"))
        try Data(Self.harness.utf8).write(to: directory.appendingPathComponent("harness.js"))
        let result = try NodeTool.run(["harness.js"], in: directory)
        #expect(result.status == 0 && result.output.contains("all ok"), Comment(rawValue: result.output))
    }

    private static let harness = #"""
    "use strict";
    const assert = require("assert");
    const s = require("./script.js");

    function point(n, median, extra) {
      return Object.assign({ n: n, median: median, ciLow: median * 0.9, ciHigh: median * 1.1, cov: 0.97, iqrLow: median * 0.8, iqrHigh: median * 1.2, k: 10 }, extra || {});
    }
    function series(idx, points, baseline) { return { idx: idx, color: idx, label: "s" + idx, ref: "r", backend: "b", baseline: !!baseline, points: points }; }
    function workload(list, rel) { return { id: "w-x", identity: "x", series: list, rel: rel || [] }; }
    const L = 74, R = 744, T = 14, B = 372;

    // A series missing a middle entity count has a gap there, never a line across it or a zero.
    {
      const a = series(0, [point(1, 100), point(2, 200), point(4, 400)], true);
      const b = series(1, [point(1, 50), point(2, 100), point(3, 150), point(4, 200)]);
      const w = workload([a, b]);
      const pts = s.collect(w, "total", "log");
      const scales = s.unionScales(pts);
      assert.deepStrictEqual(scales, [1, 2, 3, 4]);
      const byN = (idx) => { const o = {}; pts.filter((d) => d.series.idx === idx).forEach((d) => { o[d.n] = d; }); return o; };
      assert.deepStrictEqual(s.runs(scales, byN(0)).map((r) => r.map((d) => d.n)), [[1, 2], [4]]);
      assert.deepStrictEqual(s.runs(scales, byN(1)).map((r) => r.map((d) => d.n)), [[1, 2, 3, 4]]);
      // A non-positive median on a log axis is a gap as well.
      const z = s.collect(workload([series(0, [point(1, 5), point(2, 0), point(4, 5)])]), "total", "log");
      assert.deepStrictEqual(z.map((d) => d.n), [1, 4]);
    }

    // Entity count 0: omitted (and counted) on a log axis and in the per-entity plot, kept on linear total axes.
    {
      const w = workload([series(0, [point(0, 40), point(16, 160), point(32, 320)])]);
      const log = s.collect(w, "total", "log");
      assert.deepStrictEqual(log.map((d) => d.n), [16, 32]);
      assert.strictEqual(log.omitted, 1);
      const lin = s.collect(w, "total", "linear");
      assert.deepStrictEqual(lin.map((d) => d.n), [0, 16, 32]);
      assert.strictEqual(lin.omitted, 0);
      const per = s.collect(w, "perEntity", "linear");
      assert.deepStrictEqual(per.map((d) => d.n), [16, 32]);
      assert.strictEqual(per.omitted, 1);
      // Per entity divides the median and the interval by the entity count.
      assert.strictEqual(per[0].v, 10);
      assert.ok(Math.abs(per[0].lo - 9) < 1e-9 && Math.abs(per[0].hi - 11) < 1e-9 && Math.abs(per[0].qLo - 8) < 1e-9);
      // Only scale 0: no plot on a log axis, a plot on linear axes only when something is positive.
      const only = workload([series(0, [point(0, 40)])]);
      assert.strictEqual(s.layoutFor(only, "total", "log", s.collect(only, "total", "log")), null);
    }

    // Log layout: decade ticks, the floor sits on the bottom edge, the unit follows the typical value.
    {
      const w = workload([series(0, [point(1, 2000), point(2, 4000), point(1024, 4000000)])]);
      const pts = s.collect(w, "total", "log");
      const lay = s.layoutFor(w, "total", "log", pts);
      assert.strictEqual(lay.unit.label, "μs");
      assert.ok(lay.yTicks.length >= 2 && lay.yMinor.length > 0);
      assert.ok(Math.abs(lay.y(lay.floor) - B) < 1e-6, "the floor of the band clip is the bottom of the plot");
      assert.ok(lay.y(4000000) < lay.y(2000), "larger values are higher up");
      assert.ok(lay.x(1024) > lay.x(1) && lay.x(1) > L && lay.x(1024) < R);
      assert.deepStrictEqual(lay.xTicks.filter((t) => t.label).map((t) => t.label).slice(0, 3), ["1", "16", "256"]);
      for (const t of lay.yTicks) { assert.ok(t.at >= T - 1e-6 && t.at <= B + 1e-6); }
    }

    // Linear layout starts at zero, includes entity count 0 and uses nice ticks.
    {
      const w = workload([series(0, [point(0, 40), point(500000, 800000), point(1000000, 1500000)])]);
      const lay = s.layoutFor(w, "total", "linear", s.collect(w, "total", "linear"));
      assert.strictEqual(lay.x(0), L);
      assert.ok(Math.abs(lay.y(0) - B) < 1e-6);
      assert.strictEqual(lay.xTicks[0].label, "0");
      assert.ok(lay.xTicks.some((t) => t.label.endsWith("K") || t.label.endsWith("M")));
      assert.deepStrictEqual(s.niceTicks(1500), [0, 500, 1000, 1500]);
      assert.deepStrictEqual(s.niceTicks(0), [0, 1]);
    }

    // Relative plot: zone around 1, ratio ticks stay inside the range.
    {
      const rel = [{ idx: 1, color: 1, label: "s1", ref: "r", backend: "b", points: [
        { n: 1, speed: 2, ciLow: 1.8, ciHigh: 2.2, sig: true, text: "2x" }, { n: 2, speed: 0.5, sig: false, text: "0.5x" }] }];
      const w = workload([], rel);
      const pts = s.collect(w, "relative", "log");
      assert.strictEqual(pts.length, 2);
      assert.strictEqual(pts[1].hollow, true);
      const lay = s.layoutFor(w, "relative", "log", pts);
      assert.ok(lay.zone[0] < 1 && lay.zone[1] > 1 && lay.y(lay.zone[1]) < lay.y(lay.zone[0]));
      for (const v of s.ratioTicks(0.9, 1.3)) { assert.ok(v >= 0.9 - 1e-9 && v <= 1.3 + 1e-9); }
      for (const v of s.ratioTicks(0.3, 250)) { assert.ok(v >= 0.3 - 1e-9 && v <= 250 + 1e-9); }
    }
    console.log("all ok");
    """#
}
