#!/bin/bash

CHIP_NAME=$1
COM_NAME=$2
COM_SPEED=$3
ELF_FILE=$4

PROJECT_NAME=`basename $ELF_FILE`
BUILD_PATH=`dirname $ELF_FILE`
if [ `basename $BUILD_PATH` = "examples" ]; then
    BUILD_PATH=`dirname $BUILD_PATH`
fi

ESP_IDF=$(ls .embuild/espressif/esp-idf/ | tail -1)
ESP_IDF_SYS=`ls $BUILD_PATH/build/ | grep esp-idf-sys | tail -1`

if [ "$CHIP_NAME" = "esp32" ] || [ "$CHIP_NAME" = "esp32s2" ]; then
    BOOT_ADR=0x1000
else
    BOOT_ADR=0x0
fi

if [ "$COM_NAME" = "auto" ]; then
    COM_SCAN=`python3 -m esptool chip_id | grep "Serial port" | tail -1`
    echo "$COM_SCAN"
    COM_NAME=${COM_SCAN:12:-1}
fi

echo "WSL Rust TOOL"
echo "PROJECT_NAME  : $PROJECT_NAME"
echo "ELF_FILE      : $ELF_FILE"
echo "BUILD_PATH    : $BUILD_PATH"
echo "ESP-IDF       : $ESP_IDF"
echo "ESP_IDF_SYS   : $ESP_IDF_SYS"
echo "CHIP_NAME     : $CHIP_NAME"
echo "BOOT_ADR      : $BOOT_ADR"
echo "COM_NAME      : $COM_NAME"
echo "COM_SPEED     : $COM_SPEED"

cp -f "$ELF_FILE" .embuild/elf
cp -f "$BUILD_PATH/build/$ESP_IDF_SYS/out/build/bootloader/bootloader.bin" .embuild/
cp -f "$BUILD_PATH/build/$ESP_IDF_SYS/out/build/partition_table/partition-table.bin" .embuild/

python3 -m esptool --chip "$CHIP_NAME" elf2image .embuild/elf
python3 -m esptool --chip "$CHIP_NAME" --port "$COM_NAME" --baud "$COM_SPEED" --before default_reset --after hard_reset write_flash -z "$BOOT_ADR" .embuild/bootloader.bin 0x8000 .embuild/partition-table.bin 0x10000 .embuild/elf.bin
picocom "$COM_NAME" -b 115200
