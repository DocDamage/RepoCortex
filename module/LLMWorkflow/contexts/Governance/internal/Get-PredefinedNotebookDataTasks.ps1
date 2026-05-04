#requires -Version 5.1
Set-StrictMode -Version Latest

function Get-PredefinedNotebookDataTasks {
    [CmdletBinding()]
    [OutputType([array])]
    param()

    return @(
            # Task 1: Notebook Version Control
            (New-GoldenTask `
                -TaskId "gt-notebook-data-001" `
                -Name "Notebook version control" `
                -Description "Implement version control strategies for Jupyter notebooks" `
                -PackId "notebook-data" `
                -Category "integration" `
                -Difficulty "medium" `
                -Query "Show how to configure Git for Jupyter notebooks including cleaning output, using nbstripout, creating .gitattributes, and handling notebook diffs effectively." `
                -ExpectedResult @{
                    configuresGitAttributes = $true
                    mentionsNbstripout = $true
                    handlesOutputCleaning = $true
                    suggestsDiffTools = $true
                    providesPreCommitHooks = $true
                } `
                -RequiredEvidence @(
                    @{ source = "jupyter-git"; type = "source-reference" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("configuresGitAttributes", "handlesOutputCleaning")
                    forbiddenPatterns = @()
                    minConfidence = 0.8
                } `
                -Tags @("notebook", "jupyter", "git", "version-control", "nbstripout")
            ),

            # Task 2: Cell Output Caching
            (New-GoldenTask `
                -TaskId "gt-notebook-data-002" `
                -Name "Cell output caching" `
                -Description "Implement caching mechanisms for expensive cell computations" `
                -PackId "notebook-data" `
                -Category "codegen" `
                -Difficulty "medium" `
                -Query "Write Python code to implement cell output caching in Jupyter using @lru_cache, joblib.Memory, or ipycache to avoid re-running expensive computations." `
                -ExpectedResult @{
                    implementsCachingDecorator = $true
                    handlesCacheInvalidation = $true
                    showsJoblibMemory = $true
                } `
                -RequiredEvidence @(
                    @{ source = "python-cache"; type = "method-citation" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("implementsCachingDecorator", "handlesCacheInvalidation")
                    forbiddenPatterns = @()
                    minConfidence = 0.8
                } `
                -Tags @("notebook", "caching", "jupyter", "performance", "memoization")
            ),

            # Task 3: Data Lineage Tracking
            (New-GoldenTask `
                -TaskId "gt-notebook-data-003" `
                -Name "Data lineage tracking" `
                -Description "Track data flow and transformations through notebook cells" `
                -PackId "notebook-data" `
                -Category "analysis" `
                -Difficulty "hard" `
                -Query "Design a data lineage tracking system for Jupyter notebooks that captures variable dependencies, cell execution order, and data transformation chains." `
                -ExpectedResult @{
                    tracksVariableDependencies = $true
                    capturesExecutionOrder = $true
                    mapsDataTransformations = $true
                    providesLineageGraph = $true
                    handlesCellReruns = $true
                } `
                -RequiredEvidence @(
                    @{ source = "data-lineage"; type = "source-reference" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("tracksVariableDependencies", "capturesExecutionOrder", "mapsDataTransformations")
                    forbiddenPatterns = @()
                    minConfidence = 0.85
                } `
                -Tags @("notebook", "lineage", "dataflow", "tracking", "provenance")
            ),

            # Task 4: Pipeline Dependency Graph
            (New-GoldenTask `
                -TaskId "gt-notebook-data-004" `
                -Name "Pipeline dependency graph" `
                -Description "Build and visualize data pipeline dependency graphs" `
                -PackId "notebook-data" `
                -Category "codegen" `
                -Difficulty "medium" `
                -Query "Create Python code to build a dependency graph for a data processing pipeline using networkx, showing stages, dependencies, and generating a visual diagram." `
                -ExpectedResult @{
                    buildsDependencyGraph = $true
                    identifiesPipelineStages = $true
                    visualizesGraph = $true
                    detectsCycles = $true
                    showsExecutionOrder = $true
                } `
                -RequiredEvidence @(
                    @{ source = "networkx"; type = "source-reference" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("buildsDependencyGraph", "identifiesPipelineStages", "visualizesGraph")
                    forbiddenPatterns = @()
                    minConfidence = 0.8
                } `
                -Tags @("notebook", "pipeline", "dependency-graph", "visualization", "dag")
            ),

            # Task 5: Data Validation Rules
            (New-GoldenTask `
                -TaskId "gt-notebook-data-005" `
                -Name "Data validation rules" `
                -Description "Implement comprehensive data validation for dataframes" `
                -PackId "notebook-data" `
                -Category "codegen" `
                -Difficulty "medium" `
                -Query "Write Python code using pydantic, pandera, or great_expectations to validate pandas DataFrames with schema checks, constraints, and custom validation rules." `
                -ExpectedResult @{
                    definesSchemaConstraints = $true
                    validatesDataTypes = $true
                    checksNullValues = $true
                    validatesRanges = $true
                    providesValidationReport = $true
                } `
                -RequiredEvidence @(
                    @{ source = "pandas-validation"; type = "source-reference" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("definesSchemaConstraints", "validatesDataTypes", "providesValidationReport")
                    forbiddenPatterns = @()
                    minConfidence = 0.8
                } `
                -Tags @("notebook", "validation", "pandas", "schema", "data-quality")
            ),

            # Task 6: Visualization Generation
            (New-GoldenTask `
                -TaskId "gt-notebook-data-006" `
                -Name "Visualization generation" `
                -Description "Generate data visualizations optimized for notebooks" `
                -PackId "notebook-data" `
                -Category "codegen" `
                -Difficulty "easy" `
                -Query "Create Python code to generate matplotlib, seaborn, and plotly visualizations optimized for Jupyter notebooks with proper sizing, interactivity, and display settings." `
                -ExpectedResult @{
                    usesMatplotlib = $true
                    usesSeaborn = $true
                    usesPlotly = $true
                    optimizesForNotebook = $true
                    handlesInteractivePlots = $true
                    setsProperFigureSize = $true
                } `
                -RequiredEvidence @(
                    @{ source = "visualization"; type = "source-reference" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("usesMatplotlib", "optimizesForNotebook")
                    forbiddenPatterns = @()
                    minConfidence = 0.8
                } `
                -Tags @("notebook", "visualization", "matplotlib", "plotly", "seaborn")
            ),

            # Task 7: Dataset Profiling
            (New-GoldenTask `
                -TaskId "gt-notebook-data-007" `
                -Name "Dataset profiling" `
                -Description "Generate comprehensive dataset profiling reports" `
                -PackId "notebook-data" `
                -Category "analysis" `
                -Difficulty "easy" `
                -Query "Use ydata-profiling, sweetviz, or pandas-profiling to generate a comprehensive dataset report including statistics, distributions, correlations, and data quality alerts." `
                -ExpectedResult @{
                    generatesProfileReport = $true
                    includesStatistics = $true
                    showsDistributions = $true
                    analyzesCorrelations = $true
                    flagsDataQualityIssues = $true
                } `
                -RequiredEvidence @(
                    @{ source = "profiling"; type = "source-reference" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("generatesProfileReport", "includesStatistics", "flagsDataQualityIssues")
                    forbiddenPatterns = @()
                    minConfidence = 0.8
                } `
                -Tags @("notebook", "profiling", "eda", "data-quality", "statistics")
            ),

            # Task 8: Feature Engineering Pipeline
            (New-GoldenTask `
                -TaskId "gt-notebook-data-008" `
                -Name "Feature engineering pipeline" `
                -Description "Build reusable feature engineering pipelines with sklearn" `
                -PackId "notebook-data" `
                -Category "codegen" `
                -Difficulty "hard" `
                -Query "Create a scikit-learn Pipeline with ColumnTransformer for feature engineering including scaling, encoding, text vectorization, and custom transformers." `
                -ExpectedResult @{
                    usesPipeline = $true
                    usesColumnTransformer = $true
                    handlesNumericalFeatures = $true
                    handlesCategoricalFeatures = $true
                    includesCustomTransformer = $true
                    demonstratesFitTransform = $true
                } `
                -RequiredEvidence @(
                    @{ source = "sklearn"; type = "source-reference" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("usesPipeline", "usesColumnTransformer", "handlesNumericalFeatures")
                    forbiddenPatterns = @()
                    minConfidence = 0.85
                } `
                -Tags @("notebook", "feature-engineering", "sklearn", "pipeline", "ml")
            ),

            # Task 9: Model Training Tracking
            (New-GoldenTask `
                -TaskId "gt-notebook-data-009" `
                -Name "Model training tracking" `
                -Description "Track ML experiments and model training metrics" `
                -PackId "notebook-data" `
                -Category "integration" `
                -Difficulty "medium" `
                -Query "Implement experiment tracking in a Jupyter notebook using MLflow, wandb, or tensorboard to log parameters, metrics, artifacts, and model versions." `
                -ExpectedResult @{
                    logsParameters = $true
                    logsMetrics = $true
                    logsArtifacts = $true
                    tracksModelVersions = $true
                    providesExperimentComparison = $true
                } `
                -RequiredEvidence @(
                    @{ source = "mlflow"; type = "source-reference" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("logsParameters", "logsMetrics", "tracksModelVersions")
                    forbiddenPatterns = @()
                    minConfidence = 0.8
                } `
                -Tags @("notebook", "mlflow", "experiment-tracking", "ml", "logging")
            ),

            # Task 10: Experiment Comparison
            (New-GoldenTask `
                -TaskId "gt-notebook-data-010" `
                -Name "Experiment comparison" `
                -Description "Compare multiple ML experiments and generate comparison reports" `
                -PackId "notebook-data" `
                -Category "comparison" `
                -Difficulty "medium" `
                -Query "Write code to compare multiple ML experiment runs, generating visual comparisons of metrics, parameter diffs, and ranking models by performance criteria." `
                -ExpectedResult @{
                    comparesMultipleRuns = $true
                    visualizesMetricComparison = $true
                    showsParameterDiffs = $true
                    ranksModels = $true
                    generatesComparisonReport = $true
                } `
                -RequiredEvidence @(
                    @{ source = "experiment-comparison"; type = "source-reference" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("comparesMultipleRuns", "visualizesMetricComparison", "generatesComparisonReport")
                    forbiddenPatterns = @()
                    minConfidence = 0.8
                } `
                -Tags @("notebook", "experiment-comparison", "ml", "visualization", "benchmark")
            )
    )
}
