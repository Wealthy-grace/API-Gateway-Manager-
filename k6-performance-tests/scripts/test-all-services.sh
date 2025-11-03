#!/bin/bash

# ============================================================
# All Services Health Check Script
# Tests connectivity and health of all microservices
# ============================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================================
# Configuration
# ============================================================
USER_SERVICE="http://localhost:8081"
PROPERTY_SERVICE="http://localhost:8082"
APPOINTMENT_SERVICE="http://localhost:8083"
BOOKING_SERVICE="http://localhost:8084"
NOTIFICATION_SERVICE="http://localhost:8085"
API_GATEWAY="http://localhost:9500"

# ============================================================
# Helper Functions
# ============================================================

# Function to check service health
check_service() {
    local service_name=$1
    local service_url=$2
    local health_endpoint=$3

    echo -e "${CYAN}Testing ${service_name}...${NC}"

    # Check if service is reachable
    if curl -s -o /dev/null -w "%{http_code}" "${service_url}${health_endpoint}" | grep -q "200\|401"; then
        echo -e "${GREEN}✅ ${service_name} is UP${NC}"
        echo -e "${BLUE}   URL: ${service_url}${NC}"

        # Try to get actuator health if available
        health_response=$(curl -s "${service_url}/actuator/health" 2>/dev/null)
        if [ $? -eq 0 ]; then
            echo -e "${YELLOW}   Health Status:${NC}"
            echo "$health_response" | jq '.' 2>/dev/null || echo "$health_response"
        fi
        echo ""
        return 0
    else
        echo -e "${RED}❌ ${service_name} is DOWN${NC}"
        echo -e "${RED}   URL: ${service_url}${NC}"
        echo ""
        return 1
    fi
}

# Function to test API endpoint
test_endpoint() {
    local endpoint_name=$1
    local method=$2
    local url=$3
    local headers=$4
    local data=$5

    echo -e "${PURPLE}  → Testing: ${endpoint_name}${NC}"

    if [ -z "$data" ]; then
        response=$(curl -s -X "$method" "$url" $headers)
    else
        response=$(curl -s -X "$method" "$url" $headers -d "$data")
    fi

    if echo "$response" | jq -e '.success == true' >/dev/null 2>&1; then
        echo -e "${GREEN}    ✓ Success${NC}"
    else
        echo -e "${YELLOW}    ⚠ Response: ${NC}"
        echo "$response" | jq '.' 2>/dev/null || echo "$response"
    fi
    echo ""
}

# ============================================================
# Banner
# ============================================================
clear
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                        ║${NC}"
echo -e "${BLUE}║          🏥 MICROSERVICES HEALTH CHECK                ║${NC}"
echo -e "${BLUE}║                                                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Starting comprehensive health check...${NC}"
echo ""
sleep 1

# ============================================================
# Test All Services
# ============================================================
services_up=0
services_down=0

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}1️⃣  USER SERVICE (Port 8081)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
if check_service "User Service" "$USER_SERVICE" "/actuator/health"; then
    ((services_up++))

    # Test some endpoints
    echo -e "${YELLOW}  Testing endpoints...${NC}"
    test_endpoint "Get All Users" "GET" "$USER_SERVICE/api/v1/users" ""
else
    ((services_down++))
fi

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}2️⃣  PROPERTY SERVICE (Port 8082)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
if check_service "Property Service" "$PROPERTY_SERVICE" "/actuator/health"; then
    ((services_up++))

    echo -e "${YELLOW}  Testing endpoints...${NC}"
    test_endpoint "Get All Properties" "GET" "$PROPERTY_SERVICE/api/v1/properties" ""
else
    ((services_down++))
fi

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}3️⃣  APPOINTMENT SERVICE (Port 8083)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
if check_service "Appointment Service" "$APPOINTMENT_SERVICE" "/actuator/health"; then
    ((services_up++))

    echo -e "${YELLOW}  Testing endpoints...${NC}"
    test_endpoint "Get All Appointments" "GET" "$APPOINTMENT_SERVICE/api/v1/appointments" ""
else
    ((services_down++))
fi

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}4️⃣  BOOKING SERVICE (Port 8084)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
if check_service "Booking Service" "$BOOKING_SERVICE" "/actuator/health"; then
    ((services_up++))

    echo -e "${YELLOW}  Testing endpoints...${NC}"
    test_endpoint "Get All Bookings" "GET" "$BOOKING_SERVICE/api/v1/bookings" ""
else
    ((services_down++))
