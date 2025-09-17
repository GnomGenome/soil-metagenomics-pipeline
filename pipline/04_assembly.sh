#!/bin/bash
set -euo pipefail

# ---------------------------
# 04_assembly_megahit.sh
# ---------------------------
# Usage:
#   ./04_assembly_megahit.sh /full/path/to/sample_dir
# ---------------------------

SAMPLE_DIR="$1"
THREADS=${THREADS:-28}  # количество потоков, можно менять

# Входные файлы после де-хостинга
R1="${SAMPLE_DIR}/non_human_$(basename "$SAMPLE_DIR")_R1.clean.fq.gz"
R2="${SAMPLE_DIR}/non_human_$(basename "$SAMPLE_DIR")_R2.clean.fq.gz"

# Папка для сборки
ASSEMBLY_DIR="${SAMPLE_DIR}/assembly"
mkdir -p "$ASSEMBLY_DIR"

echo "[INFO] Запускаю сборку контигов для образца $(basename "$SAMPLE_DIR") с MEGAHIT..."
megahit -1 "$R1" -2 "$R2" \
        -o "$ASSEMBLY_DIR" \
        -t "$THREADS" \
        --min-contig-len 1000  # минимальная длина контигов 1 kb

FINAL_CONTIGS="${ASSEMBLY_DIR}/final.contigs.fa"
if [[ -f "$FINAL_CONTIGS" ]]; then
    echo "[DONE] Сборка контигов завершена. Результат: $FINAL_CONTIGS"
else
    echo "[ERROR] Сборка не завершилась успешно. Файл $FINAL_CONTIGS не найден."
fi
