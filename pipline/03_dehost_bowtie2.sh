#!/bin/bash
set -euo pipefail

SAMPLE_DIR="$1"
THREADS=${THREADS:-12}

# Папка для результатов
mkdir -p "$SAMPLE_DIR/bowtie_output"

# Инициализация mamba
eval "$(mamba shell hook --shell bash)"
mamba activate bowtie

# Путь к базе без расширений
HUMAN_REF="/home/k/Documents/GENOMES/t2t/t2t.fna"
INDEX_BASE="/home/k/Documents/GENOMES/t2t/human_genome_index"

# Создаём индекс, если его нет
if [ ! -f "${INDEX_BASE}.1.bt2" ]; then
    echo "[INFO] Индексы Bowtie2 не найдены. Создаю..."
    bowtie2-build "$HUMAN_REF" "$INDEX_BASE"
else
    echo "[INFO] Использую существующие индексы Bowtie2."
fi

# Входные файлы
R1="$SAMPLE_DIR/paired_R1.fq.gz"
R2="$SAMPLE_DIR/paired_R2.fq.gz"

# Префикс для не картированных ридов
UNMAPPED_PREFIX="$SAMPLE_DIR/non_human_${SAMPLE_DIR##*/}_unmapped"

# Выходной SAM
SAM_OUT="$SAMPLE_DIR/bowtie_output/${SAMPLE_DIR##*/}_to_human.sam"

echo "[INFO] Запускаю bowtie2 для $SAMPLE_DIR..."
bowtie2 -x "$INDEX_BASE" \
    -1 "$R1" -2 "$R2" \
    --very-sensitive -p "$THREADS" \
    --un-conc-gz "$UNMAPPED_PREFIX" \
    -S "$SAM_OUT"

# Переименуем unmapped в clean r1/r2
mv "${UNMAPPED_PREFIX}.1.gz" "$SAMPLE_DIR/non_human_R1.clean.fq.gz"
mv "${UNMAPPED_PREFIX}.2.gz" "$SAMPLE_DIR/non_human_R2.clean.fq.gz"

echo "[DONE] Де-хостинг завершён для $SAMPLE_DIR."
