// The inline script of the HTML report: draws every plot client-side as SVG from the embedded JSON data and wires the log/linear
// toggles, the tooltip, the crosshair and the table row highlighting. Plain ES2017, no libraries, no network access. The values
// it shows (medians, intervals, speeds, verdicts) are formatted by the Swift side and only positioned here.
enum ReportScript {
    static let source = #"""
    (function () {
      "use strict";
      var SVGNS = "http:" + "//www.w3.org/2000/svg";
      // Loaded by node for the tests (no DOM): only the pure functions are exported at the end.
      var hasDOM = typeof document !== "undefined";
      var dataNode = hasDOM ? document.getElementById("report-data") : null;
      if (hasDOM && !dataNode) { return; }
      var data = dataNode ? JSON.parse(dataNode.textContent) : { title: "", baseline: "", delta: 0.05, workloads: [] };
      var W = 760, H = 440, L = 74, R = 744, T = 14, B = 372;
      var UNITS = [["ns", 1], ["μs", 1e3], ["ms", 1e6], ["s", 1e9]];
      var KINDS = {
        perEntity: { title: "wall-clock cost per entity", y: "Median time per entity" },
        total: { title: "wall-clock time per iteration", y: "Median time per iteration" },
        relative: { title: "speed against the baseline", y: "Speed vs baseline" }
      };
      var plots = [];
      var uid = 0;

      function svg(name, attrs, parent) {
        var node = document.createElementNS(SVGNS, name);
        for (var key in attrs) { if (Object.prototype.hasOwnProperty.call(attrs, key)) { node.setAttribute(key, attrs[key]); } }
        if (parent) { parent.appendChild(node); }
        return node;
      }
      function html(name, className, text, parent) {
        var node = document.createElement(name);
        if (className) { node.className = className; }
        if (text !== undefined && text !== null) { node.textContent = text; }
        if (parent) { parent.appendChild(node); }
        return node;
      }
      function r2(v) { return Math.round(v * 100) / 100; }

      // ---- number helpers -------------------------------------------------------------------------------------------
      function median(values) {
        var sorted = values.slice().sort(function (a, b) { return a - b; });
        return sorted[Math.floor(sorted.length / 2)];
      }
      function pickUnit(values) {
        var positive = values.filter(function (v) { return v > 0 && isFinite(v); });
        if (!positive.length) { return { label: UNITS[0][0], div: 1 }; }
        var typical = median(positive);
        var chosen = UNITS[0];
        UNITS.forEach(function (u) { if (u[1] <= typical) { chosen = u; } });
        return { label: chosen[0], div: chosen[1] };
      }
      /** At most three significant digits, thousands separators, no exponent. */
      function num(v) {
        if (v === 0) { return "0"; }
        var a = Math.abs(v);
        var decimals = Math.max(0, 2 - Math.floor(Math.log10(a) + 1e-12));
        if (decimals > 9) { decimals = 9; }
        var rounded = Number(v.toFixed(decimals));
        return rounded.toLocaleString("en-US", { minimumFractionDigits: 0, maximumFractionDigits: decimals });
      }
      function plain(v) {
        var text = v.toFixed(6);
        text = text.replace(/0+$/, "").replace(/\.$/, "");
        return text === "-0" ? "0" : text;
      }
      function decadeLabel(e) {
        if (e >= 0) { return String(Math.pow(10, e)); }
        return e >= -9 ? Math.pow(10, e).toFixed(-e) : "1e" + e;
      }
      function compactCount(n) {
        if (n >= 1048576 && n % 1048576 === 0) { return (n / 1048576) + "M"; }
        if (n >= 1024 && n % 1024 === 0) { return (n / 1024) + "K"; }
        return String(n);
      }
      function siCount(v) {
        if (v >= 1e6) { return plain(v / 1e6) + "M"; }
        if (v >= 1e3) { return plain(v / 1e3) + "K"; }
        return plain(v);
      }
      function niceTicks(max) {
        if (!(max > 0) || !isFinite(max)) { return [0, 1]; }
        var raw = max / 5;
        var mag = Math.pow(10, Math.floor(Math.log10(raw)));
        var step = 10 * mag;
        [1, 2, 5, 10].some(function (f) {
          if (f * mag >= raw - 1e-12 * raw) { step = f * mag; return true; }
          return false;
        });
        var count = Math.max(1, Math.ceil(max / step - 1e-9));
        var ticks = [];
        for (var i = 0; i <= count; i++) { ticks.push(i * step); }
        return ticks;
      }
      function ratioTicks(low, high) {
        var ratio = high / low;
        var candidates = [];
        function within(v) { return v >= low * (1 - 1e-9) && v <= high * (1 + 1e-9); }
        if (ratio >= 3) {
          var families = [[1, 2, 5], [1, 1.5, 2, 3, 5, 7], [1, 1.25, 1.5, 2, 2.5, 3, 4, 5, 6, 8]];
          for (var f = 0; f < families.length; f++) {
            var values = [];
            for (var e = Math.floor(Math.log10(low)); e <= Math.ceil(Math.log10(high)); e++) {
              families[f].forEach(function (m) { values.push(m * Math.pow(10, e)); });
            }
            values = values.filter(within);
            candidates = values;
            if (values.length >= 4 && values.length <= 9) { break; }
          }
        } else {
          [0.05, 0.1, 0.2, 0.25, 0.5].some(function (step) {
            var first = Math.ceil(low / step), last = Math.floor(high / step);
            if (first > last) { return false; }
            var values = [];
            for (var i = first; i <= last; i++) { if (i * step > 0) { values.push(i * step); } }
            if (values.length >= 3 && values.length <= 9) { candidates = values; return true; }
            return false;
          });
        }
        var ticks = candidates.filter(within);
        return ticks.length ? ticks : [1];
      }
      function relativePercent(fraction) {
        var percent = Math.abs(fraction) * 100;
        if (!isFinite(percent) || percent <= 0) { return "0"; }
        var decimals = Math.min(9, Math.max(0, 1 - Math.floor(Math.log10(percent) + 1e-12)));
        return percent.toFixed(decimals);
      }

      // ---- plot model -----------------------------------------------------------------------------------------------
      /** The drawable points of one plot as {series, n, v, lo, hi, qLo, qHi, hollow, p}; v is in base units (ns or ratio). */
      function collect(workload, kind, mode) {
        var out = [];
        // Points that cannot be drawn on these axes because of their entity count 0 (a log axis, or a per-entity value).
        out.omitted = 0;
        var source = kind === "relative" ? workload.rel : workload.series;
        source.forEach(function (series) {
          series.points.forEach(function (p) {
            var per = kind === "perEntity" ? p.n : 1;
            if ((kind === "perEntity" || mode === "log") && p.n <= 0) { out.omitted++; return; }
            if (kind === "relative") {
              if (!(p.speed > 0)) { return; }
              out.push({ series: series, n: p.n, v: p.speed, lo: p.ciLow, hi: p.ciHigh, hollow: !p.sig, p: p });
            } else {
              if (mode === "log" && !(p.median > 0)) { return; }
              out.push({
                series: series, n: p.n, v: p.median / per,
                lo: p.ciLow === undefined ? undefined : p.ciLow / per, hi: p.ciHigh === undefined ? undefined : p.ciHigh / per,
                qLo: p.iqrLow / per, qHi: p.iqrHigh / per, hollow: p.ciLow === undefined, p: p
              });
            }
          });
        });
        return out;
      }

      function layoutFor(workload, kind, mode, pts) {
        if (!pts.length) { return null; }
        var ns = pts.map(function (d) { return d.n; });
        var maxN = Math.max.apply(null, ns);
        var lay = { mode: mode, kind: kind, xTicks: [], yTicks: [], yMinor: [], unit: null };
        var isLog = mode === "log";
        if (isLog) {
          var positive = ns.filter(function (n) { return n > 0; });
          var lowExp = Math.floor(Math.log2(Math.min.apply(null, positive)) + 1e-12);
          var highExp = Math.max(lowExp, Math.ceil(Math.log2(maxN) - 1e-12));
          var xLow = lowExp - 0.5, xHigh = highExp + 0.5;
          lay.x = function (n) { return L + (Math.log2(n) - xLow) / (xHigh - xLow) * (R - L); };
          for (var e = lowExp; e <= highExp; e++) {
            lay.xTicks.push({ at: lay.x(Math.pow(2, e)), label: (e % 4 === 0 || e === highExp) ? compactCount(Math.pow(2, e)) : "", major: e % 4 === 0 || e === highExp });
          }
          lay.xTitle = "Entities (log2 scale)";
        } else {
          var xt = niceTicks(maxN);
          var xMax = xt[xt.length - 1];
          lay.x = function (n) { return L + n / xMax * (R - L); };
          xt.forEach(function (v) { lay.xTicks.push({ at: lay.x(v), label: siCount(v), major: true }); });
          lay.xTitle = "Entities (linear scale)";
        }
        if (kind === "relative") {
          var delta = data.delta, zl = 1 / (1 + delta), zh = 1 + delta;
          lay.zone = [zl, zh];
          var vals = [];
          pts.forEach(function (d) { vals.push(d.v); if (d.lo) { vals.push(d.lo); } if (d.hi) { vals.push(d.hi); } });
          if (isLog) {
            var low = Math.min(Math.min.apply(null, vals), zl) / 1.04, high = Math.max(Math.max.apply(null, vals), zh) * 1.04;
            lay.y = function (v) { return B - (Math.log(v) - Math.log(low)) / (Math.log(high) - Math.log(low)) * (B - T); };
            ratioTicks(low, high).forEach(function (v) { lay.yTicks.push({ at: lay.y(v), label: plain(Math.round(v * 1000) / 1000) }); });
            lay.floor = low;
          } else {
            var yt = niceTicks(Math.max(Math.max.apply(null, vals), zh));
            var yMax = yt[yt.length - 1];
            lay.y = function (v) { return B - v / yMax * (B - T); };
            yt.forEach(function (v) { lay.yTicks.push({ at: lay.y(v), label: plain(v) }); });
            lay.floor = 0;
          }
          lay.yTitle = "Speed vs " + data.baseline + " (×, " + (isLog ? "log" : "linear") + " scale; above 1 is faster)";
          lay.unit = { label: "×", div: 1, ratio: true };
          return lay;
        }
        var per = pts.map(function (d) { return d.v; });
        var top = Math.max.apply(null, pts.map(function (d) { return Math.max(d.v, d.hi || 0, d.qHi || 0); }));
        if (isLog) {
          lay.unit = pickUnit([median(per.filter(function (v) { return v > 0; }))]);
          var lows = [], highs = [];
          pts.forEach(function (d) {
            [d.v, d.lo === undefined ? d.v : d.lo, d.qLo].forEach(function (v) { lows.push(v / lay.unit.div); });
            [d.v, d.hi === undefined ? d.v : d.hi, d.qHi].forEach(function (v) { highs.push(v / lay.unit.div); });
          });
          var smallest = Math.min.apply(null, lows.filter(function (v) { return v > 0; }));
          var largest = Math.max.apply(null, highs);
          if (!isFinite(smallest) || !(largest > 0)) { return null; }
          var yLowE = Math.floor(Math.log10(smallest) + 1e-12);
          var yHighE = Math.ceil(Math.log10(largest) - 1e-12);
          if (yHighE <= yLowE) { yHighE = yLowE + 1; }
          lay.y = function (v) { return B - (Math.log10(v / lay.unit.div) - yLowE) / (yHighE - yLowE) * (B - T); };
          lay.floor = Math.pow(10, yLowE) * lay.unit.div;
          for (var k = yLowE; k <= yHighE; k++) {
            lay.yTicks.push({ at: lay.y(Math.pow(10, k) * lay.unit.div), label: decadeLabel(k) });
            if (k < yHighE && yHighE - yLowE <= 12) {
              for (var m = 2; m <= 9; m++) { lay.yMinor.push(lay.y(m * Math.pow(10, k) * lay.unit.div)); }
            }
          }
          lay.yTitle = KINDS[kind].y + " (" + lay.unit.label + ", log10 scale)";
        } else {
          if (!(top > 0)) { return null; }
          lay.unit = pickUnit([top / 2]);
          var yTicks = niceTicks(top / lay.unit.div);
          var yTop = yTicks[yTicks.length - 1];
          lay.y = function (v) { return B - v / lay.unit.div / yTop * (B - T); };
          lay.floor = 0;
          yTicks.forEach(function (v) { lay.yTicks.push({ at: lay.y(v * lay.unit.div), label: plain(v) }); });
          lay.yTitle = KINDS[kind].y + " (" + lay.unit.label + ")";
        }
        return lay;
      }

      /** The entity counts of all series of a plot, ascending: the union axis on which a series' missing count is a gap. */
      function unionScales(pts) {
        var scales = [];
        pts.forEach(function (d) { if (scales.indexOf(d.n) < 0) { scales.push(d.n); } });
        return scales.sort(function (a, b) { return a - b; });
      }
      /** Consecutive scales of the union axis for which the series has a point; a missing scale is a gap, never a zero. */
      function runs(scales, byN) {
        var result = [], current = [];
        scales.forEach(function (n) {
          if (byN[n]) { current.push(byN[n]); } else if (current.length) { result.push(current); current = []; }
        });
        if (current.length) { result.push(current); }
        return result;
      }

      function marker(shape, x, y, parent, cls) {
        var r = 3.4;
        var attrs = { "class": cls };
        switch (shape % 4) {
          case 0: attrs.cx = r2(x); attrs.cy = r2(y); attrs.r = r; return svg("circle", attrs, parent);
          case 1: attrs.x = r2(x - r); attrs.y = r2(y - r); attrs.width = 2 * r; attrs.height = 2 * r; return svg("rect", attrs, parent);
          case 2:
            attrs.points = r2(x) + "," + r2(y - r - 1) + " " + r2(x + r + 1) + "," + r2(y + r) + " " + r2(x - r - 1) + "," + r2(y + r);
            return svg("polygon", attrs, parent);
          default:
            attrs.points = r2(x) + "," + r2(y - r - 1.5) + " " + r2(x + r + 1.5) + "," + r2(y) + " " + r2(x) + "," + r2(y + r + 1.5) + " " + r2(x - r - 1.5) + "," + r2(y);
            return svg("polygon", attrs, parent);
        }
      }

      // ---- plot --------------------------------------------------------------------------------------------------
      function Plot(root) {
        this.root = root;
        this.workload = data.workloads.filter(function (w) { return w.id === root.getAttribute("data-w"); })[0];
        this.kind = root.getAttribute("data-kind");
        this.mode = "log";
        this.build();
        this.render();
      }
      Plot.prototype.build = function () {
        var self = this;
        var bar = html("div", "plot-bar", null, this.root);
        html("strong", "plot-title", this.workload.identity + ": " + KINDS[this.kind].title, bar);
        var seg = html("span", "seg", null, bar);
        seg.setAttribute("role", "group");
        seg.setAttribute("aria-label", "Axis scale of this plot");
        this.buttons = {};
        ["log", "linear"].forEach(function (mode) {
          var b = html("button", "", mode === "log" ? "Log" : "Linear", seg);
          b.type = "button";
          b.addEventListener("click", function () { self.setMode(mode); });
          self.buttons[mode] = b;
        });
        this.frame = html("div", "plot-frame", null, this.root);
        this.tip = html("div", "tip", null, this.frame);
        this.tip.hidden = true;
        this.legend = html("div", "legend", null, this.root);
        this.notes = html("p", "notes", null, this.root);
      };
      Plot.prototype.setMode = function (mode) {
        this.mode = mode;
        this.render();
        syncGlobal();
      };
      Plot.prototype.render = function () {
        var self = this;
        var mode = this.mode;
        ["log", "linear"].forEach(function (m) { self.buttons[m].setAttribute("aria-pressed", String(m === mode)); });
        if (this.svg) { this.frame.removeChild(this.svg); }
        this.hide();
        var pts = collect(this.workload, this.kind, mode);
        this.omitted = pts.omitted;
        var lay = layoutFor(this.workload, this.kind, mode, pts);
        this.legend.textContent = "";
        this.notes.textContent = "";
        if (!lay) {
          this.svg = html("p", "empty", "No data to plot" + (mode === "log" ? " on log axes (entity count 0 cannot be shown)" : "") + ".");
          this.frame.insertBefore(this.svg, this.tip);
          return;
        }
        this.lay = lay;
        var id = "clip" + (uid++);
        var root = svg("svg", { viewBox: "0 0 " + W + " " + H, "class": "plot-svg", role: "group", "aria-label": this.workload.identity + ": " + KINDS[this.kind].title }, null);
        this.svg = root;
        this.frame.insertBefore(root, this.tip);
        var defs = svg("defs", {}, root);
        var clip = svg("clipPath", { id: id }, defs);
        svg("rect", { x: L, y: T, width: R - L, height: B - T }, clip);
        // Grid and axes.
        lay.yMinor.forEach(function (y) { svg("line", { "class": "minor", x1: L, x2: R, y1: r2(y), y2: r2(y) }, root); });
        lay.yTicks.forEach(function (t) {
          svg("line", { "class": "grid", x1: L, x2: R, y1: r2(t.at), y2: r2(t.at) }, root);
          svg("text", { "class": "tick", "text-anchor": "end", x: L - 8, y: r2(t.at + 4) }, root).textContent = t.label;
        });
        lay.xTicks.forEach(function (t) {
          svg("line", { "class": t.major ? "grid" : "minor", x1: r2(t.at), x2: r2(t.at), y1: T, y2: B }, root);
          svg("line", { "class": "axis", x1: r2(t.at), x2: r2(t.at), y1: B, y2: B + (t.major ? 6 : 3) }, root);
          if (t.label) { svg("text", { "class": "tick", "text-anchor": "middle", x: r2(t.at), y: B + 20 }, root).textContent = t.label; }
        });
        if (lay.zone) {
          svg("rect", { "class": "zone", x: L, y: r2(lay.y(lay.zone[1])), width: R - L, height: r2(lay.y(lay.zone[0]) - lay.y(lay.zone[1])) }, root);
          svg("line", { "class": "ref", x1: L, x2: R, y1: r2(lay.y(1)), y2: r2(lay.y(1)) }, root);
        }
        svg("rect", { "class": "frame", x: L, y: T, width: R - L, height: B - T }, root);
        svg("text", { "class": "axis-title", "text-anchor": "middle", x: (L + R) / 2, y: B + 46 }, root).textContent = lay.xTitle;
        svg("text", { "class": "axis-title", "text-anchor": "middle", transform: "translate(18 " + (T + B) / 2 + ") rotate(-90)" }, root).textContent = lay.yTitle;

        var floor = lay.floor;
        function yy(v) { return lay.y(floor > 0 ? Math.max(v, floor) : v); }
        var bySeries = [];
        pts.forEach(function (d) {
          var s = d.series;
          if (!bySeries[s.idx]) { bySeries[s.idx] = { series: s, pts: [], byN: {} }; }
          bySeries[s.idx].pts.push(d);
          bySeries[s.idx].byN[d.n] = d;
        });
        var groups = bySeries.filter(Boolean);
        var scales = unionScales(pts);
        var layer = svg("g", { "clip-path": "url(#" + id + ")" }, root);
        var isRel = this.kind === "relative";
        // Bands (IQR) or ribbons (CI of the speed), then lines, markers, error bars.
        groups.forEach(function (g) {
          var cls = "c" + (g.series.color % 7);
          runs(scales, g.byN).forEach(function (run) {
            var upper, lower;
            if (isRel) {
              var ribbon = run.filter(function (d) { return d.lo !== undefined && d.hi !== undefined; });
              if (ribbon.length !== run.length || run.length < 2) { return; }
              upper = run.map(function (d) { return r2(lay.x(d.n)) + "," + r2(yy(d.hi)); });
              lower = run.slice().reverse().map(function (d) { return r2(lay.x(d.n)) + "," + r2(yy(d.lo)); });
              svg("polygon", { "class": "ribbon " + cls, points: upper.concat(lower).join(" ") }, layer);
            } else if (run.length >= 2) {
              upper = run.map(function (d) { return r2(lay.x(d.n)) + "," + r2(yy(d.qHi)); });
              lower = run.slice().reverse().map(function (d) { return r2(lay.x(d.n)) + "," + r2(yy(d.qLo)); });
              svg("polygon", { "class": "band " + cls, points: upper.concat(lower).join(" ") }, layer);
            }
          });
        });
        groups.forEach(function (g) {
          var cls = "c" + (g.series.color % 7);
          runs(scales, g.byN).forEach(function (run) {
            if (run.length < 2) { return; }
            svg("polyline", {
              "class": "line " + cls + (g.series.baseline ? " baseline" : ""),
              points: run.map(function (d) { return r2(lay.x(d.n)) + "," + r2(yy(d.v)); }).join(" ")
            }, layer);
          });
        });
        var hits = svg("g", { "class": "hits" }, layer);
        // One tab stop per plot (roving tabindex); arrow keys move between points.
        var grid = [];
        var first = true;
        groups.forEach(function (g) {
          var cls = "c" + (g.series.color % 7);
          var row = [];
          grid.push(row);
          g.pts.forEach(function (d) {
            var x = lay.x(d.n), y = yy(d.v);
            var node = svg("g", { "class": "pt", tabindex: first ? "0" : "-1", role: "img", "aria-label": self.describe(d) }, hits);
            first = false;
            row.push({ node: node, d: d });
            node.addEventListener("keydown", function (ev) { self.key(ev, grid, row); });
            svg("circle", { "class": "hit", cx: r2(x), cy: r2(y), r: 10 }, node);
            marker(g.series.color, x, y, node, "marker " + cls + (d.hollow ? " hollow" : ""));
            var show = function (ev) { self.show(d, x, y, ev); };
            node.addEventListener("pointerenter", show);
            node.addEventListener("pointermove", show);
            node.addEventListener("focus", function () {
              Array.prototype.forEach.call(hits.querySelectorAll(".pt"), function (other) { other.setAttribute("tabindex", "-1"); });
              node.setAttribute("tabindex", "0");
              self.show(d, x, y, null);
            });
            node.addEventListener("click", show);
            node.addEventListener("pointerleave", function () { if (document.activeElement !== node) { self.hide(); } });
            node.addEventListener("blur", function () { self.hide(); });
          });
        });
        groups.forEach(function (g) {
          var ecls = "e" + (g.series.color % 7);
          g.pts.forEach(function (d) {
            if (isRel) { return; }
            if (d.lo === undefined || d.hi === undefined) { return; }
            var x = lay.x(d.n), yl = yy(d.lo), yh = yy(Math.max(d.hi, d.lo));
            var cap = 5;
            svg("path", {
              "class": "errbar " + ecls,
              d: "M" + r2(x) + "," + r2(yh) + "V" + r2(yl) + "M" + r2(x - cap) + "," + r2(yh) + "H" + r2(x + cap) + "M" + r2(x - cap) + "," + r2(yl) + "H" + r2(x + cap)
            }, layer);
          });
        });
        // Crosshair above everything, never catching the pointer.
        var xh = svg("g", { "class": "crosshair", visibility: "hidden" }, root);
        this.xh = {
          g: xh,
          v: svg("line", { "class": "xh-line", y2: B }, xh),
          h: svg("line", { "class": "xh-line", x1: L }, xh),
          xr: svg("rect", { "class": "xh-box", height: 18, rx: 3, y: B + 2 }, xh),
          xt: svg("text", { "class": "xh-text", "text-anchor": "middle", y: B + 15 }, xh),
          yr: svg("rect", { "class": "xh-box", height: 18, rx: 3 }, xh),
          yt: svg("text", { "class": "xh-text", "text-anchor": "end", x: L - 6 }, xh)
        };
        this.drawLegend(groups, pts);
      };
      Plot.prototype.drawLegend = function (groups, pts) {
        var self = this;
        var all = this.kind === "relative" ? this.workload.rel : this.workload.series;
        all.forEach(function (s) {
          var item = html("span", "legend-item", null, self.legend);
          var key = svg("svg", { width: 34, height: 14, viewBox: "0 0 34 14", "aria-hidden": "true" }, null);
          var cls = "c" + (s.color % 7);
          svg("line", { "class": "line " + cls + (s.baseline ? " baseline" : ""), x1: 1, x2: 33, y1: 7, y2: 7 }, key);
          marker(s.color, 17, 7, key, "marker " + cls);
          item.appendChild(key);
          html("span", "", s.label + (s.baseline ? " (baseline)" : ""), item);
        });
        var notes = [];
        var covs = [];
        var halves = [];
        pts.forEach(function (d) {
          if (d.lo !== undefined && d.hi !== undefined && d.v > 0) { halves.push((d.hi - d.lo) / 2 / d.v); }
          if (d.p.cov !== undefined) { covs.push(d.p.cov); }
        });
        var largest = halves.length ? "largest CI: ±" + relativePercent(Math.max.apply(null, halves)) + "%" : null;
        if (this.kind === "relative") {
          notes.push("Line: speed = baseline / series (Hodges–Lehmann)");
          notes.push(halves.length ? "Ribbon: 95% CI of the speed" + (largest ? " (" + largest + ")" : "") : "No ribbon: too few replicates for a CI");
          notes.push("Shaded zone: ±" + plain(data.delta * 100) + "% (equivalence zone); reference line: 1×, equal to the baseline");
          notes.push("Filled marker: significant faster or slower; hollow marker: not significant or n/a");
        } else {
          notes.push("Line: median over replicates");
          if (covs.length) {
            var lo = Math.min.apply(null, covs), hi = Math.max.apply(null, covs);
            var cov = lo === hi ? (lo * 100).toFixed(1) + "%" : (lo * 100).toFixed(1) + "-" + (hi * 100).toFixed(1) + "%";
            notes.push("Error bars (dark, with caps): CI of the median, " + cov + (largest ? " (" + largest + ")" : ""));
          } else {
            notes.push("No error bars: too few replicates for a CI");
          }
          notes.push("Light band: within-run IQR (p25 to p75), spread of one run, not uncertainty");
          if (this.workload.series.some(function (s) { return s.baseline; })) { notes.push("Dashed line: baseline"); }
          if (covs.length && pts.some(function (d) { return d.hollow; })) { notes.push("Hollow marker: no CI at this point"); }
        }
        if (this.omitted > 0) { notes.push("Entity count 0 is omitted (" + (this.mode === "log" ? "log axis" : "per-entity value") + ")"); }
        this.notes.textContent = notes.join(". ") + ".";
      };

      Plot.prototype.describe = function (d) {
        return this.tipLines(d).join(", ");
      };
      Plot.prototype.tipLines = function (d) {
        var p = d.p, s = d.series;
        var lines = [s.ref + " · " + s.backend, "Entities: " + d.n.toLocaleString("en-US")];
        if (this.kind === "relative") {
          lines.push("Speed: " + p.text);
          if (p.verdict) { lines.push("Verdict: " + p.sym + " " + p.verdict); }
        } else {
          lines.push("Median: " + p.tMedian);
          if (p.tCI) { lines.push("95% CI: " + p.tCI); }
          if (this.kind === "perEntity" && p.tPer) { lines.push("Per entity: " + p.tPer); }
          if (p.tSpeed) { lines.push("Speed: " + p.tSpeed); }
          if (p.verdict) { lines.push("Verdict: " + p.sym + " " + p.verdict); }
        }
        return lines;
      };
      Plot.prototype.axisValue = function (d) {
        var lay = this.lay;
        if (lay.unit && lay.unit.ratio) { return num(d.v) + "×"; }
        return num(d.v / lay.unit.div) + " " + lay.unit.label;
      };
      Plot.prototype.show = function (d, x, y, ev) {
        var lay = this.lay, xh = this.xh;
        if (!lay || !xh) { return; }
        var frame = this.frame.getBoundingClientRect();
        if (this.current !== d) {
          this.hide();
          this.current = d;
          var cx = r2(x), cy = r2(y);
          xh.v.setAttribute("x1", cx); xh.v.setAttribute("x2", cx); xh.v.setAttribute("y1", cy);
          xh.h.setAttribute("x2", cx); xh.h.setAttribute("y1", cy); xh.h.setAttribute("y2", cy);
          var xText = d.n.toLocaleString("en-US"), yText = this.axisValue(d);
          xh.xt.textContent = xText; xh.xt.setAttribute("x", cx);
          xh.yt.textContent = yText; xh.yt.setAttribute("y", r2(y + 4));
          var xw = xText.length * 7 + 12, yw = yText.length * 7 + 12;
          xh.xr.setAttribute("x", r2(x - xw / 2)); xh.xr.setAttribute("width", xw);
          xh.yr.setAttribute("x", L - 6 - yw + 6); xh.yr.setAttribute("width", yw); xh.yr.setAttribute("y", r2(y - 9));
          xh.g.setAttribute("visibility", "visible");
          this.tip.textContent = "";
          this.tipLines(d).forEach(function (line, i) { html("div", i === 0 ? "tip-head" : "", line, this.tip); }, this);
          this.tip.hidden = false;
          highlightRows(this.workload.id, d.n, d.series.idx, true);
        }
        // Near the pointer, or near the point when keyboard focus put us here.
        var scale = frame.width / W;
        var left = ev && ev.clientX ? ev.clientX - frame.left : x * scale;
        var top = ev && ev.clientY ? ev.clientY - frame.top : y * scale;
        var tw = this.tip.offsetWidth, th = this.tip.offsetHeight;
        var px = left + 14;
        if (px + tw > frame.width) { px = Math.max(0, left - 14 - tw); }
        var py = top + 14;
        if (py + th > frame.height) { py = Math.max(0, top - 14 - th); }
        this.tip.style.left = px + "px";
        this.tip.style.top = py + "px";
      };
      Plot.prototype.key = function (ev, grid, row) {
        var node = ev.currentTarget;
        var column = row.map(function (entry) { return entry.node; }).indexOf(node);
        var line = grid.indexOf(row);
        var target = null;
        if (ev.key === "Escape") { this.hide(); return; }
        if (ev.key === "ArrowRight") { target = row[column + 1]; }
        else if (ev.key === "ArrowLeft") { target = row[column - 1]; }
        else if (ev.key === "ArrowUp" || ev.key === "ArrowDown") {
          var other = grid[line + (ev.key === "ArrowDown" ? 1 : -1)];
          if (other && other.length) {
            var n = row[column].d.n;
            target = other.reduce(function (best, entry) { return Math.abs(entry.d.n - n) < Math.abs(best.d.n - n) ? entry : best; }, other[0]);
          }
        } else { return; }
        ev.preventDefault();
        if (target) { target.node.focus(); }
      };
      Plot.prototype.hide = function () {
        if (this.xh) { this.xh.g.setAttribute("visibility", "hidden"); }
        this.tip.hidden = true;
        if (this.current) {
          highlightRows(this.workload.id, this.current.n, this.current.series.idx, false);
          this.current = null;
        }
      };

      function highlightRows(workloadId, n, seriesIdx, on) {
        var rows = document.querySelectorAll('tr[data-w="' + workloadId + '"][data-n="' + n + '"]');
        Array.prototype.forEach.call(rows, function (row) {
          row.classList.toggle("hl", on);
          Array.prototype.forEach.call(row.querySelectorAll('td[data-s="' + seriesIdx + '"]'), function (cell) { cell.classList.toggle("hl-s", on); });
        });
      }

      // ---- global toggle ----------------------------------------------------------------------------------------------
      function buildGlobalToggle() {
        var host = document.getElementById("global-toggle");
        if (!host) { return; }
        host.textContent = "";
        html("span", "toggle-label", "All plots", host);
        var seg = html("span", "seg", null, host);
        seg.setAttribute("role", "group");
        seg.setAttribute("aria-label", "Axis scale of all plots");
        globalButtons = {};
        ["log", "linear"].forEach(function (mode) {
          var b = html("button", "", mode === "log" ? "Log" : "Linear", seg);
          b.type = "button";
          b.addEventListener("click", function () { plots.forEach(function (plot) { plot.setMode(mode); }); });
          globalButtons[mode] = b;
        });
        syncGlobal();
        host.hidden = false;
      }
      var globalButtons = null;
      /** A global button is pressed only when every plot has that scale; with mixed plots neither is. */
      function syncGlobal() {
        if (!globalButtons) { return; }
        ["log", "linear"].forEach(function (mode) {
          var all = plots.length > 0 && plots.every(function (plot) { return plot.mode === mode; });
          globalButtons[mode].setAttribute("aria-pressed", String(all));
        });
      }

      function start() {
        Array.prototype.forEach.call(document.querySelectorAll(".plot"), function (root) {
          try { plots.push(new Plot(root)); } catch (error) { root.textContent = "The plot could not be drawn: " + error.message; }
        });
        buildGlobalToggle();
      }
      if (!hasDOM) {
        module.exports = {
          collect: collect, layoutFor: layoutFor, runs: runs, unionScales: unionScales, niceTicks: niceTicks, ratioTicks: ratioTicks,
          pickUnit: pickUnit, setData: function (value) { data = value; }
        };
        return;
      }
      if (document.readyState === "loading") { document.addEventListener("DOMContentLoaded", start); } else { start(); }
    })();
    """#
}
