#requires -Version 5.1
Set-StrictMode -Version Latest

function New-GoldenTask {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^gt-[a-z0-9-]+-\d+$')]
        [string]$TaskId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [string]$Description = "",

        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[a-z0-9-]+$')]
        [string]$PackId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Query,

        [Parameter(Mandatory = $false)]
        [hashtable]$ExpectedResult = @{},

        [Parameter(Mandatory = $false)]
        [array]$RequiredEvidence = @(),

        [Parameter(Mandatory = $false)]
        [hashtable]$ValidationRules = @{},

        [Parameter(Mandatory = $false)]
        [ValidateSet('codegen', 'analysis', 'extraction', 'comparison', 'diagnosis', 'integration', 'validation')]
        [string]$Category = 'codegen',

        [Parameter(Mandatory = $false)]
        [ValidateSet('easy', 'medium', 'hard')]
        [string]$Difficulty = 'medium',

        [Parameter(Mandatory = $false)]
        [string[]]$Tags = @()
    )

    begin {
        Write-Verbose "Creating golden task: $TaskId"
    }

    process {
        # Validate task ID format (gt-{pack}-###)
        $expectedPrefix = "gt-$PackId-"
        if (-not $TaskId.StartsWith($expectedPrefix)) {
            Write-Warning "TaskId '$TaskId' does not follow convention 'gt-{pack}-###'. Expected prefix: '$expectedPrefix'"
        }

        # Set default validation rules
        $defaultValidationRules = @{
            propertyBased = $true
            requiredProperties = @($ExpectedResult.Keys)
            forbiddenPatterns = @()
            minConfidence = $script:GoldenTaskConfig.DefaultMinConfidence
            allowPartialMatch = $true
        }

        # Merge with provided rules
        $mergedRules = $defaultValidationRules.Clone()
        foreach ($key in $ValidationRules.Keys) {
            $mergedRules[$key] = $ValidationRules[$key]
        }

        $task = @{
            taskId = $TaskId
            name = $Name
            description = $Description
            packId = $PackId
            query = $Query
            expectedResult = $ExpectedResult
            requiredEvidence = $RequiredEvidence
            validationRules = $mergedRules
            category = $Category
            difficulty = $Difficulty
            tags = $Tags
            createdAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
            version = $script:GoldenTaskConfig.Version
        }

        Write-Verbose "Golden task '$TaskId' created successfully"
        return $task
    }
}
