#requires -Version 5.1

BeforeAll {
    $script:ProjectRoot = Join-Path (Join-Path $PSScriptRoot '..') ''
    $modulePath = Join-Path $script:ProjectRoot 'module\LLMWorkflow\DashboardViews.ps1'
    . $modulePath
}

Describe 'Dashboard branding' {
    It 'brands single-view HTML dashboards as Repo Cortex' {
        $html = Show-PackHealthDashboard -ProjectRoot $script:ProjectRoot -OutputFormat HTML

        $html | Should -Match '<title>Repo Cortex Pack Health</title>'
        $html | Should -Match 'class="brand-header"'
        $html | Should -Match 'data-modern-ui="true"'
        $html | Should -Match 'class="modern-ui-rail"'
        $html | Should -Match 'Repo Cortex ModernUI mark'
        $html | Should -Match 'AI workflow operations, retrieval, governance, and memory telemetry'
        $html | Should -Not -Match '<title>Pack Health Dashboard</title>'
    }

    It 'brands combined HTML exports as Repo Cortex operations surfaces' {
        $exportPath = Join-Path $TestDrive 'repo-cortex-dashboard.html'
        $html = Export-DashboardHTML -Views @('Health', 'Gateway') -ProjectRoot $script:ProjectRoot -ExportPath $exportPath

        Test-Path -LiteralPath $exportPath | Should -Be $true
        $html | Should -Match '<title>Repo Cortex Operations Dashboard</title>'
        $html | Should -Match 'Repo Cortex Operations Dashboard'
        $html | Should -Match 'Views Health, Gateway'
        $html | Should -Not -Match '<h1>LLM Workflow Dashboard</h1>'
    }

    It 'loads ModernUI assets into combined HTML exports when available' {
        $exportPath = Join-Path $TestDrive 'modern-ui-dashboard.html'

        $html = Export-DashboardHTML -Views @('Health') -ProjectRoot $script:ProjectRoot -ExportPath $exportPath

        $html | Should -Match 'data-modern-ui="true"'
        $html | Should -Match 'class="modern-ui-banner"'
        $html | Should -Match 'data:image/png;base64,'
        ([regex]::Matches($html, 'data:image/(png|gif);base64,')).Count | Should -BeGreaterOrEqual 4
        $html | Should -Match 'Repo Cortex ModernUI mark'
    }

    It 'brands the interactive console dashboard header while preserving module compatibility text' {
        $output = & {
            Write-DashboardHeader -UseColors:$false
        } | Out-String

        $output | Should -Match 'Repo Cortex Dashboard v1\.0\.0'
        $output | Should -Match 'LLMWorkflow operations telemetry'
        $output | Should -Not -Match 'LLM WORKFLOW DASHBOARD v0\.9\.6'
    }
}
