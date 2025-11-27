# Check k6 test files for correct URL configuration

Write-Host "Checking k6 test URL configurations..." -ForegroundColor Cyan
Write-Host ""

$testFiles = @(
    "scenarios/quick-test.js",
    "scenarios/smoke-test.js",
    "scenarios/load-test.js",
    "scenarios/stress-test.js",
    "scenarios/spike-test.js",
    "scenarios/soak-test.js",
    "tests/05-notification-service.test.js"
)

$foundIssues = $false

foreach ($file in $testFiles) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw

        # Check for localhost references
        if ($content -match "localhost") {
            Write-Host "⚠ $file" -ForegroundColor Yellow
            Write-Host "  Found 'localhost' - this won't work inside Docker!" -ForegroundColor Red
            $foundIssues = $true

            # Show the line
            $lines = Get-Content $file
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match "localhost") {
                    Write-Host "  Line $($i+1): $($lines[$i].Trim())" -ForegroundColor Gray
                }
            }
            Write-Host ""
        }

        # Check for 127.0.0.1 references
        if ($content -match "127\.0\.0\.1") {
            Write-Host "⚠ $file" -ForegroundColor Yellow
            Write-Host "  Found '127.0.0.1' - this won't work inside Docker!" -ForegroundColor Red
            $foundIssues = $true
            Write-Host ""
        }

        # Check for proper Docker network references
        if ($content -match "host\.docker\.internal" -or $content -match "(api-gateway-main|user-service|property-service|booking-service|appointment-service|notification-service):\d+") {
            Write-Host "✓ $file" -ForegroundColor Green
            Write-Host "  Correctly configured for Docker" -ForegroundColor Gray
            Write-Host ""
        }
    }
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

if ($foundIssues) {
    Write-Host "ISSUE FOUND: Some tests use 'localhost' which won't work in Docker!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Solutions:" -ForegroundColor Yellow
    Write-Host "1. Use 'host.docker.internal' instead of 'localhost'" -ForegroundColor White
    Write-Host "   Example: const BASE_URL = 'http://host.docker.internal:8085';" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Use container names directly" -ForegroundColor White
    Write-Host "   Example: const BASE_URL = 'http://api-gateway-main:8085';" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Use environment variable with fallback" -ForegroundColor White
    Write-Host "   Example: const BASE_URL = __ENV.BASE_URL || 'http://host.docker.internal:8085';" -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host "✓ All tests appear to be correctly configured!" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now run:" -ForegroundColor Cyan
    Write-Host "  npm run test:load" -ForegroundColor White
    Write-Host ""
}

Write-Host "Container names in your network:" -ForegroundColor Cyan
docker ps --format "table {{.Names}}\t{{.Ports}}" --filter "network=shared-microservices-network"