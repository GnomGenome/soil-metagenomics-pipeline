#!/bin/bash

# Путь к папке с файлами
SAMPLE_DIR="$1"

# Запуск FastQC для всех .fq.gz файлов в папке
mkdir -p "$SAMPLE_DIR/fastqc_output"
fastqc "$SAMPLE_DIR"/*.fq.gz -o "$SAMPLE_DIR/fastqc_output"

