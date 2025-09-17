#!/bin/bash

set -euo pipefail

BASE_DIR="/home/k/Documents/METAGENOMES/DONETSK_coal_dump"
SAMPLES=$(find "$BASE_DIR" -mindepth 1 -maxdepth 1 -type d | grep -v scripts)

for sample_dir in $SAMPLES; do
    sample=$(basename "$sample_dir")
    echo "⚙️ Запуск анализа для образца: $sample"

    echo "[INFO] Выполняется запуск скрипта 01_fastqc.sh"
    #bash $BASE_DIR/scripts/01_fastqc.sh "$sample_dir"
    echo "[INFO] Выполняется запуск скрипта 02_fastp_trimmomatic.sh"
    #bash $BASE_DIR/scripts/02_fastp_trimmomatic.sh "$sample_dir"
    echo "[INFO] Выполняется запуск скрипта 03_dehost_bowtie2.sh"
    bash $BASE_DIR/scripts/03_dehost_bowtie2.sh "$sample_dir"
    echo "[INFO] Выполняется запуск скрипта 04_assembly.sh"
    #bash $BASE_DIR/scripts/04_assembly.sh "$sample_dir"
    echo "[INFO] Выполняется запуск скрипта 05_mapping_to_contigs.sh"
    #bash $BASE_DIR/scripts/05_mapping_to_contigs.sh "$sample_dir"
    echo "[INFO] Выполняется запуск скрипта 06_binning_concoct_metabat_maxbin.sh"
    #bash $BASE_DIR/scripts/06_binning_concoct_metabat_maxbin.sh "$sample_dir"
    echo "[INFO] Выполняется запуск скрипта 07_dastool.sh"
    #bash $BASE_DIR/scripts/07_dastool.sh "$sample_dir"
    echo "[INFO] Выполняется запуск скрипта 08_checkm_gtdb.sh"
    #bash $BASE_DIR/scripts/08_checkm_gtdb.sh "$sample_dir"
    echo "[INFO] Выполняется запуск скрипта 09_annotation_prodigal_emapper.sh"
    #bash $BASE_DIR/scripts/09_annotation_prodigal_emapper.sh "$sample_dir"
    echo "[INFO] Выполняется запуск скрипта 10_coverage.sh"
    #bash $BASE_DIR/scripts/10_coverage.sh "$sample_dir"
done
