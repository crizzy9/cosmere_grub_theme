#!/bin/bash

# Grub2 Theme
##########################################################################
# This is taken from the Tela grub theme and is therefore licensed 
# under the GNU General Public License
##########################################################################

ROOT_UID=0
THEME_DIR="/usr/share/grub/themes"
THEME_NAME=stormlight

MAX_DELAY=20                                        # max delay for user to enter root password

#COLORS
CDEF=" \033[0m"                                     # default color
CCIN=" \033[0;36m"                                  # info color
CGSC=" \033[0;32m"                                  # success color
CRER=" \033[0;31m"                                  # error color
CWAR=" \033[0;33m"                                  # waring color
b_CDEF=" \033[1;37m"                                # bold default color
b_CCIN=" \033[1;36m"                                # bold info color
b_CGSC=" \033[1;32m"                                # bold success color
b_CRER=" \033[1;31m"                                # bold error color
b_CWAR=" \033[1;33m"                                # bold warning color

# echo like ...  with  flag type  and display message  colors
prompt () {
  case ${1} in
    "-s"|"--success")
      echo -e "${b_CGSC}${@/-s/}${CDEF}";;          # print success message
    "-e"|"--error")
      echo -e "${b_CRER}${@/-e/}${CDEF}";;          # print error message
    "-w"|"--warning")
      echo -e "${b_CWAR}${@/-w/}${CDEF}";;          # print warning message
    "-i"|"--info")
      echo -e "${b_CCIN}${@/-i/}${CDEF}";;          # print info message
    *)
    echo -e "$@"
    ;;
  esac
}

# Welcome message
prompt -s "\n\t************************\n\t*  ${THEME_NAME} - Grub2 Theme  *\n\t************************"

# Check command avalibility
function has_command() {
  command -v $1 > /dev/null
}

prompt -w "\nChecking for root access...\n"

# Checking for root access and proceed if it is present
if [ "$UID" -eq "$ROOT_UID" ]; then

  # Create themes directory if not exists
  prompt -i "\nChecking for the existence of themes directory...\n"
  [[ -d ${THEME_DIR}/${THEME_NAME} ]] && rm -rf ${THEME_DIR}/${THEME_NAME}
  mkdir -p "${THEME_DIR}/${THEME_NAME}"

  # Copy theme
  prompt -i "\nInstalling ${THEME_NAME} theme...\n"

  cp -a ${THEME_NAME}/* ${THEME_DIR}/${THEME_NAME}

  # Generate GRUB font files to ensure compatibility
  prompt -i "\nGenerating GRUB font files...\n"
  
  if has_command grub-mkfont; then
    cd "${THEME_DIR}/${THEME_NAME}"
    
    # Generate Dersu Uzala brush fonts
    if [ -f "Dersu Uzala brush.ttf" ]; then
      prompt -i "Generating Dersu Uzala brush fonts..."
      grub-mkfont -s 16 -o "dersu_uzala_brush_16.pf2" "Dersu Uzala brush.ttf" 2>/dev/null || prompt -w "Failed to generate dersu_uzala_brush_16.pf2"
      grub-mkfont -s 54 -o "dersu_uzala_brush_54.pf2" "Dersu Uzala brush.ttf" 2>/dev/null || prompt -w "Failed to generate dersu_uzala_brush_54.pf2"  
      grub-mkfont -s 60 -o "dersu_uzala_brush_60.pf2" "Dersu Uzala brush.ttf" 2>/dev/null || prompt -w "Failed to generate dersu_uzala_brush_60.pf2"
    else
      prompt -w "Dersu Uzala brush.ttf not found, using pre-compiled fonts"
    fi
    
    # Generate Fira Code fonts
    if [ -f "FiraCode-Regular.ttf" ]; then
      prompt -i "Generating Fira Code fonts..."
      grub-mkfont -s 16 -o "fira_code_16.pf2" "FiraCode-Regular.ttf" 2>/dev/null || prompt -w "Failed to generate fira_code_16.pf2"
      grub-mkfont -s 20 -o "fira_code_20.pf2" "FiraCode-Regular.ttf" 2>/dev/null || prompt -w "Failed to generate fira_code_20.pf2"
    else
      prompt -w "FiraCode-Regular.ttf not found, using pre-compiled fonts"
    fi
    
    prompt -s "Font generation completed."
  else
    prompt -w "grub-mkfont not found. Using pre-compiled font files."
    prompt -i "If fonts don't display correctly, install grub2-common (Debian/Ubuntu) or grub2-tools (Fedora/RHEL)"
  fi

# Set theme
  prompt -i "\nSetting ${THEME_NAME} as default...\n"

  # Backup grub config
  cp -an /etc/default/grub /etc/default/grub.bak

  grep "GRUB_THEME=" /etc/default/grub 2>&1 >/dev/null && sed -i '/GRUB_THEME=/d' /etc/default/grub
  echo "GRUB_THEME=\"${THEME_DIR}/${THEME_NAME}/theme.txt\"" >> /etc/default/grub

  # Ensure GRUB_TERMINAL_OUTPUT is set to gfxterm
  prompt -i "Ensuring GRUB_TERMINAL_OUTPUT is set to gfxterm..."
  if grep -q '^GRUB_TERMINAL_OUTPUT=' /etc/default/grub; then
    # If the line exists, modify it
    if ! grep -q '^GRUB_TERMINAL_OUTPUT="gfxterm"' /etc/default/grub; then
      sed -i 's/^GRUB_TERMINAL_OUTPUT=.*/GRUB_TERMINAL_OUTPUT="gfxterm"/' /etc/default/grub
      prompt -s "GRUB_TERMINAL_OUTPUT modified to gfxterm."
    else
      prompt -i "GRUB_TERMINAL_OUTPUT is already set to gfxterm."
    fi
  else
    # If the line doesn't exist, add it
    echo 'GRUB_TERMINAL_OUTPUT="gfxterm"' >> /etc/default/grub
    prompt -s "GRUB_TERMINAL_OUTPUT added and set to gfxterm."
  fi

