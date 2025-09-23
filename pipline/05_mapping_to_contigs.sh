#!/bin/bash
set -euo pipefail

SAMPLE_DIR="$1"
THREADS=${THREADS:-16}

BASENAME=$(basename "$SAMPLE_DIR")
ASSEMBLY_DIR="${SAMPLE_DIR}/assembly"
FINAL_CONTIGS="${ASSEMBLY_DIR}/final.contigs.fa"

# Проверка файла контигов
if [[ ! -f "$FINAL_CONTIGS" ]]; then
    echo "[ERROR] Итоговый файл контигов не найден: $FINAL_CONTIGS"
    exit 1
fi

# Входные файлы после де-хостинга
R1="${SAMPLE_DIR}/non_human_clean_R1.fq.gz"
R2="${SAMPLE_DIR}/non_human_clean_R2.fq.gz"

if [[ ! -f "$R1" || ! -f "$R2" ]]; then
    echo "[ERROR] Не найдены файлы ридов после де-хостинга"
    exit 1
fi

# Папка для результатов мэппинга
MAP_DIR="${SAMPLE_DIR}/mapping_to_contigs"
mkdir -p "$MAP_DIR"

# === 1. Мэппинг ридов на контиги с BWA ===
eval "$(mamba shell hook --shell bash)"

echo "[INFO] Индексация контигов с BWA..."
bwa index "$FINAL_CONTIGS"

SAM_OUT="${MAP_DIR}/${BASENAME}_alignment.sam"
echo "[INFO] Мэппинг ридов на контиги..."
bwa mem -t "$THREADS" "$FINAL_CONTIGS" "$R1" "$R2" > "$SAM_OUT"

BAM_OUT="${MAP_DIR}/${BASENAME}_alignment.bam"
SORTED_BAM="${MAP_DIR}/${BASENAME}_alignment_sorted.bam.gz"

echo "[INFO] Конвертация SAM -> BAM и сортировка..."
samtools view -@ "$THREADS" -bS "$SAM_OUT" > "$BAM_OUT"
samtools sort -@ "$THREADS" -o "$SORTED_BAM" "$BAM_OUT"
samtools index "$SORTED_BAM"

echo "[DONE] Мэппинг завершён."

# === 2. Биннинг ===
# Создаём директории
CONCOCT_DIR="${SAMPLE_DIR}/concoct_${BASENAME}"
METABAT_DIR="${SAMPLE_DIR}/metabat_${BASENAME}"
MAXBIN_DIR="${SAMPLE_DIR}/maxbin_${BASENAME}"
DAS_TOOL_OUTPUT="${SAMPLE_DIR}/dastool_output_${BASENAME}"

mkdir -p "$CONCOCT_DIR" "$METABAT_DIR" "$MAXBIN_DIR" "$DAS_TOOL_OUTPUT"

# 2.1 CONCOCT
echo "[INFO] Запускаю CONCOCT..."
mamba activate concoct

cut_up_fasta.py "$FINAL_CONTIGS" -c 10000 -o 0 --merge_last -b "${CONCOCT_DIR}/${BASENAME}_contigs_10K.bed" > "${CONCOCT_DIR}/${BASENAME}_contigs_10K.fa"
concoct_coverage_table.py "${CONCOCT_DIR}/${BASENAME}_contigs_10K.bed" "$SORTED_BAM" > "${CONCOCT_DIR}/${BASENAME}_coverage_table.tsv"
mkdir -p "${CONCOCT_DIR}/bins"
concoct --composition_file "${CONCOCT_DIR}/${BASENAME}_contigs_10K.fa" \
        --coverage_file "${CONCOCT_DIR}/${BASENAME}_coverage_table.tsv" \
        -b "${CONCOCT_DIR}/bins/"
merge_cutup_clustering.py "${CONCOCT_DIR}/bins/clustering_gt1000.csv" > "${CONCOCT_DIR}/bins/clustering_merged.csv"
extract_fasta_bins.py "$FINAL_CONTIGS" "${CONCOCT_DIR}/bins/clustering_merged.csv" --output_path "${CONCOCT_DIR}/bins/fasta_bins"

mamba deactivate

# 2.2 METABAT2
echo "[INFO] Запускаю METABAT2..."
mamba activate metabat

DEPTH_FILE="${METABAT_DIR}/${BASENAME}_depth.txt"
jgi_summarize_bam_contig_depths --outputDepth "$DEPTH_FILE" "$SORTED_BAM"
mkdir -p "${METABAT_DIR}/bins"
metabat2 -t "$THREADS" -i "$FINAL_CONTIGS" -a "$DEPTH_FILE" -o "${METABAT_DIR}/bins/bin"

mamba deactivate

# 2.3 MAXBIN
echo "[INFO] Запускаю MAXBIN..."
mamba activate maxbin

COV_FILE="${MAXBIN_DIR}/${BASENAME}_maxbin_coverage.txt"
pileup.sh in="$SAM_OUT" out="$COV_FILE"
awk '{print $1"\t"$5}' "$COV_FILE" | grep -v '^#' > "${MAXBIN_DIR}/${BASENAME}_abundance.txt"
mkdir -p "${MAXBIN_DIR}/bins"
run_MaxBin.pl -thread "$THREADS" -contig "$FINAL_CONTIGS" -out "${MAXBIN_DIR}/bins/bin" -abund "${MAXBIN_DIR}/${BASENAME}_abundance.txt"

mamba deactivate

# 2.4 DASTOOL
echo "[INFO] Объединение результатов DASTOOL..."
mamba activate dastool
/home/k/miniforge3/pkgs/das_tool-1.1.7-r43hdfd78af_0/share/das_tool-1.1.7-0/src/Fasta_to_Contig2Bin.sh -i "${MAXBIN_DIR}/bins/" -e fasta > "${DAS_TOOL_OUTPUT}/maxbin.contigs2bin.tsv"
/home/k/miniforge3/pkgs/das_tool-1.1.7-r43hdfd78af_0/share/das_tool-1.1.7-0/src/Fasta_to_Contig2Bin.sh -i "${CONCOCT_DIR}/bins/" -e fasta > "${DAS_TOOL_OUTPUT}/concoct.contigs2bin.tsv"
/home/k/miniforge3/pkgs/das_tool-1.1.7-r43hdfd78af_0/share/das_tool-1.1.7-0/src/Fasta_to_Contig2Bin.sh -i "${METABAT_DIR}/bins/" -e fasta > "${DAS_TOOL_OUTPUT}/metabat.contigs2bin.tsv"

DAS_Tool -i "${DAS_TOOL_OUTPUT}/maxbin.contigs2bin.tsv,${DAS_TOOL_OUTPUT}/metabat.contigs2bin.tsv,${DAS_TOOL_OUTPUT}/concoct.contigs2bin.tsv" \
         -l maxbin,metabat,concoct \
         -c "$FINAL_CONTIGS" \
         -o "${DAS_TOOL_OUTPUT}/dastool_bin" \
         --write_bins --write_bin_evals --threads "$THREADS"
         
mamba deactivate
echo "[DONE] Биннинг завершён для $BASENAME."
