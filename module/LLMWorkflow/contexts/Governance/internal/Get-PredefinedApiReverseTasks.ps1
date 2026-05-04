#requires -Version 5.1
Set-StrictMode -Version Latest

function Get-PredefinedApiReverseTasks {
    [CmdletBinding()]
    [OutputType([array])]
    param()

    return @(
            # Task 1: API Endpoint Discovery
            (New-GoldenTask `
                -TaskId "gt-api-reverse-001" `
                -Name "API endpoint discovery" `
                -Description "Discover and catalog API endpoints from traffic or documentation" `
                -PackId "api-reverse" `
                -Category "analysis" `
                -Difficulty "medium" `
                -Query "Analyze HTTP traffic logs to discover REST API endpoints, extract their paths, HTTP methods, and identify resource patterns. Return a structured catalog." `
                -ExpectedResult @{
                    identifiesEndpoints = $true
                    extractsHttpMethods = $true
                    recognizesResourcePatterns = $true
                    structuresCatalog = $true
                    identifiesBaseUrl = $true
                } `
                -RequiredEvidence @(
                    @{ source = "http-traffic"; type = "source-reference" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("identifiesEndpoints", "extractsHttpMethods", "recognizesResourcePatterns")
                    forbiddenPatterns = @()
                    minConfidence = 0.8
                } `
                -Tags @("api", "discovery", "endpoints", "rest", "traffic-analysis")
            ),

            # Task 2: Schema Inference from Traffic
            (New-GoldenTask `
                -TaskId "gt-api-reverse-002" `
                -Name "Schema inference from traffic" `
                -Description "Infer data schemas from API request/response payloads" `
                -PackId "api-reverse" `
                -Category "analysis" `
                -Difficulty "medium" `
                -Query "Given sample JSON request/response payloads from an API, infer the complete data schemas including types, required fields, and nested structures." `
                -ExpectedResult @{
                    infersTypes = $true
                    identifiesRequiredFields = $true
                    handlesNestedStructures = $true
                    detectsEnums = $true
                    providesJsonSchema = $true
                } `
                -RequiredEvidence @(
                    @{ source = "json-payloads"; type = "source-reference" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("infersTypes", "identifiesRequiredFields", "providesJsonSchema")
                    forbiddenPatterns = @()
                    minConfidence = 0.8
                } `
                -Tags @("api", "schema", "inference", "json", "types")
            ),

            # Task 3: OpenAPI Spec Generation
            (New-GoldenTask `
                -TaskId "gt-api-reverse-003" `
                -Name "OpenAPI spec generation" `
                -Description "Generate complete OpenAPI 3.0 specification from API analysis" `
                -PackId "api-reverse" `
                -Category "codegen" `
                -Difficulty "hard" `
                -Query "Generate a complete OpenAPI 3.0 specification document from discovered endpoints, schemas, and authentication requirements. Include paths, components, and security schemes." `
                -ExpectedResult @{
                    validOpenApiStructure = $true
                    includesPaths = $true
                    includesComponents = $true
                    includesSecuritySchemes = $true
                    hasInfoSection = $true
                    hasOpenApiVersion = $true
                } `
                -RequiredEvidence @(
                    @{ source = "openapi"; type = "source-reference" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("validOpenApiStructure", "includesPaths", "includesComponents")
                    forbiddenPatterns = @()
                    minConfidence = 0.85
                } `
                -Tags @("api", "openapi", "spec", "documentation", "swagger")
            ),

            # Task 4: Authentication Pattern Detection
            (New-GoldenTask `
                -TaskId "gt-api-reverse-004" `
                -Name "Authentication pattern detection" `
                -Description "Identify and classify API authentication mechanisms" `
                -PackId "api-reverse" `
                -Category "analysis" `
                -Difficulty "medium" `
                -Query "Analyze HTTP headers and request patterns to identify authentication mechanisms (API keys, OAuth, JWT, Basic Auth, Bearer tokens) and extract their usage patterns." `
                -ExpectedResult @{
                    identifiesAuthType = $true
                    extractsApiKeys = $true
                    detectsOAuthFlows = $true
                    recognizesJwtPattern = $true
                    documentsAuthLocation = $true
                } `
                -RequiredEvidence @(
                    @{ source = "http-headers"; type = "source-reference" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("identifiesAuthType", "documentsAuthLocation")
                    forbiddenPatterns = @()
                    minConfidence = 0.8
                } `
                -Tags @("api", "authentication", "oauth", "jwt", "security")
            ),

            # Task 5: GraphQL Introspection
            (New-GoldenTask `
                -TaskId "gt-api-reverse-005" `
                -Name "GraphQL introspection" `
                -Description "Parse and analyze GraphQL schema introspection results" `
                -PackId "api-reverse" `
                -Category "analysis" `
                -Difficulty "medium" `
                -Query "Parse GraphQL introspection query results to extract types, queries, mutations, subscriptions, and their relationships. Generate a navigable schema documentation." `
                -ExpectedResult @{
                    extractsTypes = $true
                    identifiesQueries = $true
                    identifiesMutations = $true
                    identifiesSubscriptions = $true
                    mapsRelationships = $true
                    handlesInterfaces = $true
                } `
                -RequiredEvidence @(
                    @{ source = "graphql-schema"; type = "source-reference" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("extractsTypes", "identifiesQueries", "identifiesMutations")
                    forbiddenPatterns = @()
                    minConfidence = 0.8
                } `
                -Tags @("api", "graphql", "introspection", "schema")
            ),

            # Task 6: gRPC Proto Reconstruction
            (New-GoldenTask `
                -TaskId "gt-api-reverse-006" `
                -Name "gRPC proto reconstruction" `
                -Description "Reconstruct protobuf definitions from gRPC traffic or reflection" `
                -PackId "api-reverse" `
                -Category "analysis" `
                -Difficulty "hard" `
                -Query "Reconstruct .proto file definitions from gRPC method calls, message patterns, and field types observed in binary traffic or server reflection." `
                -ExpectedResult @{
                    reconstructsServices = $true
                    definesMessages = $true
                    infersFieldTypes = $true
                    assignsFieldNumbers = $true
                    generatesValidProto = $true
                } `
                -RequiredEvidence @(
                    @{ source = "grpc-traffic"; type = "source-reference" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("reconstructsServices", "definesMessages", "generatesValidProto")
                    forbiddenPatterns = @()
                    minConfidence = 0.85
                } `
                -Tags @("api", "grpc", "protobuf", "proto", "binary")
            ),

            # Task 7: Response Validation
            (New-GoldenTask `
                -TaskId "gt-api-reverse-007" `
                -Name "Response validation" `
                -Description "Validate API responses against inferred or provided schemas" `
                -PackId "api-reverse" `
                -Category "validation" `
                -Difficulty "medium" `
                -Query "Given API responses and a schema, validate conformance checking for required fields, data types, value constraints, and nested structure compliance." `
                -ExpectedResult @{
                    validatesRequiredFields = $true
                    checksDataTypes = $true
                    validatesConstraints = $true
                    reportsValidationErrors = $true
                    providesErrorLocations = $true
                } `
                -RequiredEvidence @(
                    @{ source = "api-responses"; type = "source-reference" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("validatesRequiredFields", "checksDataTypes", "reportsValidationErrors")
                    forbiddenPatterns = @()
                    minConfidence = 0.8
                } `
                -Tags @("api", "validation", "schema", "response", "conformance")
            ),

            # Task 8: Rate Limit Analysis
            (New-GoldenTask `
                -TaskId "gt-api-reverse-008" `
                -Name "Rate limit analysis" `
                -Description "Extract and analyze rate limiting headers and policies" `
                -PackId "api-reverse" `
                -Category "analysis" `
                -Difficulty "easy" `
                -Query "Analyze HTTP response headers (X-RateLimit, Retry-After, etc.) to extract rate limit policies, current usage, reset times, and recommended throttling strategies." `
                -ExpectedResult @{
                    extractsRateLimitHeaders = $true
                    identifiesLimitValues = $true
                    extractsResetTimes = $true
                    calculatesRemainingQuota = $true
                    suggestsThrottling = $true
                } `
                -RequiredEvidence @(
                    @{ source = "rate-limit-headers"; type = "source-reference" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("extractsRateLimitHeaders", "identifiesLimitValues", "calculatesRemainingQuota")
                    forbiddenPatterns = @()
                    minConfidence = 0.8
                } `
                -Tags @("api", "rate-limit", "throttling", "headers", "policy")
            ),

            # Task 9: Error Pattern Recognition
            (New-GoldenTask `
                -TaskId "gt-api-reverse-009" `
                -Name "Error pattern recognition" `
                -Description "Identify and classify API error response patterns" `
                -PackId "api-reverse" `
                -Category "analysis" `
                -Difficulty "medium" `
                -Query "Analyze API error responses to identify error patterns, status code distributions, error code taxonomies, and extract meaningful error messages and recovery hints." `
                -ExpectedResult @{
                    categorizesHttpStatusCodes = $true
                    extractsErrorCodes = $true
                    identifiesErrorPatterns = $true
                    extractsErrorMessages = $true
                    suggestsRecoveryActions = $true
                } `
                -RequiredEvidence @(
                    @{ source = "error-responses"; type = "source-reference" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("categorizesHttpStatusCodes", "extractsErrorCodes", "identifiesErrorPatterns")
                    forbiddenPatterns = @()
                    minConfidence = 0.8
                } `
                -Tags @("api", "errors", "patterns", "status-codes", "recovery")
            ),

            # Task 10: API Changelog Detection
            (New-GoldenTask `
                -TaskId "gt-api-reverse-010" `
                -Name "API changelog detection" `
                -Description "Detect changes between API versions by comparing specs or traffic" `
                -PackId "api-reverse" `
                -Category "comparison" `
                -Difficulty "hard" `
                -Query "Compare two versions of an API specification or traffic logs to detect breaking changes, new endpoints, deprecated fields, and generate a detailed changelog." `
                -ExpectedResult @{
                    identifiesBreakingChanges = $true
                    detectsNewEndpoints = $true
                    identifiesDeprecatedFields = $true
                    detectsTypeChanges = $true
                    generatesDetailedChangelog = $true
                    classifiesChangeSeverity = $true
                } `
                -RequiredEvidence @(
                    @{ source = "api-versions"; type = "comparison" }
                ) `
                -ValidationRules @{
                    propertyBased = $true
                    requiredProperties = @("identifiesBreakingChanges", "detectsNewEndpoints", "generatesDetailedChangelog")
                    forbiddenPatterns = @()
                    minConfidence = 0.85
                } `
                -Tags @("api", "changelog", "versioning", "breaking-changes", "diff")
            )
    )
}
