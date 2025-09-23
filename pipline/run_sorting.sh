#!/bin/bash

# Путь к папке с файлами
BASE_DIR="/home/k/Documents/METAGENOMES/DONETSK_coal_dump"

cd "$BASE_DIR" || { echo "Папка не найдена"; exit 1; }

# Перебираем все .fq.gz файлы в текущей папке, игнорируем папку scripts
for file in *.fq.gz; do
    # Проверка, что файл существует (на случай, если файлов нет)
    [ -e "$file" ] || continue

    # Извлекаем место сбора пробы — часть до первого '_'
    place="${file%%_*}"

    # Создаём папку, если нет
    mkdir -p "$place"

    # Перемещаем файл в папку
    mv "$file" "$place/"
done

