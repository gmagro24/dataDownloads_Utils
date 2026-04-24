#!/bin/bash  
# =====================================================
# Script run_sra_to_fastq_pipeline.sh
# Author: Gina Magro
# Created 2026-04-20
# Description: 
# 	Downloads SRA accessions and converts them to FASTQ files,
# 	Includes logging, skipping completed samples, and cleanup.
#
# Usage 
# ./run_sra_to_fastq_pipeline <accesionFile_OR_AccesionFileList> [OutputDir]
#
# Requirements 
# 	- sratoolkit (prefetch, fasterq-dump) 
#	- sufficient disk space (~20BG per sample FASTQ)
# 
# Notes: 
# 	- FASTQ Files are signigicantly large than SRA files 
# 	- Script removes intermediate .sra files after conversion 
#
# =====================================================
 
set -euo pipefail 

# ==========================
#  Usage check 
# =========================

if [ -z "${1:-}" ]; then 
	echo "Usage: $0 <accession_file> [output_dir]" 
	exit 1
fi 

ACCESSION_FILE="$1" 
OUTDIR="${2:-fastq_output}" 
TMPDIR="tmp"
LOGDIR="logs"
SRADIR="./sra"
mkdir -p "$OUTDIR" "$TMPDIR" "$LOGDIR" "$SRADIR" 

echo "=========================="
echo "SRA PIPELINE STARTED"
echo "Accession file: $ACCESSION_FILE"
echo "Output dir: $OUTDIR"
echo "=========================="

# ==========================
# Process Accessions 
# ==========================
grep -E '^SRR' "$ACCESSION_FILE" | tr -d "\r" | while read -r acc; do
	echo "---------------------"
	echo "Processing $acc" 
	echo "---------------------" 
	
	# Skip id already done
	if [ -f "$OUTDIR/${acc}_1.fastq" ]; then 
	  echo "$acc already processed. Skipping." 
	  continue 
	fi
	# Step 1: Download 
	echo "Downloading $acc..." 
	prefetch "$acc"	\
	 --max-size 100G \
	--output-directory "$SRADIR" \
	  > "$LOGDIR/${acc}_prefetch.log" 2>&1

	# Step 2: Convert to FASTQ
	echo "Converting $acc to FASTQ..." 
	fasterq-dump "$SRADIR/$acc/$acc.sra" \
	  --split-files \
	  --threads 8 \
	  --outdir "$OUTDIR" \
	  --temp "$TMPDIR" \
	  > "$LOGDIR/${acc}_fasterq.log" 2>&1
	echo "$acc DONE"

	# Step 3: Remove sra files 
	rm -f "$SRADIR/$acc/$acc.sra"
	rmdir "$SRADIR/$acc" 2>/dev/null || true
done 
echo "=============================="
echo "PIPELINE COMPLETE" 
echo "=============================="

