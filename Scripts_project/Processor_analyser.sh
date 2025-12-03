#!/bin/bash
set -e

echo "Enter project directory:"
read PROJECT_DIR

RAW_DIR="$PROJECT_DIR/Raw_data"
PROCESSED_BASE="$PROJECT_DIR/Processed_data"
RESULTS_BASE="$PROJECT_DIR/Results"
LOG_DIR="$PROJECT_DIR/Logs"

mkdir -p "$PROCESSED_BASE" "$RESULTS_BASE" "$LOG_DIR"

###########################################
# VERSIONING
###########################################
VERSION=$(ls -d $PROCESSED_BASE/version_* 2>/dev/null | wc -l)
VERSION=$((VERSION + 1))

PROCESSED_DIR="$PROCESSED_BASE/version_$VERSION"
RESULTS_DIR="$RESULTS_BASE/processed_analysis_v$VERSION"

mkdir -p "$PROCESSED_DIR" "$RESULTS_DIR/fastqc"

echo "Processing version: v$VERSION"
echo "Results will be saved in: $RESULTS_DIR"
echo ""

###########################################
# NORMALIZE FILENAMES (SYMLINK CLEANUP)
###########################################
echo "Do you wish to normalize filenames? (y/n)"
read NORMALIZE

if [[ "$NORMALIZE" == "y" || "$NORMALIZE" == "Y" ]]; then
    echo "Normalizing FASTQ filenames..."
    echo "Logging normalization to: $LOG_DIR/normalization.log"

ABS_RAW_DIR="$RAW_DIR"      # Ensures absolute path
TEMP_NORMALIZED="$RAW_DIR/normalized"
mkdir -p "$TEMP_NORMALIZED"

echo "Normalized FASTQ filenames:" | tee "$LOG_DIR/normalization.log"

