#!/bin/bash
#!/bin/bash
set -e

echo "Enter project directory:"
read PROJECT_DIR

RAW_DIR="$PROJECT_DIR/Raw_data"
RESULTS_DIR="$PROJECT_DIR/Results/raw_analysis"
LOG_DIR="$PROJECT_DIR/Logs"

mkdir -p "$RESULTS_DIR"

echo "Enter source FASTQ folder (local or SSH, e.g. /path/to/fastq/ or user@server:/path/to/fastq/):"
read SRC

echo "Copying FASTQs with rsync..."
rsync -avP "$SRC"/*.fastq.gz "$RAW_DIR"/ 2>&1 | tee "$LOG_DIR/rsync_raw.log"

echo "Running FastQC on raw data..."
fastqc -o "$RESULTS_DIR" "$RAW_DIR"/*.fastq.gz \
    2>&1 | tee "$LOG_DIR/fastqc_raw.log"

echo "Running MultiQC on raw analysis..."
multiqc "$RESULTS_DIR" -o "$RESULTS_DIR" \
    2>&1 | tee "$LOG_DIR/multiqc_raw.log"

echo "Raw data analysis completed."
