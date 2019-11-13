#!/usr/bin/env bash
#
# Author: Daniel Banta
# Created: 2019-10-28
#
#
# importing config file
source ./color.sh
source ./chk_config.sh
source ./functions.sh

declare -A config
TODAY=$(date +"%Y%m%d-%H%M")
START_TIME=$(date +%s)

#================================================================
#
# CHECKING CONFIGURATION
#
#================================================================

# default values
config[CLEAN_TARGET]=0 # delete empty folders and metadata from TARGET
config[DELETE]=1 # delete duplicate files from SOURCE
config[MOVE]=1 # move unmatched files from SOURCE to TARGET
config[MD5]=0 # create md5 checksum file from target in /tmp
config[VERBOSE]=0 # only show minmal infos
config[PERMISSIVE]=0 # ask user for permissions to use config

# config settings can be overwritten by using options and parameters
while [ -n "${1}" ]; do 
 
    case "${1}" in
    -d) config[DELETE]=0 ;;
    -D) config[CLEAN_TARGET]=1 ;;
    -m) config[MOVE]=0 ;;
    -M) config[MD5]=1 ;;
    -v) config[VERBOSE]=1 ;;
    -y) config[PERMISSIVE]=1 ;;
    --help) printf "${HELP_MSG}" && exit 0;;

    *) break ;;
    esac
    shift
done
# set md5 dir - default /tmp if -M was not set otherwise ~/.checksums
[[ ${config[MD5]} -eq 1 ]] && config[MD5_DIR]="$(chk_directory "md5" "~/.checksums" | xargs )" || config[MD5_DIR]="$(chk_directory "md5" "/tmp" | xargs )"

# get directories from parameters and overwrite config file
[[ -n ${1} ]] && config[SOURCE_DIR]="${1}"
[[ -n ${2} ]] && config[TARGET_DIR]="${2}"

#
# check the config and get permission from user
config[SOURCE_DIR]="$(chk_directory "source" "${config[SOURCE_DIR]}" | xargs )"
config[TARGET_DIR]="$(chk_directory "target" "${config[TARGET_DIR]}" | xargs )"


# print configuration for this run and ask user for permission
# permission is not necessary if the -y option was set
if [[ ! ${config[PERMISSIVE]} -eq 1 ]]; then
  clear
  MSG="\n${YELLOW}Please check your configuration:${RESET} \n\
${BLUE}[SOURCE_DIR]${GREEN}\t${config[SOURCE_DIR]}\t${GREY}This is the folder that might contain duplicates.${RESET} \n\
${BLUE}[TARGET_DIR]${GREEN}\t${config[TARGET_DIR]}\t${GREY}This is the folder the files are supposed to be merged in to.${RESET} \n${BLUE}[CHECKSUM_SAVE]\t"
  [[ ${config[MD5_DIR]} == "/tmp/" ]] && MSG="${MSG}${YELLOW}Off\t${GREY}Delete file checksums from TARGET after use${RESET} \n" || MSG="${MSG}${GREEN}Checksum files will be saved to ~/.checksums${RESET}  \n"   

  if [[ ${config[VERBOSE]} -eq 1 ]]; then
    # CLEAN_TARGET
    MSG="${MSG}${BLUE}[CLEAN_TARGET]\t"
    [[ ${config[DEEP_CLEAN]} -eq 1 ]] && MSG="${MSG}${GREEN}On${RESET}" || MSG="${MSG}${YELLOW}Off${RESET}"
    MSG="${MSG}\t${GREY}Performs a deep clean of TARGET including files like .AppleDouble, .DsStore etc. and empty folders${RESET}\n"

    # DELETE
    MSG="${MSG}${BLUE}[DELETE]\t"
    [[ ${config[DELETE]} -eq 1 ]] && MSG="${MSG}${GREEN}On${RESET}" || MSG="${MSG}${YELLOW}Off${RESET}"
    MSG="${MSG}\t${GREY}Duplicate files will not be delete from SOURCE${RESET}\n"

    # MOVE
    MSG="${MSG}${BLUE}[MOVE]\t\t"
    [[ ${config[MOVE]} -eq 1 ]] && MSG="${MSG}${GREEN}On${RESET}" || MSG="${MSG}${YELLOW}Off${RESET}"
    MSG="${MSG}\t${GREY}Move unmatched files from SOURCE to import folder in TARGET${RESET}\n"

    # VERBOSE
    MSG="${MSG}${BLUE}[VERBOSE]\t"
    [[ ${config[VERBOSE]} -eq 1 ]] && MSG="${MSG}${GREEN}On${RESET}" || MSG="${MSG}${YELLOW}Off${RESET}"
    MSG="${MSG}\t${GREY}Print additional information, helpful for debugging.${RESET}\n"
    # PERMISSIVE
    MSG="${MSG}${BLUE}[PERMISSIVE]\t"
    [[ ${config[PERMISSIVE]} -eq 1 ]] && MSG="${MSG}${GREEN}On${RESET}" || MSG="${MSG}${YELLOW}Off${RESET}"
    MSG="${MSG}\t${GREY}Assume yes to entire config.${RESET}\n"

  fi # end print config 
    printf "${MSG}"

  ! f_confirm && exit 0
fi
# ///// END CHECK CONFIG


#================================================================
#
# BEGIN WITH TESTING
#
#================================================================

# define checksum file for target dir
MD=${config[TARGET_DIR]%/}
CHECKSUMS_TARGET="${config[MD5_DIR]}${MD##*/}.md5"