# Loop safely through FASTQ files
shopt -s nullglob
for FILE in "$ABS_RAW_DIR"/*.fastq.gz "$ABS_RAW_DIR"/*.fq.gz; do

    # Skip normalized folder
    [[ "$FILE" == *"/normalized/"* ]] && continue

    BASENAME=$(basename "$FILE")
    CLEAN="$BASENAME"

    ###########################################
    # 1. Remove unwanted suffixes (generic)
    ###########################################
    CLEAN=$(echo "$CLEAN" | sed \
        -e 's/\.trimP//g' \
        -e 's/\.trimmed//g' \
        -e 's/\.clean//g' \
        -e 's/\.processed//g')

    ###########################################
    # 2. Normalize read pair patterns
    # Works on ANY naming structure:
    #   sample.1.fastq.gz
    #   sample_R1.fq.gz
    #   sample-2.fastq.gz
    #   sample.read1.fq.gz
    #   sample_001_R2.fastq.gz
    ###########################################

    # Standard replacements: _1 → _R1, _2 → _R2
    CLEAN=$(echo "$CLEAN" | sed \
        -e 's/\([._-]\)1\([._-]\)/\1R1\2/g' \
        -e 's/\([._-]\)2\([._-]\)/\1R2\2/g')

    # If still lacking R1/R2 but ends in _1.fastq.gz
    if [[ "$CLEAN" =~ _1\.fastq.gz$ ]]; then
        CLEAN="${CLEAN/_1.fastq.gz/_R1.fastq.gz}"
    fi
    if [[ "$CLEAN" =~ _2\.fastq.gz$ ]]; then
        CLEAN="${CLEAN/_2.fastq.gz/_R2.fastq.gz}"
    fi

    # If STILL nothing → fallback based on R1/R2 pattern
    if [[ "$CLEAN" != *R1* && "$CLEAN" != *R2* ]]; then
        # Detect with regex grouping
        if echo "$BASENAME" | grep -qi '1[^0-9]*\.f'; then
            CLEAN="${CLEAN/.fastq.gz/_R1.fastq.gz}"
            CLEAN="${CLEAN/.fq.gz/_R1.fq.gz}"
        fi
        if echo "$BASENAME" | grep -qi '2[^0-9]*\.f'; then
            CLEAN="${CLEAN/.fastq.gz/_R2.fastq.gz}"
            CLEAN="${CLEAN/.fq.gz/_R2.fq.gz}"
        fi
    fi

    ###########################################
    # 3. Rename the file (not a symlink)
    ###########################################
    echo " → $BASENAME   →   $CLEAN" | tee -a "$LOG_DIR/normalization.log"

    mv "$FILE" "$TEMP_NORMALIZED/$CLEAN"

done
shopt -u nullglob

echo "Normalization complete."

else
#No normalization selected, use raw data directly
TEMP_NORMALIZED="$RAW_DIR"

fi



###########################################
# FASTP PARAMETERS (Runtime)
###########################################
#Default values
PHRED_CHANGE=15
MINLEN=15

echo "Enable detection of adapter0? (y/n)"
read ADAPTER0

echo "Change phred quality? Default 15" 
read PHRED_CHANGE
PHRED_CHANGE=${PHRED_CHANGE:-15}

echo "Specify Minimum length? Default 15"
read MINLEN
MINLEN=${MINLEN:-15}

echo "Enable deduplication? (y/n)"
read DEDUP

echo "Trim poly-G tails? (y/n)"
read POLYG

echo "Enter additional FASTP options (or leave blank):"
read EXTRA_OPTS

FASTP_OPTS=""
[[ $ADAPTER0 == "y" ]] && FASTP_OPTS+=" --detect_adapter_for_pe "
[[ $DEDUP == "y" ]] && FASTP_OPTS+=" --dedup "
[[ $POLYG == "y" ]] && FASTP_OPTS+=" --trim_poly_g "
[[ $PHRED_CHANGE ]] && FASTP_OPTS+=" --qualified_quality_phred $PHRED_CHANGE "
[[ $MINLEN ]] && FASTP_OPTS+=" --length_required $MINLEN "
FASTP_OPTS+=" $EXTRA_OPTS "

echo "Using FASTP options: $FASTP_OPTS"
echo ""

###########################################
# PROCESSING LOOP 
###########################################

echo "Starting FASTP processing..."

for R1 in "$TEMP_NORMALIZED"/*_R1.fastq.gz; do
    SAMPLE=$(basename "$R1" _R1.fastq.gz)

    R2="$TEMP_NORMALIZED/${SAMPLE}_R2.fastq.gz"

    if [[ ! -f "$R2" ]]; then
        echo "WARNING: Paired R2 file not found for $SAMPLE. Skipping."
        continue
    fi

    echo "Processing sample: $SAMPLE"

    fastp \
        -i "$R1" \
        -I "$R2" \
        -o "$PROCESSED_DIR/${SAMPLE}_R1.trimmed.v${VERSION}.fastq.gz" \
        -O "$PROCESSED_DIR/${SAMPLE}_R2.trimmed.v${VERSION}.fastq.gz" \
        --html "$RESULTS_DIR/${SAMPLE}_fastp_v${VERSION}.html" \
        --json "$RESULTS_DIR/${SAMPLE}_fastp_v${VERSION}.json" \
        $FASTP_OPTS \
        2>&1 | tee "$LOG_DIR/fastp_${SAMPLE}_v${VERSION}.log"
done


###########################################
# QC on processed data
###########################################
echo "Running FastQC..."
fastqc -o "$RESULTS_DIR/fastqc" "$PROCESSED_DIR"/*.fastq.gz \
    2>&1 | tee "$LOG_DIR/fastqc_processed_v${VERSION}.log"

echo "Running MultiQC..."
multiqc "$RESULTS_DIR/fastqc" -o "$RESULTS_DIR" \
    2>&1 | tee "$LOG_DIR/multiqc_processed_v${VERSION}.log"

echo ""
echo "Processing completed for version v$VERSION"
echo "Processed files: $PROCESSED_DIR"
echo "Results: $RESULTS_DIR"
