#!/bin/bash

# Путь к папке с файлами
SAMPLE_DIR="$1"

# Создаём папку для вывода отчётов
mkdir -p "$SAMPLE_DIR/fastp_output"

# Тримминг с помощью fastp
fastp -i "$SAMPLE_DIR"/*_R1.fq.gz -I "$SAMPLE_DIR"/*_R2.fq.gz -o "$SAMPLE_DIR"/fastp_output/trimmed_R1.fq.gz -O "$SAMPLE_DIR"/fastp_output/trimmed_R2.fq.gz \
  --html "$SAMPLE_DIR"/fastp_output/fastp.html \
  --json "$SAMPLE_DIR"/fastp_output/fastp.json

# Инициализация mamba для текущего shell
eval "$(mamba shell hook --shell bash)"

# Активация окружения trim
mamba activate trim

# Тримминг с помощью trimmomatic
cd /home/k/miniforge3/envs/trim/share/trimmomatic-0.39-2
java -jar /home/k/miniforge3/envs/trim/share/trimmomatic-0.39-2/trimmomatic.jar PE -phred33 "$SAMPLE_DIR"/fastp_output/trimmed_R1.fq.gz "$SAMPLE_DIR"/fastp_output/trimmed_R2.fq.gz "$SAMPLE_DIR"/paired_R1.fq.gz "$SAMPLE_DIR"/unpaired_R1.fq.gz "$SAMPLE_DIR"/paired_R2.fq.gz "$SAMPLE_DIR"/unpaired_R2.fq.gz ILLUMINACLIP:/home/k/miniforge3/envs/trim/share/trimmomatic-0.39-2/adapters/TruSeq3-PE.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36

