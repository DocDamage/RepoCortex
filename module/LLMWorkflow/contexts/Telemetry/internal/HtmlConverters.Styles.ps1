Set-StrictMode -Version Latest

function Get-DashboardHtmlStyles {
    param($ThemeColors)

    return @"
        :root {
            --rc-bg: $($ThemeColors.bgColor); --rc-surface: $($ThemeColors.cardBg);
            --rc-surface-strong: $($ThemeColors.headerBg); --rc-text: $($ThemeColors.textColor);
            --rc-muted: $($ThemeColors.mutedTextColor); --rc-border: $($ThemeColors.borderColor);
            --rc-accent: $($ThemeColors.accentColor); --rc-accent-2: $($ThemeColors.accentColor2);
            --rc-good: $($ThemeColors.healthyColor); --rc-warn: $($ThemeColors.warningColor);
            --rc-bad: $($ThemeColors.criticalColor); --rc-shadow: $($ThemeColors.shadowColor);
            --rc-stripe: $($ThemeColors.tableStripe);
        }
        * { box-sizing: border-box; }
        body {
            margin: 0; color: var(--rc-text); line-height: 1.5; padding: 28px;
            font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            background:
                radial-gradient(circle at top left, color-mix(in srgb, var(--rc-accent) 18%, transparent), transparent 30rem),
                linear-gradient(180deg, var(--rc-bg), var(--rc-bg));
        }
        .page-shell { max-width: 1440px; margin: 0 auto; }
        .brand-header {
            display: flex; justify-content: space-between; align-items: flex-end;
            gap: 24px; padding: 24px; margin-bottom: 22px;
            background: linear-gradient(135deg, var(--rc-surface-strong), var(--rc-surface));
            border: 1px solid var(--rc-border); border-radius: 8px;
            box-shadow: 0 18px 50px var(--rc-shadow);
        }
        .brand-lockup { display: flex; align-items: center; gap: 16px; min-width: 0; }
        .brand-mark {
            width: 52px; height: 52px; display: grid; place-items: center; flex: 0 0 auto;
            border: 1px solid color-mix(in srgb, var(--rc-accent) 45%, var(--rc-border));
            border-radius: 8px;
            background: linear-gradient(135deg, color-mix(in srgb, var(--rc-accent) 28%, transparent), color-mix(in srgb, var(--rc-accent-2) 24%, transparent));
            color: var(--rc-text); font-weight: 800; letter-spacing: 0;
        }
        .brand-mark-image {
            padding: 8px; object-fit: contain; image-rendering: pixelated;
            background: color-mix(in srgb, var(--rc-surface) 82%, white);
        }
        body[data-modern-ui="true"] {
            --rc-bg: #162033; --rc-surface: #23314a; --rc-surface-strong: #f6f3df;
            --rc-text: #fdf7e8; --rc-muted: #d7e0f2; --rc-border: #384a68;
            --rc-accent: #22d3ee; --rc-accent-2: #ff5fb8;
            --rc-stripe: rgba(255, 255, 255, 0.07);
            background:
                linear-gradient(90deg, rgba(34, 211, 238, 0.18) 0 16px, transparent 16px 32px),
                linear-gradient(180deg, #162033 0%, #263655 52%, #1b263b 100%);
        }
        body[data-modern-ui="true"] .page-shell {
            display: grid; grid-template-columns: 84px minmax(0, 1fr);
            gap: 18px; max-width: 1520px;
        }
        body[data-modern-ui="true"] .brand-header {
            grid-column: 2; align-items: center; min-height: 124px;
            background:
                linear-gradient(90deg, #ffdd57 0 10px, transparent 10px),
                linear-gradient(135deg, #21324f 0%, #5a3f7b 46%, #234f5d 100%);
            border: 3px solid #f6f3df; box-shadow: 8px 8px 0 rgba(0, 0, 0, 0.36);
        }
        body[data-modern-ui="true"] .brand-mark {
            width: 78px; height: 78px; border: 3px solid #1d2435;
            border-radius: 6px; background: #f6f3df; box-shadow: 5px 5px 0 rgba(0, 0, 0, 0.25);
        }
        body[data-modern-ui="true"] .brand-mark-image { padding: 11px; }
        body[data-modern-ui="true"] .brand-title { color: #fff8e7; text-shadow: 2px 2px 0 #172033; }
        body[data-modern-ui="true"] .brand-subtitle { color: #f6f3df; }
        body[data-modern-ui="true"] .meta-chip {
            color: #172033; background: #f6f3df; border: 2px solid #172033;
            box-shadow: 3px 3px 0 rgba(0, 0, 0, 0.22);
        }
        .modern-ui-rail {
            grid-column: 1; grid-row: 1 / span 2; position: sticky; top: 18px;
            align-self: start; display: flex; flex-direction: column; gap: 12px;
            padding: 12px; min-height: 420px; background: #f6f3df;
            border: 3px solid #172033; border-radius: 8px; box-shadow: 8px 8px 0 rgba(0, 0, 0, 0.32);
        }
        .modern-ui-button {
            min-height: 64px; display: grid; place-items: center; gap: 4px;
            padding: 8px 4px; border: 2px solid #172033; border-radius: 6px;
            background: #2d3f61; color: #fff8e7; font-size: 0.66rem;
            font-weight: 800; text-transform: uppercase; box-shadow: 3px 3px 0 rgba(0, 0, 0, 0.28);
        }
        .modern-ui-button.is-active { background: #ff5fb8; color: #172033; }
        .modern-ui-button img,
        .modern-ui-banner img,
        .modern-ui-corner img {
            width: 32px; height: 32px; object-fit: contain; image-rendering: pixelated;
        }
        .modern-ui-banner {
            grid-column: 2; display: grid; grid-template-columns: repeat(3, minmax(0, 1fr));
            gap: 12px; margin-bottom: 18px;
        }
        .modern-ui-panel {
            min-height: 86px; display: flex; align-items: center; gap: 14px;
            padding: 14px; background: #f6f3df; color: #172033;
            border: 3px solid #172033; border-radius: 8px; box-shadow: 5px 5px 0 rgba(0, 0, 0, 0.24);
        }
        .modern-ui-panel img { width: 48px; height: 48px; object-fit: contain; image-rendering: pixelated; }
        .modern-ui-panel strong { display: block; font-size: 0.82rem; text-transform: uppercase; }
        .modern-ui-panel span { color: #46516a; font-size: 0.8rem; font-weight: 700; }
        body[data-modern-ui="true"] .dashboard-grid { grid-column: 2; }
        body[data-modern-ui="true"] .card {
            background: #23314a; border: 3px solid #f6f3df;
            box-shadow: 7px 7px 0 rgba(0, 0, 0, 0.24);
        }
        body[data-modern-ui="true"] .metric {
            background: #f6f3df; color: #172033; border: 2px solid #172033;
            box-shadow: 3px 3px 0 rgba(0, 0, 0, 0.22);
        }
        body[data-modern-ui="true"] .metric-value,
        body[data-modern-ui="true"] .metric-label { color: #172033; }
        .brand-title { margin: 0; color: var(--rc-text); font-size: clamp(1.55rem, 2.4vw, 2.25rem); line-height: 1.05; letter-spacing: 0; }
        .brand-subtitle { margin-top: 6px; color: var(--rc-muted); font-size: 0.95rem; }
        .brand-meta {
            display: flex; flex-wrap: wrap; justify-content: flex-end; gap: 8px;
            color: var(--rc-muted); font-size: 0.82rem;
        }
        .meta-chip { border: 1px solid var(--rc-border); border-radius: 8px; padding: 6px 9px; background: color-mix(in srgb, var(--rc-surface) 82%, transparent); white-space: nowrap; }
        .dashboard-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(360px, 1fr)); gap: 18px; align-items: start; }
        .card {
            background: var(--rc-surface); border: 1px solid var(--rc-border); border-radius: 8px;
            padding: 20px; margin-bottom: 18px; box-shadow: 0 12px 32px var(--rc-shadow); overflow: hidden;
        }
        .card h2, .card h3 { color: var(--rc-text); margin: 0 0 14px; letter-spacing: 0; }
        .card h2 { font-size: 1.08rem; padding-bottom: 10px; border-bottom: 1px solid var(--rc-border); }
        .card h3 { margin-top: 18px; font-size: 0.92rem; color: var(--rc-muted); text-transform: uppercase; }
        .metric-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(118px, 1fr)); gap: 12px; margin-bottom: 18px; }
        .metric {
            min-height: 88px; display: flex; flex-direction: column; justify-content: center;
            gap: 4px; padding: 14px;
            background: color-mix(in srgb, var(--rc-bg) 55%, var(--rc-surface));
            border: 1px solid color-mix(in srgb, var(--rc-border) 70%, transparent);
            border-radius: 8px;
        }
        .metric-value { color: var(--rc-text); font-size: 1.65rem; line-height: 1; font-weight: 800; }
        .metric-label { color: var(--rc-muted); font-size: 0.78rem; font-weight: 600; text-transform: uppercase; }
        .status-healthy { color: var(--rc-good); }
        .status-warning { color: var(--rc-warn); }
        .status-critical { color: var(--rc-bad); }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; font-size: 0.9rem; }
        th, td {
            padding: 10px 12px; text-align: left;
            border-bottom: 1px solid var(--rc-border); vertical-align: middle;
        }
        th {
            color: var(--rc-muted); background: var(--rc-stripe);
            font-size: 0.76rem; font-weight: 700; text-transform: uppercase;
        }
        tr:hover { background: var(--rc-stripe); }
        .badge {
            display: inline-flex; align-items: center; min-height: 24px; padding: 3px 8px;
            border-radius: 8px; font-size: 0.75rem; font-weight: 700; border: 1px solid currentColor;
        }
        .badge-healthy { background: color-mix(in srgb, var(--rc-good) 14%, transparent); color: var(--rc-good); }
        .badge-warning { background: color-mix(in srgb, var(--rc-warn) 16%, transparent); color: var(--rc-warn); }
        .badge-critical { background: color-mix(in srgb, var(--rc-bad) 14%, transparent); color: var(--rc-bad); }
        pre {
            background: color-mix(in srgb, var(--rc-bg) 62%, black); padding: 15px;
            border-radius: 8px; overflow-x: auto;
            font-family: 'Cascadia Mono', 'Consolas', 'Monaco', monospace;
            font-size: 0.84rem; color: var(--rc-text);
        }
        .mermaid { text-align: left; padding: 0; }
        @media (max-width: 760px) {
            body { padding: 14px; }
            body[data-modern-ui="true"] .page-shell { display: block; }
            .modern-ui-rail {
                position: static; min-height: 0; flex-direction: row;
                overflow-x: auto; margin-bottom: 14px;
            }
            .modern-ui-button { min-width: 72px; }
            .modern-ui-banner { grid-template-columns: 1fr; }
            .brand-header { align-items: flex-start; flex-direction: column; padding: 18px; }
            .brand-lockup { align-items: flex-start; flex-direction: column; gap: 12px; }
            .brand-meta { justify-content: flex-start; }
            .dashboard-grid { grid-template-columns: 1fr; }
            .card { padding: 15px; }
            table { display: block; overflow-x: auto; white-space: nowrap; }
        }
"@
}
