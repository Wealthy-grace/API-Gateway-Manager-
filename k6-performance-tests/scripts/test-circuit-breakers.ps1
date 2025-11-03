# ============================================================
# Circuit Breaker Testing Script - Windows PowerShell
# ============================================================

# Colors
$Green = "Green"
$Yellow = "Yellow"
$Blue = "Cyan"
$Red = "Red"

Clear-Host

Write-Host "╔════════════════════════════════════════════╗" -ForegroundColor $Blue
Write-Host "║   🛡️  Circuit Breaker Test Suite         ║" -ForegroundColor $Blue
Write-Host "╔════════════════════════════════════════════╗" -ForegroundColor $Blue
Write-Host ""

# ============================================================
# Configuration
# ============================================================
$NOTIFICATION_SERVICE = "http://localhost:8085"
$BOOKING_SERVICE = "http://localhost:8084"

# Get JWT Token
Write-Host "Getting JWT token..." -ForegroundColor $Yellow
try {
    $loginBody = @{
        username = "Jessica-Admin"
        password = "Admin@225"
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri "http://localhost:9500/api/auth/login" `
        -Method Post `
        -ContentType "application/json" `
        -Body $loginBody

    $TOKEN = $response.data.access_token

    if ([string]::IsNullOrEmpty($TOKEN)) {
        Write-Host "❌ Failed to get JWT token!" -ForegroundColor $Red
        exit 1
    }

    Write-Host "✅ Token obtained" -ForegroundColor $Green
} catch {
    Write-Host "❌ Failed to login: $_" -ForegroundColor $Red
    exit 1
}

Write-Host ""

# ============================================================
# Test 1: Check Initial Circuit Breaker Status
# ============================================================
Write-Host "1️⃣  Testing NOTIFICATION SERVICE Circuit Breakers..." -ForegroundColor $Green
Write-Host ""

try {
    $status = Invoke-RestMethod -Uri "$NOTIFICATION_SERVICE/api/circuit-breaker/status"
    $status | ConvertTo-Json -Depth 10 | Write-Host
} catch {
    Write-Host "Failed to get status: $_" -ForegroundColor $Red
}

Write-Host ""
Start-Sleep -Seconds 2

# ============================================================
# Test 2: Send Test Requests
# ============================================================
Write-Host "2️⃣  Sending test requests to Notification Service..." -ForegroundColor $Yellow
Write-Host ""

$headers = @{
    "Authorization" = "Bearer $TOKEN"
    "Content-Type" = "application/json"
}

for ($i = 1; $i -le 10; $i++) {
    Write-Host "Request $i/10" -ForegroundColor $Blue

    $body = @{
        userId = 1
        userEmail = "test@example.com"
        userName = "Test User"
        type = "NEW_PROPERTY"
        subject = "Circuit Breaker Test $i"
        message = "Testing circuit breaker functionality"
    } | ConvertTo-Json

    try {
        $result = Invoke-RestMethod -Uri "$NOTIFICATION_SERVICE/api/notifications/send" `
            -Method Post `
            -Headers $headers `
            -Body $body

        Write-Host "  ✓ Success: $($result.message)" -ForegroundColor $Green
    } catch {
        Write-Host "  ✗ Failed: $_" -ForegroundColor $Red
    }

    Start-Sleep -Seconds 1
}

Write-Host ""

# ============================================================
# Test 3: Check Circuit Breaker Status After Load
# ============================================================
Write-Host "3️⃣  Checking circuit breaker status after load..." -ForegroundColor $Green
Write-Host ""

try {
    $status = Invoke-RestMethod -Uri "$NOTIFICATION_SERVICE/api/circuit-breaker/status"
    $status | ConvertTo-Json -Depth 10 | Write-Host
} catch {
    Write-Host "Failed to get status: $_" -ForegroundColor $Red
}

Write-Host ""

# ============================================================
# Test 4: Manual Failure Simulation
# ============================================================
Write-Host "4️⃣  MANUAL STEP: Stop User Service (port 8081)" -ForegroundColor $Red
Write-Host "To stop the service:" -ForegroundColor $Yellow
Write-Host "  Stop-Process -Id (Get-NetTCPConnection -LocalPort 8081).OwningProcess -Force" -ForegroundColor $Yellow
Write-Host ""
Write-Host "Press Enter after stopping User Service..." -ForegroundColor $Yellow
Read-Host

Write-Host "5️⃣  Sending requests to trigger circuit breaker..." -ForegroundColor $Yellow
Write-Host ""

for ($i = 1; $i -le 5; $i++) {
    Write-Host "Request $i/5 (User Service is down)" -ForegroundColor $Blue

    $body = @{
        propertyId = 1
        userIds = @(1)
    } | ConvertTo-Json

    try {
        $result = Invoke-RestMethod -Uri "$NOTIFICATION_SERVICE/api/notifications/new-property" `
            -Method Post `
            -Headers $headers `
            -Body $body

        Write-Host "  Response: $($result.message)" -ForegroundColor $Yellow
    } catch {
        Write-Host "  Fallback activated" -ForegroundColor $Red
    }

    Start-Sleep -Seconds 1
}

Write-Host ""

# ============================================================
# Test 5: Check Circuit Breaker State
# ============================================================
Write-Host "6️⃣  Checking circuit breaker status (should be OPEN)..." -ForegroundColor $Green
Write-Host ""

try {
    $status = Invoke-RestMethod -Uri "$NOTIFICATION_SERVICE/api/circuit-breaker/status/userService"
    $status | ConvertTo-Json -Depth 10 | Write-Host
} catch {
    Write-Host "Failed to get status: $_" -ForegroundColor $Red
}

Write-Host ""

# ============================================================
# Test 6: Recovery
# ============================================================
Write-Host "7️⃣  MANUAL STEP: Restart User Service (port 8081)" -ForegroundColor $Red
Write-Host "Press Enter after restarting User Service..." -ForegroundColor $Yellow
Read-Host

Write-Host "8️⃣  Testing recovery..." -ForegroundColor $Green
Write-Host ""

for ($i = 1; $i -le 3; $i++) {
    Write-Host "Recovery Request $i/3" -ForegroundColor $Blue

    $body = @{
        userId = 1
        userEmail = "test@example.com"
        userName = "Test User"
        type = "NEW_PROPERTY"
        subject = "Recovery Test"
        message = "Testing circuit breaker recovery"
    } | ConvertTo-Json

    try {
        $result = Invoke-RestMethod -Uri "$NOTIFICATION_SERVICE/api/notifications/send" `
            -Method Post `
            -Headers $headers `
            -Body $body

        Write-Host "  ✓ Success: $($result.message)" -ForegroundColor $Green
    } catch {
        Write-Host "  ✗ Failed: $_" -ForegroundColor $Red
    }

    Start-Sleep -Seconds 2
}

Write-Host ""

# ============================================================
# Final Status
# ============================================================
Write-Host "9️⃣  Final circuit breaker status (should be CLOSED)..." -ForegroundColor $Green
Write-Host ""

try {
    $status = Invoke-RestMethod -Uri "$NOTIFICATION_SERVICE/api/circuit-breaker/status"
    $status | ConvertTo-Json -Depth 10 | Write-Host
} catch {
    Write-Host "Failed to get status: $_" -ForegroundColor $Red
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════╗" -ForegroundColor $Blue
Write-Host "║          ✅ Test Suite Complete!          ║" -ForegroundColor $Blue
Write-Host "╚════════════════════════════════════════════╝" -ForegroundColor $Blue
Write-Host ""