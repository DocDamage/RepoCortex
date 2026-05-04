Set-StrictMode -Version Latest

$script:DashboardVersion = '1.0.0'
$script:DefaultDashboardDir = '.llm-workflow/dashboards'
$script:DefaultExportDir = '.llm-workflow/exports'

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
        bgColor = '#1e1e1e'
        cardBg = '#252526'
        textColor = '#d4d4d4'
        borderColor = '#3e3e42'
        healthyColor = '#4ec9b0'
        warningColor = '#dcdcaa'
        criticalColor = '#f44747'
        headerBg = '#2d2d30'
        accentColor = '#569cd6'
    }
    light = @{
        bgColor = '#ffffff'
        cardBg = '#f5f5f5'
        textColor = '#333333'
        borderColor = '#e0e0e0'
        healthyColor = '#28a745'
        warningColor = '#ffc107'
        criticalColor = '#dc3545'
        headerBg = '#f8f9fa'
        accentColor = '#007bff'
    }
}
