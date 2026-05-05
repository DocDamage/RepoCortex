Set-StrictMode -Version Latest

$script:DashboardVersion = '1.0.0'
$script:DefaultDashboardDir = '.llm-workflow/dashboards'
$script:DefaultExportDir = '.llm-workflow/exports'
$script:ProductBrandName = 'Repo Cortex'
$script:ProductModuleName = 'LLMWorkflow'
$script:ProductBrandTagline = 'AI workflow operations, retrieval, governance, and memory telemetry'

# ANSI Color Codes for Console Output
$script:AnsiColors = @{
    Reset = "$([char]0x1B)[0m"
    Bold = "$([char]0x1B)[1m"
    Dim = "$([char]0x1B)[2m"
    Red = "$([char]0x1B)[31m"
    Green = "$([char]0x1B)[32m"
    Yellow = "$([char]0x1B)[33m"
    Blue = "$([char]0x1B)[34m"
    Magenta = "$([char]0x1B)[35m"
    Cyan = "$([char]0x1B)[36m"
    White = "$([char]0x1B)[37m"
    BrightRed = "$([char]0x1B)[91m"
    BrightGreen = "$([char]0x1B)[92m"
    BrightYellow = "$([char]0x1B)[93m"
    BrightBlue = "$([char]0x1B)[94m"
    BgRed = "$([char]0x1B)[41m"
    BgGreen = "$([char]0x1B)[42m"
    BgYellow = "$([char]0x1B)[43m"
}

# Status Color Mapping
$script:StatusColors = @{
    healthy = 'Green'
    degraded = 'Yellow'
    critical = 'Red'
    warning = 'Yellow'
    ok = 'Green'
    notice = 'Blue'
    compliant = 'Green'
    active = 'Green'
    inactive = 'Gray'
    suspended = 'Yellow'
    offline = 'Red'
    error = 'Red'
    closed = 'Green'
    open = 'Red'
    half_open = 'Yellow'
}

# HTML Theme Colors (Dark/Light)
$script:HtmlThemes = @{
    dark = @{
        bgColor = '#0b1020'
        cardBg = '#121a2f'
        textColor = '#edf4ff'
        mutedTextColor = '#9fb0ca'
        borderColor = '#263653'
        healthyColor = '#36d6a5'
        warningColor = '#f6c85f'
        criticalColor = '#ff6b7a'
        headerBg = '#10182d'
        accentColor = '#68d8ff'
        accentColor2 = '#9ef0c7'
        shadowColor = 'rgba(2, 8, 23, 0.38)'
        tableStripe = 'rgba(104, 216, 255, 0.05)'
    }
    light = @{
        bgColor = '#f7fafc'
        cardBg = '#ffffff'
        textColor = '#172033'
        mutedTextColor = '#5b6b83'
        borderColor = '#d8e1ee'
        healthyColor = '#118864'
        warningColor = '#a86500'
        criticalColor = '#c73045'
        headerBg = '#eef6fb'
        accentColor = '#096c91'
        accentColor2 = '#157a5b'
        shadowColor = 'rgba(23, 32, 51, 0.10)'
        tableStripe = 'rgba(9, 108, 145, 0.05)'
    }
}
