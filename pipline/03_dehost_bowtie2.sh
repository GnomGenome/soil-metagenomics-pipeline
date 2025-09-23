#!/bin/bash
set -euo pipefail

SAMPLE_DIR="$1"
THREADS=${THREADS:-28}

# Путь к базе bowtie2 (без расширений .bt2)
HUMAN_REF="/home/k/Documents/GENOMES/t2t/t2t.fna"
INDEX_BASE="/home/k/Documents/GENOMES/t2t/human_genome_index"

# Папка для результатов
mkdir -p "$SAMPLE_DIR/bowtie_output"

# Активация окружения
eval "$(mamba shell hook --shell bash)"
mamba activate bowtie

# Создаём индекс, если его нет
if [ ! -f "${INDEX_BASE}.1.bt2" ]; then
    echo "[INFO] Индексы Bowtie2 не найдены. Создаю..."
    bowtie2-build "$HUMAN_REF" "$INDEX_BASE"
else
    echo "[INFO] Использую существующие индексы Bowtie2."
fi

# Входные файлы (после тримминга)
R1="$SAMPLE_DIR/paired_R1.fq.gz"
R2="$SAMPLE_DIR/paired_R2.fq.gz"

# SAM выход
SAM_OUT="$SAMPLE_DIR/bowtie_output/${SAMPLE_DIR##*/}_to_human.sam"

# Файлы для некартированных ридов с нужными именами сразу
UNMAPPED_R1="$SAMPLE_DIR/non_human_R1_clean.fq.gz"
UNMAPPED_R2="$SAMPLE_DIR/non_human_R2_clean.fq.gz"

# Запуск bowtie2
echo "[INFO] Запускаю bowtie2 для $(basename "$SAMPLE_DIR")..."
bowtie2 -p $THREADS -x $INDEX_BASE \
  -1 $R1 \
  -2 $R2 \
  --un-conc-gz \
  $SAMPLE_DIR/non_human_clean \
  > $SAM_OUT

mv $SAMPLE_DIR/non_human_clean.1 $SAMPLE_DIR/non_human_clean_R1.fq.gz
mv $SAMPLE_DIR/non_human_clean.2 $SAMPLE_DIR/non_human_clean_R2.fq.gz
echo "[DONE] Де-хостинг завершён для $(basename "$SAMPLE_DIR")."
