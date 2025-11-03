#!/bin/bash

# ============================================================
# Fix Spring Boot Version Compatibility
# Updates all services from Spring Boot 3.5.x to 3.2.10
# ============================================================

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  🔧 Spring Boot Version Fix Tool          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Fixing Spring Boot version in all services...${NC}"
echo ""

services=(
    "User-Service"
    "Property-Service"
    "Appointment-Service"
    "Booking-Service"
    "Notification-Service"
    "API-Gateway"
)

updated_count=0
failed_count=0

for service in "${services[@]}"; do
    if [ -f "$service/build.gradle" ]; then
        echo -e "${BLUE}Updating $service...${NC}"

        # Backup original file
        cp "$service/build.gradle" "$service/build.gradle.backup"

        # Update Spring Boot version from 3.5.x to 3.2.10
        sed -i.bak "s/version '3.5.7'/version '3.2.10'/g" "$service/build.gradle"
        sed -i.bak "s/version '3.5.6'/version '3.2.10'/g" "$service/build.gradle"
        sed -i.bak "s/version '3.5.5'/version '3.2.10'/g" "$service/build.gradle"
        sed -i.bak "s/version '3.5.4'/version '3.2.10'/g" "$service/build.gradle"

        # Update dependency management version
        sed -i.bak "s/version '1.1.6'/version '1.1.4'/g" "$service/build.gradle"

        # Clean up .bak files
        rm -f "$service/build.gradle.bak"

        echo -e "${GREEN}✅ $service updated${NC}"
        ((updated_count++))
    else
        echo -e "${YELLOW}⚠️  $service/build.gradle not found${NC}"
        ((failed_count++))
    fi
done

echo ""
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Updated: $updated_count services${NC}"
if [ $failed_count -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Skipped: $failed_count services${NC}"
fi
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Review changes in each service"
echo "  2. Run: ./gradlew clean build --refresh-dependencies"
echo "  3. Restart all services"
echo ""
echo -e "${BLUE}Backup files saved as: build.gradle.backup${NC}"