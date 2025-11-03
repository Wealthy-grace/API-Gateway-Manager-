# ============================================================
# Circuit Breaker Testing Script - Windows PowerShell
# Enhanced version with better error handling and diagnostics
# ============================================================

# Clear screen
Clear-Host

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   Circuit Breaker Test Suite (Enhanced)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$NOTIFICATION_SERVICE = "http://localhost:8085"
$BOOKING_SERVICE = "http://localhost:8084"
$USER_SERVICE = "http://localhost:8081"
$API_GATEWAY = "http://localhost:9500"

# ============================================================
# Get JWT Token from Keycloak
# ============================================================
Write-Host "[*] Getting JWT Token from Keycloak..." -ForegroundColor Yellow

$KEYCLOAK_URL = "http://localhost:8080/realms/friendly-housing/protocol/openid-connect/token"

try {
    # Keycloak requires form data, not JSON
    $keycloakBody = @{
        username = "Jessica-Admin"
        password = "Admin@225"
        grant_type = "password"
        client_id = "booking-service"
        client_secret = '39JGwi1wzcPzEXotI2z6igOIl4xGWSAm'
    }

    $keycloakResponse = Invoke-RestMethod `
        -Uri $KEYCLOAK_URL `
        -Method Post `
        -ContentType "application/x-www-form-urlencoded" `
        -Body $keycloakBody `
        -ErrorAction Stop

    $TOKEN = $keycloakResponse.access_token

    if ([string]::IsNullOrEmpty($TOKEN)) {
        Write-Host "[ERROR] Failed to get JWT token!" -ForegroundColor Red
        Write-Host "Response: $($keycloakResponse | ConvertTo-Json)" -ForegroundColor Red
        exit 1
    }

    Write-Host "[SUCCESS] Token obtained successfully from Keycloak" -ForegroundColor Green
    Write-Host "Token: $($TOKEN.Substring(0, 50))..." -ForegroundColor DarkGray
} catch {
    Write-Host "[ERROR] Keycloak authentication failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Make sure Keycloak is running on port 8080" -ForegroundColor Yellow
    Write-Host "URL: $KEYCLOAK_URL" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Setup headers
$headers = @{
    "Authorization" = "Bearer $TOKEN"
    "Content-Type" = "application/json"
}

# ============================================================
# Helper Function: Check Service Health
# ============================================================
function Test-ServiceHealth {
    param(
        [string]$ServiceName,
        [string]$Url,
        [hashtable]$Headers = @{}
    )

    Write-Host "Checking $ServiceName health..." -ForegroundColor Cyan

    try {
        $response = Invoke-WebRequest -Uri $Url -Headers $Headers -TimeoutSec 5 -ErrorAction Stop
        Write-Host "  [OK] $ServiceName is UP (Status: $($response.StatusCode))" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "  [FAIL] $ServiceName is DOWN: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# ============================================================
# Pre-Flight Checks
# ============================================================
Write-Host "[PRE-FLIGHT] Checking service availability..." -ForegroundColor Yellow
Write-Host ""

$notificationUp = Test-ServiceHealth -ServiceName "Notification Service" -Url "$NOTIFICATION_SERVICE/actuator/health"
$bookingUp = Test-ServiceHealth -ServiceName "Booking Service" -Url "$BOOKING_SERVICE/actuator/health"
$userUp = Test-ServiceHealth -ServiceName "User Service" -Url "$USER_SERVICE/actuator/health"

Write-Host ""

if (-not $notificationUp) {
    Write-Host "[ERROR] Notification Service is not running. Please start it first." -ForegroundColor Red
    exit 1
}

# ============================================================
# Test 1: Check Initial Circuit Breaker Status (Without Auth)
# ============================================================
Write-Host "[TEST 1] Checking NOTIFICATION SERVICE Circuit Breakers (No Auth)..." -ForegroundColor Green
Write-Host ""

try {
    $cbStatus = Invoke-RestMethod -Uri "$NOTIFICATION_SERVICE/api/circuit-breaker/status" -ErrorAction Stop
    Write-Host "Circuit Breaker Status:" -ForegroundColor Cyan
    $cbStatus | ConvertTo-Json -Depth 10 | Write-Host
} catch {
    Write-Host "[WARNING] Could not fetch status without auth: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "Trying with authentication..." -ForegroundColor Yellow

    try {
        $cbStatus = Invoke-RestMethod -Uri "$NOTIFICATION_SERVICE/api/circuit-breaker/status" -Headers $headers -ErrorAction Stop
        Write-Host "Circuit Breaker Status (with auth):" -ForegroundColor Cyan
        $cbStatus | ConvertTo-Json -Depth 10 | Write-Host
    } catch {
        Write-Host "[ERROR] Could not fetch status even with auth: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Note: Circuit breaker status endpoint may require authentication configuration" -ForegroundColor Yellow
    }
}

Write-Host ""
Start-Sleep -Seconds 2

# ============================================================
# Test 2: Check Booking Service Circuit Breakers
# ============================================================
Write-Host "[TEST 2] Checking BOOKING SERVICE Circuit Breakers..." -ForegroundColor Green
Write-Host ""

try {
    $bookingCB = Invoke-RestMethod `
        -Uri "$BOOKING_SERVICE/api/bookings/circuit-breaker/status" `
        -Headers $headers `
        -ErrorAction Stop

    Write-Host "Booking Service Circuit Breakers:" -ForegroundColor Cyan
    $bookingCB | ConvertTo-Json -Depth 10 | Write-Host
} catch {
    Write-Host "[WARNING] Could not fetch booking service status: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Start-Sleep -Seconds 2

# ============================================================
# Test 3: Send Test Requests (10 requests)
# ============================================================
Write-Host "[TEST 3] Sending 10 test requests to Notification Service..." -ForegroundColor Yellow
Write-Host ""

$successCount = 0
$failCount = 0

for ($i = 1; $i -le 10; $i++) {
    Write-Host "Request $i/10" -ForegroundColor Cyan

    $notificationBody = @{
        userId = 1
        userEmail = "test@example.com"
        userName = "Test User"
        type = "NEW_PROPERTY"
        subject = "Circuit Breaker Test $i"
        message = "Testing circuit breaker functionality"
    } | ConvertTo-Json

    try {
        $result = Invoke-RestMethod `
            -Uri "$NOTIFICATION_SERVICE/api/notifications/send" `
            -Method Post `
            -Headers $headers `
            -Body $notificationBody `
            -ErrorAction Stop

        if ($result.success) {
            Write-Host "  [OK] Success: $($result.message)" -ForegroundColor Green
            $successCount++
        } else {
            Write-Host "  [WARN] Response: $($result.message)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  [FAIL] Failed: $($_.Exception.Message)" -ForegroundColor Red
        $failCount++
    }

    Start-Sleep -Milliseconds 800
}

Write-Host ""
Write-Host "Results: $successCount successful, $failCount failed" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# Test 4: Check Circuit Breaker Status After Load
# ============================================================
Write-Host "[TEST 4] Checking circuit breaker status after load..." -ForegroundColor Green
Write-Host ""

try {
    # Try both with and without auth
    try {
        $cbStatusAfter = Invoke-RestMethod -Uri "$NOTIFICATION_SERVICE/api/circuit-breaker/status" -Headers $headers -ErrorAction Stop
    } catch {
        $cbStatusAfter = Invoke-RestMethod -Uri "$NOTIFICATION_SERVICE/api/circuit-breaker/status" -ErrorAction Stop
    }

    foreach ($cb in $cbStatusAfter.PSObject.Properties) {
        $cbName = $cb.Name
        $cbData = $cb.Value

        Write-Host "$cbName Circuit Breaker:" -ForegroundColor Cyan

        $stateColor = if ($cbData.state -eq "CLOSED") { "Green" } else { "Red" }
        Write-Host "  State: $($cbData.state)" -ForegroundColor $stateColor
        Write-Host "  Failure Rate: $($cbData.failureRate)" -ForegroundColor Yellow
        Write-Host "  Slow Call Rate: $($cbData.slowCallRate)" -ForegroundColor Yellow
        Write-Host "  Successful Calls: $($cbData.successfulCalls)" -ForegroundColor Gray
        Write-Host "  Failed Calls: $($cbData.failedCalls)" -ForegroundColor Gray
        Write-Host "  Buffered Calls: $($cbData.bufferedCalls)" -ForegroundColor Gray
        Write-Host ""
    }
} catch {
    Write-Host "[WARNING] Could not fetch status: $($_.Exception.Message)" -ForegroundColor Yellow
}

Start-Sleep -Seconds 2

# ============================================================
# Test 5: Verify User Service is Running Before Failure Test
# ============================================================
Write-Host ""
Write-Host "===============================================" -ForegroundColor Blue
Write-Host "[TEST 5] Service Failure Simulation" -ForegroundColor Red
Write-Host "===============================================" -ForegroundColor Blue
Write-Host ""

Write-Host "Current User Service Status:" -ForegroundColor Yellow
$userServiceUp = Test-ServiceHealth -ServiceName "User Service" -Url "$USER_SERVICE/actuator/health"
Write-Host ""

if (-not $userServiceUp) {
    Write-Host "[WARNING] User Service is already down!" -ForegroundColor Red
    Write-Host "Please start User Service first to see the circuit breaker open." -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "To test circuit breaker with service failure:" -ForegroundColor Yellow
Write-Host "  1. Stop User Service (port 8081)" -ForegroundColor Yellow
Write-Host "     Command: Stop-Process -Id (Get-NetTCPConnection -LocalPort 8081).OwningProcess -Force" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  2. Alternative: Press Ctrl+C in User Service terminal" -ForegroundColor Yellow
Write-Host ""

$continue = Read-Host "Do you want to continue with failure simulation? (y/n)"

if ($continue -eq 'y') {
    Write-Host ""
    Write-Host "[ACTION REQUIRED] Stop the User Service now!" -ForegroundColor Red
    Write-Host "Press Enter AFTER stopping User Service..." -ForegroundColor Yellow
    Read-Host

    # Verify User Service is actually down
    Write-Host ""
    Write-Host "Verifying User Service is down..." -ForegroundColor Yellow
    $userServiceDown = -not (Test-ServiceHealth -ServiceName "User Service" -Url "$USER_SERVICE/actuator/health")

    if (-not $userServiceDown) {
        Write-Host "[WARNING] User Service is still running!" -ForegroundColor Red
        Write-Host "Circuit breaker may not open if service is still up." -ForegroundColor Yellow
    } else {
        Write-Host "[CONFIRMED] User Service is DOWN" -ForegroundColor Green
    }
    Write-Host ""

    Write-Host "[TEST 6] Sending requests with User Service down..." -ForegroundColor Yellow
    Write-Host "Note: Watch for circuit breaker to OPEN after multiple failures" -ForegroundColor DarkGray
    Write-Host ""

    $failureCount = 0
    $circuitOpenDetected = $false

    for ($i = 1; $i -le 15; $i++) {
        Write-Host "Request $i/15 (User Service DOWN)" -ForegroundColor Cyan

        # Test endpoint that requires User Service
        $propertyNotif = @{
            propertyId = 1
            userIds = @(1, 2, 3)
        } | ConvertTo-Json

        try {
            $startTime = Get-Date
            $result = Invoke-RestMethod `
                -Uri "$NOTIFICATION_SERVICE/api/notifications/new-property" `
                -Method Post `
                -Headers $headers `
                -Body $propertyNotif `
                -TimeoutSec 10 `
                -ErrorAction Stop
            $duration = ((Get-Date) - $startTime).TotalMilliseconds

            Write-Host "  Response: $($result.message) (${duration}ms)" -ForegroundColor Yellow

            # Check if it's a fallback response
            if ($result.message -match "fallback|degraded|partial") {
                Write-Host "  [INFO] Fallback mechanism activated" -ForegroundColor Magenta
            }

        } catch {
            $failureCount++
            $errorMsg = $_.Exception.Message

            if ($errorMsg -match "circuit.*open|not permitted") {
                Write-Host "  [CIRCUIT OPEN] Request blocked by circuit breaker!" -ForegroundColor Red
                $circuitOpenDetected = $true
            } else {
                Write-Host "  [FAIL] Error: $errorMsg" -ForegroundColor Red
            }
        }

        Start-Sleep -Seconds 1

        # Check circuit breaker status every 5 requests
        if ($i % 5 -eq 0) {
            Write-Host ""
            Write-Host "  Checking circuit breaker status..." -ForegroundColor DarkGray
            try {
                try {
                    $quickStatus = Invoke-RestMethod -Uri "$NOTIFICATION_SERVICE/api/circuit-breaker/status/userService" -Headers $headers -ErrorAction Stop
                } catch {
                    $quickStatus = Invoke-RestMethod -Uri "$NOTIFICATION_SERVICE/api/circuit-breaker/status/userService" -ErrorAction Stop
                }

                $stateColor = switch ($quickStatus.state) {
                    "CLOSED" { "Green" }
                    "OPEN" { "Red" }
                    "HALF_OPEN" { "Yellow" }
                    default { "White" }
                }
                Write-Host "  Circuit State: $($quickStatus.state) | Failures: $($quickStatus.failedCalls)/$($quickStatus.bufferedCalls) | Rate: $($quickStatus.failureRate)" -ForegroundColor $stateColor
            } catch {
                Write-Host "  Could not fetch circuit status" -ForegroundColor DarkGray
            }
            Write-Host ""
        }
    }

    Write-Host ""
    Write-Host "Failure Test Summary:" -ForegroundColor Cyan
    Write-Host "  Total failures detected: $failureCount/15" -ForegroundColor Yellow
    Write-Host "  Circuit breaker opened: $circuitOpenDetected" -ForegroundColor $(if ($circuitOpenDetected) { "Green" } else { "Red" })
    Write-Host ""

    # Check circuit breaker state (should be OPEN)
    Write-Host "[TEST 7] Checking circuit breaker state (should be OPEN)..." -ForegroundColor Green
    Write-Host ""

    try {
        try {
            $userServiceCB = Invoke-RestMethod -Uri "$NOTIFICATION_SERVICE/api/circuit-breaker/status/userService" -Headers $headers -ErrorAction Stop
        } catch {
            $userServiceCB = Invoke-RestMethod -Uri "$NOTIFICATION_SERVICE/api/circuit-breaker/status/userService" -ErrorAction Stop
        }

        Write-Host "User Service Circuit Breaker Details:" -ForegroundColor Cyan
        $userServiceCB | ConvertTo-Json -Depth 10 | Write-Host

        if ($userServiceCB.state -eq "OPEN") {
            Write-Host ""
            Write-Host "[SUCCESS] Circuit breaker is OPEN as expected!" -ForegroundColor Green
        } elseif ($userServiceCB.state -eq "HALF_OPEN") {
            Write-Host ""
            Write-Host "[INFO] Circuit breaker is HALF_OPEN (testing recovery)" -ForegroundColor Yellow
        } else {
            Write-Host ""
            Write-Host "[WARNING] Circuit breaker is still CLOSED" -ForegroundColor Red
            Write-Host "This may indicate:" -ForegroundColor Yellow
            Write-Host "  - Failure threshold not reached" -ForegroundColor Yellow
            Write-Host "  - Aggressive fallback preventing failures from being counted" -ForegroundColor Yellow
            Write-Host "  - Circuit breaker configuration issue" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Could not fetch status: $($_.Exception.Message)" -ForegroundColor Yellow
    }

    Write-Host ""

    # Test recovery
    Write-Host "[TEST 8] Service Recovery Test" -ForegroundColor Red
    Write-Host "===============================================" -ForegroundColor Blue
    Write-Host "[ACTION REQUIRED] Restart User Service now!" -ForegroundColor Red
    Write-Host "Press Enter AFTER restarting User Service..." -ForegroundColor Yellow
    Read-Host

    # Verify User Service is back up
    Write-Host ""
    Write-Host "Verifying User Service is running..." -ForegroundColor Yellow
    $userServiceRestored = Test-ServiceHealth -ServiceName "User Service" -Url "$USER_SERVICE/actuator/health"
    Write-Host ""

    if ($userServiceRestored) {
        Write-Host "[CONFIRMED] User Service is UP" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] User Service still appears to be down" -ForegroundColor Red
    }
    Write-Host ""

    Write-Host "[TEST 9] Testing recovery (5 requests)..." -ForegroundColor Green
    Write-Host "Note: Circuit breaker should gradually close (OPEN → HALF_OPEN → CLOSED)" -ForegroundColor DarkGray
    Write-Host ""

    $recoverySuccess = 0
    $recoveryFail = 0

    for ($i = 1; $i -le 5; $i++) {
        Write-Host "Recovery Request $i/5" -ForegroundColor Cyan

        $recoveryBody = @{
            userId = 1
            userEmail = "test@example.com"
            userName = "Test User"
            type = "NEW_PROPERTY"
            subject = "Recovery Test $i"
            message = "Testing circuit breaker recovery"
        } | ConvertTo-Json

        try {
            $result = Invoke-RestMethod `
                -Uri "$NOTIFICATION_SERVICE/api/notifications/send" `
                -Method Post `
                -Headers $headers `
                -Body $recoveryBody `
                -ErrorAction Stop

            Write-Host "  [OK] Success: $($result.message)" -ForegroundColor Green
            $recoverySuccess++
        } catch {
            $errorMsg = $_.Exception.Message
            if ($errorMsg -match "circuit.*open|not permitted") {
                Write-Host "  [CIRCUIT OPEN] Still blocked by circuit breaker" -ForegroundColor Red
            } else {
                Write-Host "  [FAIL] Failed: $errorMsg" -ForegroundColor Red
            }
            $recoveryFail++
        }

        Start-Sleep -Seconds 2

        # Check status after each recovery attempt
        try {
            try {
                $recoveryStatus = Invoke-RestMethod -Uri "$NOTIFICATION_SERVICE/api/circuit-breaker/status/userService" -Headers $headers -ErrorAction Stop
            } catch {
                $recoveryStatus = Invoke-RestMethod -Uri "$NOTIFICATION_SERVICE/api/circuit-breaker/status/userService" -ErrorAction Stop
            }

            $stateColor = switch ($recoveryStatus.state) {
                "CLOSED" { "Green" }
                "OPEN" { "Red" }
                "HALF_OPEN" { "Yellow" }
                default { "White" }
            }
            Write-Host "  Current State: $($recoveryStatus.state)" -ForegroundColor $stateColor
        } catch {
            # Silently continue
        }
        Write-Host ""
    }

    Write-Host ""
    Write-Host "Recovery Summary:" -ForegroundColor Cyan
    Write-Host "  Successful: $recoverySuccess/5" -ForegroundColor Green
    Write-Host "  Failed: $recoveryFail/5" -ForegroundColor Red
    Write-Host ""

    # Final status
    Write-Host "[TEST 10] Final circuit breaker status (should be CLOSED)..." -ForegroundColor Green
    Write-Host ""

    try {
        try {
            $finalStatus = Invoke-RestMethod -Uri "$NOTIFICATION_SERVICE/api/circuit-breaker/status" -Headers $headers -ErrorAction Stop
        } catch {
            $finalStatus = Invoke-RestMethod -Uri "$NOTIFICATION_SERVICE/api/circuit-breaker/status" -ErrorAction Stop
        }

        Write-Host "All Circuit Breakers Final Status:" -ForegroundColor Cyan
        $finalStatus | ConvertTo-Json -Depth 10 | Write-Host

        Write-Host ""
        Write-Host "Circuit Breaker States Summary:" -ForegroundColor Cyan
        foreach ($cb in $finalStatus.PSObject.Properties) {
            $cbName = $cb.Name
            $cbData = $cb.Value
            $stateColor = switch ($cbData.state) {
                "CLOSED" { "Green" }
                "OPEN" { "Red" }
                "HALF_OPEN" { "Yellow" }
                default { "White" }
            }
            Write-Host "  $cbName : $($cbData.state)" -ForegroundColor $stateColor
        }
    } catch {
        Write-Host "Could not fetch final status: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# ============================================================
# Additional Diagnostics
# ============================================================
Write-Host ""
Write-Host "===============================================" -ForegroundColor Blue
Write-Host "Additional Diagnostics" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Blue
Write-Host ""

Write-Host "Actuator Endpoints:" -ForegroundColor Yellow
Write-Host "  Circuit Breaker Events: $NOTIFICATION_SERVICE/actuator/circuitbreakerevents" -ForegroundColor Gray
Write-Host "  Circuit Breaker Metrics: $NOTIFICATION_SERVICE/actuator/metrics/resilience4j.circuitbreaker.calls" -ForegroundColor Gray
Write-Host "  Health: $NOTIFICATION_SERVICE/actuator/health" -ForegroundColor Gray
Write-Host ""

$checkMetrics = Read-Host "Do you want to check circuit breaker metrics? (y/n)"

if ($checkMetrics -eq 'y') {
    Write-Host ""
    Write-Host "Fetching Circuit Breaker Events..." -ForegroundColor Cyan
    try {
        $events = Invoke-RestMethod -Uri "$NOTIFICATION_SERVICE/actuator/circuitbreakerevents" -ErrorAction Stop
        $events | ConvertTo-Json -Depth 10 | Write-Host
    } catch {
        Write-Host "Could not fetch events: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "Note: Actuator endpoints may require authentication or may be disabled" -ForegroundColor DarkGray
    }
}

# ============================================================
# Summary
# ============================================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "       Test Suite Complete!" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Summary:" -ForegroundColor Green
Write-Host "  [OK] Tested circuit breaker under normal load"
Write-Host "  [OK] Checked circuit breaker status"
if ($continue -eq 'y') {
    Write-Host "  [OK] Tested circuit breaker with service failure"
    Write-Host "  [OK] Tested circuit breaker recovery"
}
Write-Host ""

Write-Host "Recommendations:" -ForegroundColor Yellow
Write-Host "  1. Check application logs for circuit breaker state transitions"
Write-Host "  2. Review Resilience4j configuration (failure threshold, wait duration)"
Write-Host "  3. Verify fallback methods are not masking circuit breaker behavior"
Write-Host "  4. Monitor metrics at actuator endpoints for detailed insights"
Write-Host ""

Write-Host "Configuration to Check:" -ForegroundColor Yellow
Write-Host "  - resilience4j.circuitbreaker.instances.*.failureRateThreshold"
Write-Host "  - resilience4j.circuitbreaker.instances.*.waitDurationInOpenState"
Write-Host "  - resilience4j.circuitbreaker.instances.*.slidingWindowSize"
Write-Host "  - resilience4j.circuitbreaker.instances.*.minimumNumberOfCalls"
Write-Host ""

Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')