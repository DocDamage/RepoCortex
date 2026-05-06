#requires -Version 5.1
$ErrorActionPreference = 'Stop'

Describe "Module import performance" {
    It "should import in under 5 seconds" {
        $elapsed = Measure-Command { Import-Module .\module\LLMWorkflow\LLMWorkflow.psd1 -Force }
        $elapsed.TotalSeconds | Should -BeLessThan 5
    }
}
