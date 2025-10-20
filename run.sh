#!/bin/bash

echo "==================================="
echo "SurveyMap Flutter - Quick Start"
echo "==================================="
echo ""
echo "Choose a platform:"
echo "1) Web (Chrome)"
echo "2) macOS Desktop"
echo "3) Check available devices"
echo ""
read -p "Enter choice (1-3): " choice

case $choice in
    1)
        echo "Running on Chrome..."
        flutter run -d chrome
        ;;
    2)
        echo "Running on macOS..."
        flutter run -d macos
        ;;
    3)
        echo "Available devices:"
        flutter devices
        ;;
    *)
        echo "Invalid choice. Showing available devices:"
        flutter devices
        ;;
esac
