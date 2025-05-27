# backup_utils.sh


CONFIG_FILE="./backup.conf"
declare -a SOURCE_DIRS
declare BACKUP_DEST
declare BACKUP_MODE

get_cfg_variables(){
  SOURCE_DIRS=()
  BACKUP_DEST=""
  BACKUP_MODE=""
  while read -r line; do
    if [[ "$line" =~ SOURCE_DIRS ]]; then
      while read -r sub_line; do
        if [[ "$sub_line" =~ \) ]]; then
          break
        fi
        SOURCE_DIRS+=("$(echo "$sub_line" | tr -d '" ')")
      done
    fi
    [[ "$line" =~ BACKUP_DEST ]] && BACKUP_DEST=$(echo "$line" | cut -d= -f2- | tr -d '"')
    [[ "$line" =~ MODE ]] && BACKUP_MODE=$(echo "$line" | cut -d= -f2- | tr -d '"')
  done < "$CONFIG_FILE"
}