# Update grub config
  prompt -i "\nUpdating grub configuration..."
  if has_command update-grub; then
    prompt -i "Using uepdate-grub..."
    if update-grub; then
      prompt -s "GRUB configuration updated successfully."
    else
      prompt -e "update-grub failed. Please update GRUB manually."
    fi
  elif has_command grub-mkconfig; then # For GRUB (legacy) or systems using this command name for GRUB2
    prompt -i "Using grub-mkconfig -o /boot/grub/grub.cfg..."
    if grub-mkconfig -o /boot/grub/grub.cfg; then
      prompt -s "GRUB configuration updated successfully."
    else
      prompt -e "grub-mkconfig -o /boot/grub/grub.cfg failed. Trying grub2-mkconfig if available or update manually."
      # Fall through to grub2-mkconfig if grub-mkconfig failed and grub2-mkconfig exists
      if ! has_command grub2-mkconfig; then
        prompt -e "No grub2-mkconfig found. Please update GRUB manually."
      fi
    fi
  fi

  # This 'if' block for grub2-mkconfig can be entered directly OR as a fallback from grub-mkconfig failing
  if has_command grub2-mkconfig && ! (has_command update-grub && update-grub &>/dev/null); then # Only run if update-grub didn't succeed or isn't the primary
    GRUB_UPDATED_BY_GRUB2_MKCONFIG=false
    prompt -i "Using grub2-mkconfig. Detecting system type..."

    # Default paths to try, in order of preference
    GRUB2_PATHS_TO_TRY=()

    # Check for UEFI
    IS_UEFI=false
    if [ -d /sys/firmware/efi ]; then
      IS_UEFI=true
      prompt -i "UEFI system detected."
    else
      prompt -i "BIOS/Legacy system detected (or /sys/firmware/efi not found)."
    fi

    if has_command dnf; then # Fedora, RHEL, CentOS like
      prompt -i "DNF package manager detected (Fedora/RHEL like)."
      if $IS_UEFI; then
        GRUB2_PATHS_TO_TRY+=("/boot/efi/EFI/fedora/grub.cfg") # Common Fedora UEFI path
      fi
      GRUB2_PATHS_TO_TRY+=("/boot/grub2/grub.cfg") # Common Fedora BIOS path or fallback

    elif has_command zypper; then # openSUSE like
      prompt -i "Zypper package manager detected (openSUSE like)."
      # openSUSE often uses /boot/grub2/grub.cfg for both BIOS and UEFI
      GRUB2_PATHS_TO_TRY+=("/boot/grub2/grub.cfg")

    elif has_command apt-get || has_command apt; then # Debian, Ubuntu like
        prompt -i "APT package manager detected (Debian/Ubuntu like)."
        # These systems more commonly use update-grub which calls grub-mkconfig.
        # If update-grub wasn't used or failed, and we are here with grub2-mkconfig:
        if $IS_UEFI; then
          GRUB2_PATHS_TO_TRY+=("/boot/efi/EFI/ubuntu/grub.cfg") # Ubuntu UEFI
          GRUB2_PATHS_TO_TRY+=("/boot/efi/EFI/debian/grub.cfg") # Debian UEFI
        fi
        GRUB2_PATHS_TO_TRY+=("/boot/grub/grub.cfg") # Common for grub2-mkconfig on these systems too

    else
      prompt -i "No specific package manager (dnf, zypper, apt) detected for grub2-mkconfig hints. Using general paths."
    fi

    # Add general fallbacks if not already added or if no distro specific paths were found
    # Ensure common paths are in the list, preventing duplicates later
    GENERAL_FALLBACKS=("/boot/grub2/grub.cfg" "/boot/grub/grub.cfg")
    for p in "${GENERAL_FALLBACKS[@]}"; do
      if [[ ! " ${GRUB2_PATHS_TO_TRY[@]} " =~ " ${p} " ]]; then
        GRUB2_PATHS_TO_TRY+=("$p")
      fi
    done
    
    # Remove duplicate paths that might have been added by different logic branches
    UNIQUE_GRUB_PATHS_TO_TRY=($(echo "${GRUB2_PATHS_TO_TRY[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))


    for grub_cfg_path in "${UNIQUE_GRUB_PATHS_TO_TRY[@]}"; do
      if [ -z "${grub_cfg_path}" ]; then continue; fi # Skip empty path if array was empty
      prompt -i "Attempting to update GRUB with: grub2-mkconfig -o ${grub_cfg_path}"
      # Check if the parent directory for the grub config exists.
      # This is a heuristic to see if it's a plausible location.
      grub_cfg_dir=$(dirname "${grub_cfg_path}")
      if [ ! -d "${grub_cfg_dir}" ]; then
          prompt -w "Parent directory ${grub_cfg_dir} for GRUB path ${grub_cfg_path} does not exist. Skipping."
          continue
      fi

      if grub2-mkconfig -o "${grub_cfg_path}"; then
        prompt -s "GRUB configuration updated successfully at ${grub_cfg_path}."
        GRUB_UPDATED_BY_GRUB2_MKCONFIG=true
        break # Exit loop on success
      else
        prompt -w "Failed to update GRUB at ${grub_cfg_path}."
      fi
    done

    if ! $GRUB_UPDATED_BY_GRUB2_MKCONFIG; then
      prompt -e "grub2-mkconfig failed to update GRUB with common paths."
      prompt -e "Please determine your GRUB configuration file path and run manually, e.g.:"
      prompt -e "sudo grub2-mkconfig -o /path/to/your/grub.cfg"
    fi
  elif ! has_command update-grub && ! has_command grub-mkconfig && ! has_command grub2-mkconfig; then
    prompt -e "No GRUB update command (update-grub, grub-mkconfig, grub2-mkconfig) found. Please update GRUB manually."
  fi

  # Success message
  prompt -s "\n\t          ***************\n\t          *  All done!  *\n\t          ***************\n"

else

  # Error message
  prompt -e "\n [ Error! ] -> Run me as root "

  # persisted execution of the script as root
  read -p "[ trusted ] specify the root password : " -t${MAX_DELAY} -s
  [[ -n "$REPLY" ]] && {
    sudo -S <<< $REPLY $0
  } || {
    prompt  "\n Operation canceled  Bye"
    exit 1
  }
fi