fi

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}5️⃣  NOTIFICATION SERVICE (Port 8085)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
if check_service "Notification Service" "$NOTIFICATION_SERVICE" "/actuator/health"; then
    ((services_up++))

    echo -e "${YELLOW}  Testing endpoints...${NC}"
    test_endpoint "Circuit Breaker Status" "GET" "$NOTIFICATION_SERVICE/api/circuit-breaker/status" ""
else
    ((services_down++))
fi

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}6️⃣  API GATEWAY (Port 9500)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
if check_service "API Gateway" "$API_GATEWAY" "/actuator/health"; then
    ((services_up++))

    echo -e "${YELLOW}  Testing routes...${NC}"
    echo -e "${PURPLE}  → Gateway Routes:${NC}"
    curl -s "$API_GATEWAY/actuator/gateway/routes" | jq -r '.[] | "    • \(.route_id): \(.uri)"' 2>/dev/null
    echo ""
else
    ((services_down++))
fi

# ============================================================
# Database Connectivity Check
# ============================================================
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}7️⃣  DATABASE CONNECTIVITY${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"

echo -e "${CYAN}Checking database connections...${NC}"

# Check MySQL connectivity (User, Property, Booking, Notification)
if command -v mysql &> /dev/null; then
    echo -e "${YELLOW}  MySQL (Port 3306):${NC}"
    if mysql -h localhost -P 3306 -u root -e "SELECT 1;" 2>/dev/null; then
        echo -e "${GREEN}    ✅ MySQL is accessible${NC}"
    else
        echo -e "${RED}    ❌ MySQL connection failed${NC}"
    fi
else
    echo -e "${YELLOW}    ⚠ MySQL client not installed (skipping direct check)${NC}"
fi

# Check MongoDB connectivity (Appointment Service)
if command -v mongosh &> /dev/null || command -v mongo &> /dev/null; then
    echo -e "${YELLOW}  MongoDB (Port 27017):${NC}"
    if mongosh --eval "db.version()" --quiet 2>/dev/null || mongo --eval "db.version()" --quiet 2>/dev/null; then
        echo -e "${GREEN}    ✅ MongoDB is accessible${NC}"
    else
        echo -e "${RED}    ❌ MongoDB connection failed${NC}"
    fi
else
    echo -e "${YELLOW}    ⚠ MongoDB client not installed (skipping direct check)${NC}"
fi

echo ""

# ============================================================
# RabbitMQ Check
# ============================================================
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}8️⃣  RABBITMQ MESSAGE BROKER${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"

echo -e "${CYAN}Checking RabbitMQ...${NC}"
if curl -s -u guest:guest http://localhost:15672/api/overview >/dev/null 2>&1; then
    echo -e "${GREEN}✅ RabbitMQ Management Console is UP${NC}"
    echo -e "${BLUE}   URL: http://localhost:15672${NC}"

    # Get queue information
    queues=$(curl -s -u guest:guest http://localhost:15672/api/queues)
    queue_count=$(echo "$queues" | jq '. | length' 2>/dev/null)
    echo -e "${YELLOW}   Active Queues: ${queue_count}${NC}"
    echo "$queues" | jq -r '.[] | "    • \(.name): \(.messages) messages"' 2>/dev/null
else
    echo -e "${RED}❌ RabbitMQ is DOWN${NC}"
    echo -e "${RED}   URL: http://localhost:15672${NC}"
fi

echo ""

# ============================================================
# Summary Report
# ============================================================
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    📊 SUMMARY REPORT                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

total_services=$((services_up + services_down))
health_percentage=$((services_up * 100 / total_services))

echo -e "${GREEN}Services UP:   ${services_up}/${total_services}${NC}"
echo -e "${RED}Services DOWN: ${services_down}/${total_services}${NC}"
echo -e "${YELLOW}Health Status: ${health_percentage}%${NC}"
echo ""

if [ $services_down -eq 0 ]; then
    echo -e "${GREEN}╔═══════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✅ ALL SERVICES ARE OPERATIONAL! ✅  ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════╝${NC}"
    exit 0
else
    echo -e "${RED}╔═══════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ⚠️  SOME SERVICES ARE DOWN! ⚠️       ║${NC}"
    echo -e "${RED}╚═══════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Troubleshooting:${NC}"
    echo "  1. Check if services are running"
    echo "  2. Check application logs for errors"
    echo "  3. Verify database connections"
    echo "  4. Ensure RabbitMQ is running"
    exit 1
fi