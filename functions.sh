#!/usr/bin/env bash
#
# Author: Daniel Banta
# Created: 2019-10-28

# confirm user input
f_confirm() {
  while true; do
    printf "\n${1:-Continue?} [y/n]: " >&2
    read -r -n 1 REPLY
    case $REPLY in
      [yY]) echo ; return 0 ;;
      [nN]) echo ; return 1 ;;
      *) printf " ${RED} %s \n${RESET}" "invalid input" >&2
    esac 
  done  
}

# remove trailing slash from string
rm_slashes() {
  shopt -s extglob           # enable +(...) glob syntax
  echo "${1%%+/}"
}

# get the basename for a directory
get_base() {
  RES="$(rm_slashes "${1}")"
  echo "${RES##*/}"
}

clean_directory() {
  [[ -z $1 ]] && return 1 || DIR=$1

  # clean metadata if deep_clean is set
  find "${DIR}" -regextype sed -iregex ".*\.DS\_Store" -o -iregex ".*organizer" -o -iregex ".*appledouble" -o -iname "desktop.ini" -print0 2>/dev/null | xargs -0 rm -rf

  # Loop and delete all empty directories
  
  CLEANING=""
  while [[ -z ${CLEANING} ]]; do
    if [[ -n $(find "${DIR}" -type d -empty 2>/dev/null) ]]; then
      find "${DIR}" -type d -empty -print0 2>/dev/null | xargs -0 rm -rf
    else
      CLEANING=TRUE
    fi
  done

  # done
  return 0
}

create_md5_checksums() {
  [[ -z $1 ]] && return 1 || TARGET=${1}
  [[ -z $2 ]] && return 1 || MD5_FILE=${2}


  # get the current file from md5sum file. grep will return 0 if it is there are it will return 1 if it wasn't found
  #if [[ cat ${CHECKSUMS_TARGET} | grep -q "/home/daniel/Downloads/inactive/testing/target/2019-10-22_Filsona.md"
  # for every file that is found in the directory check if it exists in the md5sum file and append only the new values
  find "${TARGET}" -type f 2>/dev/null | while read file; do
    # reading hash and file name into array
    # [0] = hash, [1] = path/filename, [2] = filename
    
    HASH="$(md5sum "${file}" | awk '{print $1}')"

    # check if file exists in md5sum file, returns 0 if found
    cat ${MD5_FILE} | grep -q "${file}"
    if [[ $? -eq 0 ]]; then

      # check if md5 sum is found in md5sum file, returns 0 if found
      # don't do anything if the md5 sum already exists
      #
      # delete line from file if the md5 sums don't match and append the new one
      cat ${MD5_FILE} | grep -q "${HASH}"
      if [[ ! $? -eq 0 ]]; then 
        grep -v "${file}" "${MD5_FILE}" > "/tmp/md5temp" && mv "/tmp/md5temp" "${MD5_FILE}" && printf "%s\x20\x20%s\n" >> "${MD5_FILE}" "${HASH}" "${file}"
      fi
    else 
      # append new file to the checksum file
      printf "%s\x20\x20%s\n" >> "${MD5_FILE}" "${HASH}" "${file}"
    fi
  done
  return 0
}

calc_runtime() {

  [[ -z $1 ]] && echo "didn\'t run"
  [[ $1 -ge 0 ]] && RUNTIME=$1 || echo "1 second"
  
  DAYS=$(( ${RUNTIME} / 86400 ))
  HOURS=$(( ${RUNTIME} % 86400 / 3600 ))
  MINUTES=$(( ${RUNTIME} % 3600 / 60 ))
  SECONDS=$(( ${RUNTIME} % 60 ))
  
  MSG=""
  [[ ${DAYS} -eq 1 ]] && MSG="${MSG}${DAYS} day,"
  [[ ${DAYS} -gt 1 ]] && MSG="${MSG}${DAYS} days,"
  [[ ${HOURS} -eq 1 ]] && MSG="${MSG} ${HOURS} hour," 
  [[ ${HOURS} -gt 1 ]] && MSG="${MSG} ${HOURS} hours,"
  [[ ${MINUTES} -eq 1 ]] && MSG="${MSG} ${MINUTES} minute,"
  [[ ${MINUTES} -gt 1 ]] && MSG="${MSG} ${MINUTES} minutes,"
  [[ ${SECONDS} -eq 1 ]] && MSG="${MSG} ${SECONDS} second"
  [[ ${SECONDS} -gt 1 ]] && MSG="${MSG} ${SECONDS} seconds"
  
  echo ${MSG}
}