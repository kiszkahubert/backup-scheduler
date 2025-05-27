#!/bin/bash

source ./backup_utils.sh

if [[ ! -e backup.conf ]]; then
  echo "Config file does not exist"
  exit 1 
fi

main_menu(){
  options=("Directories to backup" "Save destination" "Change backup frequency" "All settings" "Exit and save")
  selected=0
  while true; do
    ((selected < 0)) && selected=0
    ((selected >= ${#options[@]})) && selected=$((${#options[@]} - 1))
    clear
    echo -e "CONFIGURE BACKUP\n\n"
    for i in "${!options[@]}"; do
      if [[ $i -eq $selected ]]; then
        echo -e "> \e[7m${options[$i]}\e[0m"
      else
        echo "  ${options[$i]}"
      fi
    done
    read -rsn1 key
    if [[ $key == $'\x1b' ]]; then
      read -rsn2 key
      [[ $key == "[A" ]] && ((selected--))
      [[ $key == "[B" ]] && ((selected++))
    elif [[ $key == "" ]]; then
      case $selected in
        0) source_settings;;
        1) save_destination;;
        2) change_backup_frequency;; 
        3) all_settings;;
        4) update_crontab && exit 0;;
      esac
    fi
  done
}

all_settings(){
  clear
  get_cfg_variables
  if [[ ${#SOURCE_DIRS[@]} -eq 0 ]]; then
    echo "No directories configured for backup"
  else
    echo "Current backup directories:"
    for i in "${!SOURCE_DIRS[@]}"; do
        echo "$((i+1)). ${SOURCE_DIRS[$i]}"
    done
  fi
  echo -e "\n\n"
  echo "Current backup destination: $BACKUP_DEST"
  echo -e "\n\n"
  echo "Current backup mode: $BACKUP_MODE"
  options=("EXIT")
  while true; do
    ((selected < 0)) && selected=0
    ((selected >= ${#options[@]})) && selected=$((${#options[@]} - 1))
    for i in "${!options[@]}"; do
      if [[ $i -eq $selected ]]; then
        echo -e "> \e[7m${options[$i]}\e[0m"
      else
        echo "  ${options[$i]}"
      fi
    done

    read -rsn1 key
    if [[ $key == $'\x1b' ]]; then
      read -rsn2 key
      [[ $key == "[A" ]] && ((selected--))
      [[ $key == "[B" ]] && ((selected++))
    elif [[ $key == "" ]]; then
      if [[ "${options[$selected]}" == "EXIT" ]]; then
        main_menu
      fi
    fi
  done
}

change_backup_frequency(){
  clear
  get_cfg_variables
  options=("Change frequency" "EXIT")
  selected=0
  while true; do
    ((selected < 0)) && selected=0
    ((selected >= ${#options[@]})) && selected=$((${#options[@]} - 1))
    clear
    echo "Current frequency $BACKUP_MODE"
    for i in "${!options[@]}"; do
      if [[ $i -eq $selected ]]; then
        echo -e "> \e[7m${options[$i]}\e[0m"
      else
        echo "  ${options[$i]}"
      fi
    done

    read -rsn1 key
    if [[ $key == $'\x1b' ]]; then
      read -rsn2 key
      [[ $key == "[A" ]] && ((selected--))
      [[ $key == "[B" ]] && ((selected++))
    elif [[ $key == "" ]]; then
      if [[ "${options[$selected]}" == "EXIT" ]]; then
        main_menu
      else
        read -p "Choose frequency (daily, weekly, monthly): " val
        if [[ "$val" != "daily" && "$val" != "weekly" && "$val" != "monthly" ]]; then
          echo "Provided value is incorrect!"
          sleep 1
          main_menu
        fi
        if grep -q "MODE=" "$CONFIG_FILE"; then
          sed -i "s|^MODE=.*|MODE=$val|" "$CONFIG_FILE"
        fi
        echo "Mode changed to: $val"
        sleep 1
        main_menu
      fi
    fi
  done
}

save_destination(){
  clear
  get_cfg_variables
  options=("Change destination" "EXIT")
  selected=0
  while true; do
    ((selected < 0)) && selected=0
    ((selected >= ${#options[@]})) && selected=$((${#options[@]} - 1))
    clear
    echo "Current destination $BACKUP_DEST"
    for i in "${!options[@]}"; do
      if [[ $i -eq $selected ]]; then
        echo -e "> \e[7m${options[$i]}\e[0m"
      else
        echo "  ${options[$i]}"
      fi
    done

    read -rsn1 key
    if [[ $key == $'\x1b' ]]; then
      read -rsn2 key
      [[ $key == "[A" ]] && ((selected--))
      [[ $key == "[B" ]] && ((selected++))
    elif [[ $key == "" ]]; then
      if [[ "${options[$selected]}" == "EXIT" ]]; then
        main_menu
      else
        read -p "Provide absolute path to directory: " dir
        expanded_dir=$(eval echo "$dir")
        if [[ ! -d "$expanded_dir" ]]; then
          echo "Provided path does not exist!"
          sleep 1
          main_menu
        fi
        if grep -q "BACKUP_DEST=" "$CONFIG_FILE"; then
          sed -i "s|^BACKUP_DEST=.*|BACKUP_DEST=$dir|" "$CONFIG_FILE"
        fi
        echo "Backup destination changed to: $expanded_dir"
        sleep 1
        main_menu
      fi
    fi
  done
}

source_settings(){
  options=("Add folder to backup" "Remove folders from backup", "EXIT")
  selected=0
  while true; do
    ((selected < 0)) && selected=0
    ((selected >= ${#options[@]})) && selected=$((${#options[@]} - 1))
    clear
    for i in "${!options[@]}"; do
      if [[ $i -eq $selected ]]; then
        echo -e "> \e[7m${options[$i]}\e[0m"
      else
        echo "  ${options[$i]}"
      fi
    done
    read -rsn1 key
    if [[ $key == $'\x1b' ]]; then
      read -rsn2 key
      [[ $key == "[A" ]] && ((selected--))
      [[ $key == "[B" ]] && ((selected++))
    elif [[ $key == "" ]]; then
      case $selected in
        0) add_folder_to_backup;;
        1) remove_folders_from_backup;;
        2) main_menu;;
      esac
    fi
  done
}

add_folder_to_backup(){
  clear
  read -p "Provide absolute path to directory: " dir
  expanded_dir=$(eval echo "$dir")
  existing_dirs=$(awk '/SOURCE_DIRS=\(/,/\)/' backup.conf | grep -o '".*"' | tr -d '"')
  if [[ ! -d "$expanded_dir" ]]; then
    echo "Provided path does not exist!"
    sleep 1
    source_settings
  fi
  for existing in $existing_dirs; do
    if [[ "$existing" == "$expanded_dir" ]]; then
      echo "Folder already exists"
      sleep 1
      source_settings
      return
    fi
  done
  sed -i "/SOURCE_DIRS=(/a \ \ \"$expanded_dir\"" backup.conf
  echo "Folder added"
  sleep 1
}
remove_folders_from_backup(){
  clear
  get_cfg_variables
  if [[ ${#SOURCE_DIRS[@]} -eq 0 ]]; then
    echo "No directories found."
    sleep 1
    source_settings
    return
  fi
  options=("${SOURCE_DIRS[@]}" "EXIT")
  selected=0
  while true; do
  ((selected < 0)) && selected=0
  ((selected >= ${#options[@]})) && selected=$((${#options[@]} - 1))
  clear
  echo "Select directory to remove:"
  for i in "${!options[@]}"; do
    if [[ $i -eq $selected ]]; then
      echo -e "> \e[7m${options[$i]}\e[0m"
    else
      echo "  ${options[$i]}"
    fi
  done

  read -rsn1 key
  if [[ $key == $'\x1b' ]]; then
    read -rsn2 key
    [[ $key == "[A" ]] && ((selected--))
    [[ $key == "[B" ]] && ((selected++))
  elif [[ $key == "" ]]; then
    if [[ "${options[$selected]}" == "EXIT" ]]; then
      source_settings
    else
      folder_to_remove="${options[$selected]}"
      expanded_path=$(eval echo "$folder_to_remove")
      sed -i "/[[:space:]]*\"${folder_to_remove//\//\\/}\"/d" backup.conf
      echo "Folder $folder_to_remove removed."
      sleep 1
      remove_folders_from_backup
      return
    fi
  fi
done
}
main_menu