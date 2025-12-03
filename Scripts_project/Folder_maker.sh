#!/bin/bash
set -e

echo "Enter project directory path:"
read PROJECT_DIR

RAW_DIR="$PROJECT_DIR/Raw_data"
PROCESSED_DIR="$PROJECT_DIR/Processed_data"
RESULTS_DIR="$PROJECT_DIR/Results"
LOG_DIR="$PROJECT_DIR/Logs"

mkdir -p "$RAW_DIR" "$PROCESSED_DIR" "$RESULTS_DIR" "$LOG_DIR"

echo "Project folder structure created:"
echo "$PROJECT_DIR"
echo " ├── Raw_data/"
echo " ├── Processed_data/"
echo " ├── Results/"
echo " └── Logs/"
echo "All necessary directories have been created successfully."
