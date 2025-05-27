#!/bin/bash
source ./backup_utils.sh

get_cfg_variables

NOW=$(date +"%Y-%m-%d_%H-%M-%S")
ARCHIVE_NAME="backup_$NOW.tar.gz"
DEST_PATH="$BACKUP_DEST/$ARCHIVE_NAME"
tar -czf "$DEST_PATH" "${SOURCE_DIRS[@]}"