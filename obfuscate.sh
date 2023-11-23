#!/usr/bin/env bash

# Скрипт для обфускации кода - ЗАМЕНЯЕТ исходные файлы!!!
# Запускать из корня: `bash bin/obfuscate.sh`
# Запуск также должен быть настроен на ci/cd

# Директория, куда изначально складываются обфусцированные файлы
# УДАЛЯЕТСЯ после успеха
DIST_DIR="dist"

# Строка для импорта `pyarmor` - заменяет первую строку в обфусцированных файлах
# чтобы Django смог импортировать библиотеку `pyarmor`
BOOTSTRAP_CODE="from pytransform import pyarmor_runtime"

# Исходники для обфускации (пути писать от корня проекта)
SRC_FILES=( $(find . -type f -name "*.py") )

# Генерируем обфусцированные файлы (с нужной иерархией)
function generate_files() {
  for src_file in "${SRC_FILES[@]}"
  do
    echo "PROCESSING '$src_file'"
    pyarmor --silent obfuscate --restrict 0 --exact "$src_file"

    file_name="$(basename "$src_file")"
    dir_name="$DIST_DIR/$(dirname "$src_file")"

    # Заменяем первую строку, чтобы работал импорт
    # для этого обязателен параметр `--restrict 0`
    # иначе файлы не пройдут валидацию после замены строки с импортом
    sed -i "1s/.*/$BOOTSTRAP_CODE/" "$DIST_DIR/$file_name"

    mkdir -p $dir_name
    mv "$DIST_DIR/$file_name" "$dir_name/$file_name"
  done
}

# Заменяем исходные файлы обфусцированными
function replace_files() {
  for src_file in "${SRC_FILES[@]}"
  do
    echo "REPLACING '$src_file'"

    # cp $src_file "$src_file.backup"    # Можно расскоментировать ДЛЯ ОТЛАДКИ
    mv "$DIST_DIR/$src_file" $src_file
  done

  cp -r "$DIST_DIR/pytransform" .
  rm -rf $DIST_DIR
  echo "DONE!"
}

################################################################################

generate_files
replace_files
