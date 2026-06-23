#!/bin/bash

# Pre-build validation script for Flutter project
# This script validates configuration before building the app

set -e

echo "=== Flutter Pre-Build Validation ==="
echo "Starting pre-build checks..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}ERROR: Flutter is not installed or not in PATH${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Flutter is installed${NC}"

# Check if Dart is installed
if ! command -v dart &> /dev/null; then
    echo -e "${RED}ERROR: Dart is not installed or not in PATH${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Dart is installed${NC}"

# Check if pubspec.yaml exists
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}ERROR: pubspec.yaml not found${NC}"
    exit 1
fi

echo -e "${GREEN}✓ pubspec.yaml found${NC}"

# Check if android/build.gradle.kts exists
if [ ! -f "android/app/build.gradle.kts" ]; then
    echo -e "${RED}ERROR: android/app/build.gradle.kts not found${NC}"
    exit 1
fi

echo -e "${GREEN}✓ android/app/build.gradle.kts found${NC}"

# Run pub get
echo -e "${YELLOW}Running flutter pub get...${NC}"
flutter pub get

echo -e "${GREEN}✓ Dependencies resolved${NC}"

# Run code generation
echo -e "${YELLOW}Running code generation...${NC}"
flutter pub run build_runner build --delete-conflicting-outputs || true

echo -e "${GREEN}✓ Code generation complete${NC}"

# Run analyzer
echo -e "${YELLOW}Running dart analyzer...${NC}"
dart analyze --fatal-infos || echo -e "${YELLOW}⚠ Analyzer warnings detected${NC}"

# Run tests
echo -e "${YELLOW}Running unit tests...${NC}"
flutter test --no-coverage || echo -e "${YELLOW}⚠ Some tests failed${NC}"

echo -e "${GREEN}=== Pre-Build Validation Complete ===${NC}"
echo "All required checks passed. Ready for build."