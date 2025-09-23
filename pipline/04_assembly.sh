#!/bin/bash
set -euo pipefail

# Путь к папке с файлами
SAMPLE_DIR="$1"
THREADS=${THREADS:-28}

# Входные файлы после де-хостинга
BASENAME=$(basename "$SAMPLE_DIR")
R1="${SAMPLE_DIR}/non_human_clean_R1.fq.gz"
R2="${SAMPLE_DIR}/non_human_clean_R2.fq.gz"

# Проверка наличия входных файлов
if [[ ! -f "$R1" ]]; then
    echo "[ERROR] Не найден файл R1: $R1"
    exit 1
fi
if [[ ! -f "$R2" ]]; then
    echo "[ERROR] Не найден файл R2: $R2"
    exit 1
fi

# Папка для сборки
ASSEMBLY_DIR="${SAMPLE_DIR}/assembly"

echo "[INFO] Запускаю сборку контигов для образца $BASENAME с MEGAHIT..."
#START_TIME=$(date)

megahit -1 "$R1" -2 "$R2" \
        -o "$ASSEMBLY_DIR" \
        -t "$THREADS" \
        --min-contig-len 1000

# Проверка успеха сборки
if [[ $? -eq 0 ]]; then
    FINAL_CONTIGS="${ASSEMBLY_DIR}/final_contigs.fa"
    if [[ -f "$FINAL_CONTIGS" ]]; then
        echo "[DONE] Сборка завершена успешно."
        echo "Результат: $FINAL_CONTIGS"
        #echo "[INFO] Время выполнения: $(date -d "@$(( $(date +%s) - $(date -d "$START_TIME" +%s) ))" '+%H:%M:%S')"
        exit 0
    else
        echo "[ERROR] Файл итоговых контингентов не найден: $FINAL_CONTIGS"
        exit 1
    fi
else
    echo "[ERROR] MEGAHIT завершился ошибкой."
    exit 1
fi