# remove any old MD5 file in tmp directory
[[ ${config[MD5_DIR]} == "/tmp/" ]] && rm -rf "${CHECKSUMS_TARGET}"

#....................
# Clean and create MD5s for TARGET DIR
#....................


# clean metadata and empty folder if clean_target is set
if [[ ${config[CLEAN_TARGET]} -eq 1 ]]; then 
  printf "%s Cleaning up TARGET" "${INFO}"
  clean_directory "${config[TARGET_DIR]}"
  [[ $? -eq 0 ]] && printf "%s\n" "${DONE}" || printf "%s Code: %s\n" "${ERROR}" "${?}"
fi


# create md5 checksums
if [[ ! -f ${CHECKSUMS_TARGET} ]]; then
  printf "%s Creating MD5 checksums for TARGET" "${INFO}"
  find "${config[TARGET_DIR]}" -type f -exec md5sum {} >> "${CHECKSUMS_TARGET}" \;
else
  printf "%s Updating MD5 checksums for TARGET" "${INFO}"
  create_md5_checksums "${config[TARGET_DIR]}" "${CHECKSUMS_TARGET}"
fi
[[ $? -eq 0 ]] && printf "${SUCCESS}\n" || printf "%s Code: %s\n" "${ERROR}" "${?}"
#... done with target dir

#....................
# Clean and compare MD5s for SOURCE DIR
#....................
printf "%s Cleaning up SOURCE" "${INFO}"
clean_directory "${config[SOURCE_DIR]}"
[[ $? -eq 0 ]] && printf "%s\n" "${DONE}" || printf "%s Code: %s\n" "${ERROR}" "${?}"


# comparing files from both folders
# delete from SOURCE if they match
# printf "%s Comparing SOURCE and TARGET files ...\n" "${INFO}"

find "${config[SOURCE_DIR]}" -type f 2>/dev/null | while read file; do

  # populating array with data from current file in loop
  declare -A FILE
  FILE[HASH]="$(md5sum "${file}" | awk '{print $1}')"
  FILE[POINTER]="${file}"
  FILE[FNAME]="${file##*/}"
  # the relative path is calculate like: "Length File Pointer" - ( "Length SOURCE Path" + "Length Filename" )
  FILE[RELPATH]="${file:${#config[SOURCE_DIR]}:$(( ${#file} - ( ${#config[SOURCE_DIR]} + ${#FILE[FNAME]} ) ))}"

  printf "%sProcessing:\t%s%s\n" "${BLUE}" "${RESET}" "${FILE[RELPATH]:-"./"}${FILE[FNAME]}" 

  # check if file checksum exists in target directory
  cat "${CHECKSUMS_TARGET}" | grep -q "${FILE[HASH]}"
  if [[ $? -eq 0 ]]; then

    # if it exists, delete it from source dir, but only if deleting is not overwritten by user
    if [[ ${config[DELETE]} -eq 1 ]]; then 
      rm -rf "${file}"
      [[ $? -eq 1 ]] && printf "%s Couldn't delete %s\n%sCode: %s\n" "${ERROR}" "${FILE[RELPATH]:-"./"}${FILE[FNAME]}" "${ERROR}" "${?}"

      if [[ ${config[VERBOSE]} -eq 1 ]] && [[ $? -eq 0 ]]; then  
        printf "%s duplicate file %s\n" "${DELETE}" "${SUCCESS}"      
      fi
    fi


  else
    if [[ ${config[MOVE]} -eq 1 ]]; then 
      if [[ ${config[VERBOSE]} -eq 1 ]]; then  
        printf "%s new file " "${MOVE}"     
      fi
      # if it doesn't exists move it to import folder in target dir

      
      MV2_IMPORT="${config[TARGET_DIR]}.import/${TODAY}/${FILE[RELPATH]:-"./"}"
      mkdir -p "${MV2_IMPORT}" && mv "${file}" "$_"
      if [[ ${config[VERBOSE]} -eq 1 ]] && [[ $? -eq 0 ]]; then  
        printf "%s\n" "${SUCCESS}"  
      fi
      
      [[ $? -eq 1 ]] && printf "%s Couldn't move to import directory %s\n%sCode: %s\n" "${ERROR}" "${FILE[RELPATH]:-"./"}${FILE[FNAME]}" "${ERROR}" "${?}" 
    fi
  fi
done
# if output is set to quiet the output would be missing a done notification
[[ ${config[VERBOSE]} -eq 0 ]] && printf "%s\n" "${DONE}"

# ///// END TESTING

#================================================================
#
# END SCRIPT WITH CLEANING EMPTY FOLDERS FROM SOURCE
#
#================================================================
printf "%s Cleaning up ..." "${INFO}"
# cleaning out SOURCE
clean_directory "${config[SOURCE_DIR]}"
[[ $? -eq 0 ]] && printf "%s\n" "${DONE}" || printf "\n%s Code: %s\n" "${ERROR}" "${?}"

# End first loop if no files in source directory are being deleted
#   if [[ ${config[DELETE]} -eq 0 ]] || [[ ${config[MOVE]} -eq 0 ]] || [[ ! -d "${config[SOURCE_DIR]}" ]]; then LOOP=false; fi
# done # end while loop as long as source dir exists

# deleting checksums if necessary
[[ ${config[MD5]} -eq 0 ]] && rm -rf "${CHECKSUMS_TARGET}"

CURRENT_TIME=$(date +%s)
RAN=$(calc_runtime "$(( ${CURRENT_TIME} - ${START_TIME}))")
printf "\nTotal Runtime: %s\n" "${RAN}"
