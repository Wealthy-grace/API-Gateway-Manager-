param(
    [Parameter(Mandatory=$true)]
    [string]$TestFile,

    [Parameter(Mandatory=$false)]
    [string]$Network = "shared-microservices-network"
)

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath
$currentDir = (Get-Location).Path

Write-Host "Running k6 test: $TestFile" -ForegroundColor Cyan
Write-Host "Project root: $projectRoot" -ForegroundColor Gray
Write-Host "Network mode: $Network" -ForegroundColor Gray
Write-Host ""

# Create reports directory if it doesn't exist
$reportsDir = Join-Path $projectRoot "reports"
if (-not (Test-Path $reportsDir)) {
    New-Item -ItemType Directory -Path $reportsDir | Out-Null
    Write-Host "Created reports directory" -ForegroundColor Green
}

# Generate timestamp for report
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$reportFile = "k6-results-$timestamp.json"

# Run k6 in Docker container
docker run --rm `
    -v "${projectRoot}:/k6" `
    -v "${reportsDir}:/reports" `
    --network=$Network `
    -e K6_OUT="json=/reports/$reportFile" `
    grafana/k6:latest `
    run "/k6/$TestFile"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Test completed successfully!" -ForegroundColor Green
    Write-Host "Report saved to: reports/$reportFile" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "Test failed with exit code: $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}