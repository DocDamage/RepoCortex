#requires -Version 5.1
Set-StrictMode -Version Latest

function Get-PredefinedAgentSimTasks {
    [CmdletBinding()]
    [OutputType([array])]
    param()

    return @(
            # Task 1: Multi-Agent Setup
            (New-GoldenTask `
                -TaskId "gt-agent-sim-001" `
                -Name "Multi-agent setup" `
                -Description "Configure and initialize a multi-agent simulation environment" `
                -PackId "agent-sim" `
                -Category "codegen" `
                -Difficulty "medium" `
                -Query "Create a multi-agent simulation setup using Python with agent definitions, environment state, agent communication channels, and coordination mechanisms." `
                -ExpectedResult @{
                    definesAgentClass = $true
                    initializesMultipleAgents = $true
                    setsUpCommunication = $true
                    definesEnvironmentState = $true
                    implementsCoordination = $true
                } `
                -RequiredEvidence @(
                    @{ source = "multi-agent"; type = "source-reference" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("definesAgentClass", "initializesMultipleAgents", "setsUpCommunication")
                    forbiddenPatterns = @()
                    minConfidence = 0.8
                } `
                -Tags @("agent", "multi-agent", "simulation", "coordination", "mas")
            ),

            # Task 2: Reward Function Design
            (New-GoldenTask `
                -TaskId "gt-agent-sim-002" `
                -Name "Reward function design" `
                -Description "Design and implement reward functions for reinforcement learning agents" `
                -PackId "agent-sim" `
                -Category "codegen" `
                -Difficulty "hard" `
                -Query "Design a reward function for an RL agent including sparse vs dense rewards, shaping techniques, multi-objective weighting, and penalty structures." `
                -ExpectedResult @{
                    implementsSparseReward = $true
                    implementsDenseReward = $true
                    includesRewardShaping = $true
                    handlesMultiObjective = $true
                    definesPenaltyStructure = $true
                } `
                -RequiredEvidence @(
                    @{ source = "rl-rewards"; type = "source-reference" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("implementsDenseReward", "includesRewardShaping", "definesPenaltyStructure")
                    forbiddenPatterns = @()
                    minConfidence = 0.85
                } `
                -Tags @("agent", "rl", "reward-function", "reinforcement-learning", "shaping")
            ),

            # Task 3: Trajectory Analysis
            (New-GoldenTask `
                -TaskId "gt-agent-sim-003" `
                -Name "Trajectory analysis" `
                -Description "Analyze agent behavior trajectories and state transitions" `
                -PackId "agent-sim" `
                -Category "analysis" `
                -Difficulty "medium" `
                -Query "Write code to analyze agent trajectories including state-action sequences, path optimization, divergence detection, and trajectory clustering." `
                -ExpectedResult @{
                    analyzesStateActionSequences = $true
                    detectsPathPatterns = $true
                    identifiesDivergences = $true
                    clustersTrajectories = $true
                    calculatesPathMetrics = $true
                } `
                -RequiredEvidence @(
                    @{ source = "trajectory-analysis"; type = "source-reference" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("analyzesStateActionSequences", "identifiesDivergences", "clustersTrajectories")
                    forbiddenPatterns = @()
                    minConfidence = 0.8
                } `
                -Tags @("agent", "trajectory", "analysis", "behavior", "paths")
            ),

            # Task 4: A/B Testing Framework
            (New-GoldenTask `
                -TaskId "gt-agent-sim-004" `
                -Name "A/B testing framework" `
                -Description "Implement A/B testing for comparing agent policies or behaviors" `
                -PackId "agent-sim" `
                -Category "integration" `
                -Difficulty "medium" `
                -Query "Create an A/B testing framework for agent policies including random assignment, statistical significance testing, confidence intervals, and performance comparison." `
                -ExpectedResult @{
                    implementsRandomAssignment = $true
                    calculatesStatisticalSignificance = $true
                    computesConfidenceIntervals = $true
                    comparesPolicies = $true
                    handlesSampleSizeCalculation = $true
                } `
                -RequiredEvidence @(
                    @{ source = "ab-testing"; type = "source-reference" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("implementsRandomAssignment", "calculatesStatisticalSignificance", "comparesPolicies")
                    forbiddenPatterns = @()
                    minConfidence = 0.8
                } `
                -Tags @("agent", "ab-testing", "statistics", "policy-comparison", "experiment")
            ),

            # Task 5: Environment Configuration
            (New-GoldenTask `
                -TaskId "gt-agent-sim-005" `
                -Name "Environment configuration" `
                -Description "Configure simulation environments with Gymnasium/PettingZoo" `
                -PackId "agent-sim" `
                -Category "codegen" `
                -Difficulty "medium" `
                -Query "Create a custom Gymnasium environment with proper observation/action spaces, reset/step methods, rendering, and environment registration." `
                -ExpectedResult @{
                    extendsGymEnv = $true
                    definesObservationSpace = $true
                    definesActionSpace = $true
                    implementsReset = $true
                    implementsStep = $true
                    registersEnvironment = $true
                } `
                -RequiredEvidence @(
                    @{ source = "gymnasium"; type = "source-reference" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("extendsGymEnv", "implementsReset", "implementsStep")
                    forbiddenPatterns = @()
                    minConfidence = 0.8
                } `
                -Tags @("agent", "gymnasium", "environment", "rl", "simulation")
            ),

            # Task 6: Agent Behavior Validation
            (New-GoldenTask `
                -TaskId "gt-agent-sim-006" `
                -Name "Agent behavior validation" `
                -Description "Validate agent behaviors against expected policies and constraints" `
                -PackId "agent-sim" `
                -Category "validation" `
                -Difficulty "medium" `
                -Query "Implement validation tests for agent behaviors including policy conformance checking, safety constraint validation, and behavioral invariants." `
                -ExpectedResult @{
                    validatesPolicyConformance = $true
                    checksSafetyConstraints = $true
                    verifiesBehavioralInvariants = $true
                    testsEdgeCases = $true
                    providesValidationReport = $true
                } `
                -RequiredEvidence @(
                    @{ source = "behavior-validation"; type = "source-reference" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("validatesPolicyConformance", "checksSafetyConstraints", "providesValidationReport")
                    forbiddenPatterns = @()
                    minConfidence = 0.8
                } `
                -Tags @("agent", "validation", "behavior", "safety", "testing")
            ),

            # Task 7: Policy Optimization
            (New-GoldenTask `
                -TaskId "gt-agent-sim-007" `
                -Name "Policy optimization" `
                -Description "Implement policy gradient and optimization algorithms" `
                -PackId "agent-sim" `
                -Category "codegen" `
                -Difficulty "hard" `
                -Query "Implement a policy gradient algorithm (REINFORCE, PPO, or A2C) with neural network policy, value function, and training loop." `
                -ExpectedResult @{
                    implementsPolicyNetwork = $true
                    implementsValueFunction = $true
                    calculatesPolicyGradient = $true
                    includesTrainingLoop = $true
                    handlesAdvantageEstimation = $true
                } `
                -RequiredEvidence @(
                    @{ source = "policy-gradient"; type = "source-reference" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("implementsPolicyNetwork", "calculatesPolicyGradient", "includesTrainingLoop")
                    forbiddenPatterns = @()
                    minConfidence = 0.85
                } `
                -Tags @("agent", "policy-gradient", "ppo", "reinforcement-learning", "optimization")
            ),

            # Task 8: Simulation Replay
            (New-GoldenTask `
                -TaskId "gt-agent-sim-008" `
                -Name "Simulation replay" `
                -Description "Record and replay simulation episodes for debugging and analysis" `
                -PackId "agent-sim" `
                -Category "codegen" `
                -Difficulty "medium" `
                -Query "Create a simulation replay system that records episodes (states, actions, rewards) and supports playback, stepping, and event inspection." `
                -ExpectedResult @{
                    recordsEpisodeData = $true
                    supportsPlayback = $true
                    allowsStepping = $true
                    inspectsEvents = $true
                    savesReplayFiles = $true
                } `
                -RequiredEvidence @(
                    @{ source = "simulation-replay"; type = "source-reference" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("recordsEpisodeData", "supportsPlayback", "allowsStepping")
                    forbiddenPatterns = @()
                    minConfidence = 0.8
                } `
                -Tags @("agent", "replay", "simulation", "debugging", "recording")
            ),

            # Task 9: Metrics Collection
            (New-GoldenTask `
                -TaskId "gt-agent-sim-009" `
                -Name "Metrics collection" `
                -Description "Collect and aggregate agent performance metrics" `
                -PackId "agent-sim" `
                -Category "integration" `
                -Difficulty "easy" `
                -Query "Implement a metrics collection system for agents including episode rewards, success rates, convergence tracking, and custom metric aggregation." `
                -ExpectedResult @{
                    tracksEpisodeRewards = $true
                    calculatesSuccessRates = $true
                    monitorsConvergence = $true
                    aggregatesStatistics = $true
                    exportsMetricsData = $true
                } `
                -RequiredEvidence @(
                    @{ source = "metrics"; type = "source-reference" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("tracksEpisodeRewards", "calculatesSuccessRates", "monitorsConvergence")
                    forbiddenPatterns = @()
                    minConfidence = 0.8
                } `
                -Tags @("agent", "metrics", "performance", "monitoring", "statistics")
            ),

            # Task 10: Agent Collaboration Patterns
            (New-GoldenTask `
                -TaskId "gt-agent-sim-010" `
                -Name "Agent collaboration patterns" `
                -Description "Implement collaboration patterns for multi-agent systems" `
                -PackId "agent-sim" `
                -Category "codegen" `
                -Difficulty "hard" `
                -Query "Implement agent collaboration patterns including auction-based allocation, consensus algorithms, shared memory, and emergent coordination strategies." `
                -ExpectedResult @{
                    implementsAuctionMechanism = $true
                    implementsConsensus = $true
                    usesSharedMemory = $true
                    demonstratesEmergentCoordination = $true
                    handlesCommunicationOverhead = $true
                } `
                -RequiredEvidence @(
                    @{ source = "collaboration"; type = "source-reference" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("implementsAuctionMechanism", "implementsConsensus", "demonstratesEmergentCoordination")
                    forbiddenPatterns = @()
                    minConfidence = 0.85
                } `
                -Tags @("agent", "collaboration", "multi-agent", "coordination", "distributed")
            )
    )
}
