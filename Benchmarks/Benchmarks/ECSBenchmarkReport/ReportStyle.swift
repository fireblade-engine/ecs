// The inline stylesheet of the HTML report. Colours are tokens on :root, redefined for dark mode; series colours are Okabe-Ito
// based (colour-blind safe) with the dark variants lightened for contrast, and error bars use a darker (light theme) or lighter
// (dark theme) shade of the series hue so they stand apart from lines and markers.
enum ReportStyle {
    static let css = #"""
    :root {
      color-scheme: light dark;
      --bg: #ffffff; --fg: #1f2328; --muted: #59636e; --border: #d1d9e0; --card: #f6f8fa; --accent: #0969da;
      --grid: #c3cad2; --minor: #e6e9ed; --axis: #59636e; --zone: #59636e;
      --faster-bg: #dafbe1; --slower-bg: #ffebe9; --neutral-bg: transparent; --faster-fg: #116329; --slower-fg: #a40e26;
      --tip-bg: #ffffff; --tip-fg: #1f2328; --code-bg: #eff2f5;
      --c0: #0072B2; --c1: #D55E00; --c2: #009E73; --c3: #CC79A7; --c4: #E69F00; --c5: #56B4E9; --c6: #6E6E6E;
      --e0: #003959; --e1: #6A2F00; --e2: #004F3A; --e3: #663C54; --e4: #735000; --e5: #2B5A74; --e6: #373737;
    }
    @media (prefers-color-scheme: dark) {
      :root {
        --bg: #0d1117; --fg: #e6edf3; --muted: #9198a1; --border: #3d444d; --card: #151b23; --accent: #4493f8;
        --grid: #4a525c; --minor: #2d333b; --axis: #9198a1; --zone: #9198a1;
        --faster-bg: #12261e; --slower-bg: #3c1618; --faster-fg: #7ee787; --slower-fg: #ffa198;
        --tip-bg: #1c2128; --tip-fg: #e6edf3; --code-bg: #262c36;
        --c0: #5AB4F0; --c1: #F28C42; --c2: #2FD0A0; --c3: #E69BC4; --c4: #F2B83A; --c5: #8FD0F5; --c6: #B4B4B4;
        --e0: #A4D6F7; --e1: #F8C097; --e2: #8DE5CB; --e3: #F1C8DF; --e4: #F8D893; --e5: #C1E5FA; --e6: #D6D6D6;
      }
    }
    * { box-sizing: border-box; }
    html { scroll-behavior: smooth; }
    body {
      margin: 0; background: var(--bg); color: var(--fg);
      font: 15px/1.55 "Segoe UI", Roboto, "Helvetica Neue", Helvetica, Arial, sans-serif;
      overflow-wrap: anywhere;
    }
    main, header.top, nav.toc, .bar-inner { max-width: 1200px; margin: 0 auto; padding-left: 16px; padding-right: 16px; }
    header.top { padding-top: 24px; }
    h1 { font-size: 1.7rem; line-height: 1.25; margin: 0 0 8px; }
    h2 { font-size: 1.35rem; margin: 2.2rem 0 .6rem; padding-bottom: .25rem; border-bottom: 1px solid var(--border); }
    h3 { font-size: 1.1rem; margin: 1.6rem 0 .5rem; }
    h4 { font-size: 1rem; margin: 1.2rem 0 .4rem; }
    p, ul, blockquote { margin: .5rem 0; }
    ul { padding-left: 1.3rem; }
    li { margin: .2rem 0; }
    a { color: var(--accent); }
    code { background: var(--code-bg); padding: .08em .35em; border-radius: 4px; font: .9em Menlo, Consolas, "DejaVu Sans Mono", monospace; }
    blockquote { border-left: 4px solid var(--accent); background: var(--card); padding: .1rem 1rem; border-radius: 0 6px 6px 0; }
    .muted { color: var(--muted); }
    nav.toc { padding-top: 8px; }
    nav.toc ul { columns: 2 280px; column-gap: 24px; list-style: none; padding: 0; }
    nav.toc li { break-inside: avoid; }
    nav.toc .jump { margin-bottom: 4px; }
    .bar { position: sticky; top: 0; z-index: 5; background: var(--bg); border-bottom: 1px solid var(--border); }
    .bar-inner { display: flex; gap: 12px; align-items: center; padding-top: 8px; padding-bottom: 8px; flex-wrap: wrap; }
    .seg { display: inline-flex; border: 1px solid var(--border); border-radius: 6px; overflow: hidden; }
    .seg button { font: inherit; font-size: .85rem; padding: 3px 12px; border: 0; background: var(--card); color: var(--fg); cursor: pointer; }
    .seg button + button { border-left: 1px solid var(--border); }
    .seg button[aria-pressed="true"] { background: var(--accent); color: #fff; }
    .seg button:focus-visible, .pt:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
    .toggle-label { font-size: .85rem; color: var(--muted); }
    .facts { display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 8px 24px; margin: 12px 0; }
    .fact { background: var(--card); border: 1px solid var(--border); border-radius: 8px; padding: 8px 12px; min-width: 0; }
    .fact dt { font-size: .75rem; text-transform: uppercase; letter-spacing: .04em; color: var(--muted); }
    .fact dd { margin: 0; }
    .table-wrap { overflow-x: auto; max-width: 100%; margin: .6rem 0 1rem; border: 1px solid var(--border); border-radius: 6px; }
    table { border-collapse: collapse; font-size: .85rem; width: max-content; min-width: 100%; }
    th, td { border: 1px solid var(--border); padding: 3px 8px; white-space: nowrap; overflow-wrap: normal; }
    thead th { background: var(--card); text-align: center; font-weight: 600; }
    td { text-align: right; font-variant-numeric: tabular-nums; }
    td.lbl { text-align: left; font-weight: 600; background: var(--card); }
    table.kv td, table.kv th { white-space: normal; text-align: left; font-variant-numeric: normal; }
    td.v-faster { background: var(--faster-bg); }
    td.v-slower { background: var(--slower-bg); }
    td.v-equivalent, td.v-inconclusive, td.v-unavailable { background: var(--neutral-bg); }
    td.verdict { font-weight: 600; }
    td.v-faster.verdict { color: var(--faster-fg); }
    td.v-slower.verdict { color: var(--slower-fg); }
    .sym { display: inline-block; width: 1.1em; text-align: center; }
    tr.hl td { box-shadow: inset 0 2px 0 var(--accent), inset 0 -2px 0 var(--accent); }
    tr.hl td.hl-s { box-shadow: inset 0 0 0 2px var(--accent); font-weight: 700; }
    section.workload { scroll-margin-top: 60px; }
    details { margin: .8rem 0; }
    summary { cursor: pointer; font-weight: 600; }
    .plots { display: grid; grid-template-columns: repeat(auto-fit, minmax(min(100%, 520px), 1fr)); gap: 16px; margin: 12px 0; }
    .plot { min-width: 0; border: 1px solid var(--border); border-radius: 8px; padding: 8px 10px 10px; background: var(--bg); }
    .plot-bar { display: flex; justify-content: space-between; align-items: center; gap: 8px; flex-wrap: wrap; }
    .plot-title { font-size: .9rem; }
    .plot-frame { position: relative; }
    .plot-svg { width: 100%; height: auto; display: block; }
    .plot .empty { color: var(--muted); padding: 2rem 0; text-align: center; }
    .legend { display: flex; flex-wrap: wrap; gap: 4px 16px; font-size: .8rem; margin-top: 4px; }
    .legend-item { display: inline-flex; align-items: center; gap: 6px; }
    .notes { font-size: .75rem; color: var(--muted); margin: 6px 0 0; }
    .tip {
      position: absolute; z-index: 3; pointer-events: none; background: var(--tip-bg); color: var(--tip-fg); border: 1px solid var(--border);
      border-radius: 6px; box-shadow: 0 4px 14px rgba(0, 0, 0, .25); padding: 6px 9px; font-size: .78rem; line-height: 1.4; max-width: 280px;
    }
    .tip[hidden] { display: none; }
    .tip-head { font-weight: 600; }
    svg text { fill: var(--fg); font-family: "Segoe UI", Roboto, "Helvetica Neue", Helvetica, Arial, sans-serif; }
    svg .tick { font-size: 12px; } svg .axis-title { font-size: 13px; }
    svg .grid { stroke: var(--grid); stroke-width: 1; } svg .minor { stroke: var(--minor); stroke-width: 1; }
    svg .axis, svg .frame { stroke: var(--axis); stroke-width: 1; } svg .frame { fill: none; }
    svg .zone { fill: var(--zone); fill-opacity: .14; } svg .ref { stroke: var(--fg); stroke-dasharray: 2 3; }
    svg .line { fill: none; stroke: currentColor; stroke-width: 2; stroke-linejoin: round; } svg .line.baseline { stroke-dasharray: 7 4; }
    svg .band { fill: currentColor; fill-opacity: .16; stroke: currentColor; stroke-opacity: .4; stroke-linejoin: round; }
    svg .ribbon { fill: currentColor; fill-opacity: .2; stroke: none; }
    svg .marker { fill: currentColor; stroke: currentColor; stroke-width: 1.4; } svg .marker.hollow { fill: var(--bg); }
    svg .errbar { fill: none; stroke: currentColor; stroke-width: 2.4; stroke-linecap: butt; pointer-events: none; }
    svg .hit { fill: transparent; stroke: none; } svg .pt { cursor: pointer; outline: none; }
    svg .pt:hover .marker, svg .pt:focus .marker { stroke-width: 3; }
    svg .crosshair { pointer-events: none; }
    svg .xh-line { stroke: var(--fg); stroke-width: 1; stroke-dasharray: 4 3; opacity: .75; }
    svg .xh-box { fill: var(--accent); } svg .xh-text { fill: #fff; font-size: 12px; font-weight: 600; }
    .c0 { color: var(--c0); } .c1 { color: var(--c1); } .c2 { color: var(--c2); } .c3 { color: var(--c3); } .c4 { color: var(--c4); } .c5 { color: var(--c5); } .c6 { color: var(--c6); }
    .errbar.e0 { color: var(--e0); } .errbar.e1 { color: var(--e1); } .errbar.e2 { color: var(--e2); } .errbar.e3 { color: var(--e3); }
    .errbar.e4 { color: var(--e4); } .errbar.e5 { color: var(--e5); } .errbar.e6 { color: var(--e6); }
    @media (max-width: 600px) {
      body { font-size: 14px; }
      h1 { font-size: 1.35rem; }
      nav.toc ul { columns: 1; }
    }
    """#
}
