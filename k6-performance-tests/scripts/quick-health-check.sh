#!/bin/bash

# ============================================================
# Quick Health Check - Fast verification of all services
# ============================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🏥 Quick Health Check..."
echo ""

# Services array
declare -A services=(
    ["User Service"]="http://localhost:8081"
    ["Property Service"]="http://localhost:8082"
    ["Appointment Service"]="http://localhost:8083"
    ["Booking Service"]="http://localhost:8084"
    ["Notification Service"]="http://localhost:8085"
    ["API Gateway"]="http://localhost:9500"
)

up=0
down=0

# Check each service
for service_name in "${!services[@]}"; do
    service_url="${services[$service_name]}"

    if curl -s -o /dev/null -w "%{http_code}" "${service_url}/actuator/health" | grep -q "200\|401"; then
        echo -e "${GREEN}✅ ${service_name}${NC} - ${service_url}"
        ((up++))
    else
        echo -e "${RED}❌ ${service_name}${NC} - ${service_url}"
        ((down++))
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}UP: ${up}${NC} | ${RED}DOWN: ${down}${NC}"

if [ $down -eq 0 ]; then
    echo -e "${GREEN}✅ All services operational!${NC}"
    exit 0
else
    echo -e "${RED}⚠️  Some services are down!${NC}"
    exit 1
fi