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

update_crontab(){
  get_cfg_variables
  SCRIPT_PATH="$(pwd)/backup_script.sh"
  crontab -l 2>/dev/null | grep -v "$SCRIPT_PATH" > /tmp/current_cron || true
  case "$BACKUP_MODE" in
    daily) cron_schedule="0 12 * * *";;
    weekly) cron_schedule="0 12 * * 0";;
    monthly) cron_schedule="0 12 1 * *";;
  esac
  echo "$cron_schedule bash $SCRIPT_PATH" >> /tmp/current_cron
  crontab /tmp/current_cron
  rm /tmp/current_cron
}