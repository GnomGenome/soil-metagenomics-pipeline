#!/bin/bash
set -euo pipefail

SAMPLE_DIR="$1"
THREADS=${THREADS:-12}

BASENAME=$(basename "$SAMPLE_DIR")
DAS_TOOL_OUTPUT="${SAMPLE_DIR}/dastool_output_${BASENAME}"
CHECKM_DIR="${SAMPLE_DIR}/checkm_${BASENAME}"
GTDB_DIR="${SAMPLE_DIR}/gtdbtk_${BASENAME}"

# === 1. CheckM ===
mkdir -p "$CHECKM_DIR"
eval "$(mamba shell hook --shell bash)"
mamba activate checkm

echo "[INFO] Запускаю CheckM для оценки качества бинов..."
# предполагаем, что бины находятся в папке DASTool_bins/
BIN_FOLDER="${DAS_TOOL_OUTPUT}/dastool_bin"
checkm lineage_wf -x fa -t "$THREADS" "$BIN_FOLDER" "$CHECKM_DIR"

echo "[DONE] CheckM завершён. Результаты в $CHECKM_DIR"

mamba deactivate

# === 2. GTDB-Tk ===
mkdir -p "$GTDB_DIR"
mamba activate gtdb

echo "[INFO] Запускаю GTDB-Tk для таксономической классификации..."
gtdbtk classify_wf --genome_dir "$BIN_FOLDER" \
                    --out_dir "$GTDB_DIR" \
                    --cpus "$THREADS"

echo "[DONE] GTDB-Tk завершён. Результаты в $GTDB_DIR"

mamba deactivate

echo "[INFO] Все шаги оценки и классификации завершены."
