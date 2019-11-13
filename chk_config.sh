#!/usr/bin/env bash
#
# Author: Daniel Banta
# Created: 2019-10-30

chk_dupe() {
  for ELEM in ${config[@]}; do
    if [[ "${ELEM}" == "${2}" ]] && [[ ${config[${1}]} ]]; then 
      echo -n "${ERROR}The provided path is already in use by this script.\n${ELEM} vs. ${1}" >&2
      return 1 # return error if duplicate
    else
      continue
    fi
  done
  return 0 # return true if not in array
}

chk_directory () {

  # clean parameters and set variable
  #
  # $1 = folder to be checked and set as folder name e.g. "source"
  [[ -n ${1} ]] && ACTION="${1,,}" || return 1
  #
  # $2 = folder address, can be omitted for "md5" because it defaults to /tmp
  [[ -z ${2} ]] && [[ ${ACTION} == "md5" ]] && DIR="/tmp"
  [[ -n ${2} ]] && [[ ${ACTION} == "md5" ]] && DIR="${2}"
  #
  if [[ ${ACTION} =~ source|target ]]; then 
    [[ -z ${2} ]] && DIR="" || DIR=${2}
  fi

  [[ -z ${DIR} ]] && DIR="$(get_directory "${ACTION,,}" "")"

  MSG="${INFO}Do you want to use this as your ${GREEN}${ACTION^^}${RESET} folder: ${YELLOW}${DIR}${RESET}"

  # confirm dir with user or ask for user input

  if [[ ${ACTION} == "md5" ]]; then
    DIR="$(echo "$(set_directory "${DIR}" "${ACTION}" )" | xargs)"
  #
  # if DIR is set and the user wants to set it
  elif [[ -n ${DIR} ]] && [[ ${config[PERMISSIVE]} -eq 1 ]] ; then
    DIR="$(rm_slashes ${DIR})"
    DIR="$(echo "$(set_directory "${DIR}" "${ACTION}" )" | xargs)"
  elif [[ -n ${DIR} ]] && [[ ! ${config[PERMISSIVE]} -eq 1 ]] && f_confirm "${MSG}" ; then
    DIR="$(rm_slashes ${DIR})"
    DIR="$(echo "$(set_directory "${DIR}" "${ACTION}" )" | xargs)"
  else
    DIR="$(echo "$(get_directory "${ACTION}" )" | xargs)"
  fi
 
  # validate directory and echo it
  CHECK=false
  while ! $CHECK; do

    # check if Directory is already in array  
    if chk_dupe "${ACTION}" "${DIR}"  && [[ -d "${DIR}" ]]; then
      CHECK=true
    elif [[ ${ACTION} == "md5" ]] && $(mkdir -p "${DIR}"); then
      printf "\n${GREEN}[SUCCESS]${RESET} Created folder to store checksum files in: ${DIR} \n" >&2
      CHECK=true
    else 
      printf "\n${ERROR}The provided path couldn't be validated. Please try again.\n" >&2
      DIR="$(echo "$(get_directory "${ACTION}" )" | xargs)" 
    fi
  done

  echo "${DIR}"

}

get_directory() {

  DIR=""

  # loop while input is not a directory
  while [[ ! -d "${DIR}" ]] || [[ "${DIR}" == "" ]]; do
    
    # reading folder from input
    printf "Please select a folder as the ${1^^}  [Shortcuts: (T)his, (H)ome ]: " >&2
    read -e DIR

    # convert shortcuts
    case "${DIR}" in
      [tT] ) 
        DIR="${PWD}" ;;

      [hH] ) 
        DIR="${HOME}" ;;

      "")
        DIR="/dev/null" ;;
      *) 
        DIR="${DIR}" ;
    esac

    # clean up and set dir
    DIR="$(set_directory "${DIR}")"
  done # end while not DIR
  echo "${DIR}" # return name of folder
}

set_directory() {
  # get characters before and after first slash
  PRE=${1%%/*}
  POST=${1#*/}

  # check for home, root, and relative paths
  case ${PRE} in 
  "~")
    DIR="${HOME}/${POST}" ;;
  "") # i.e. root like /var/tmp
    DIR="${1}" ;;
  *) # relative paths like some/dir or ../sibling/dir
    DIR="${PWD}/${1}" ;;
  esac

  # clean double slashes
  DIR="$(echo "${DIR}" | sed -e 's/\/\//\//g' | xargs)"

  # clean up path if realpath is available
  [[ $(command -v realpath) ]] && DIR="$(realpath "${DIR}")"

  # add slash to end of path if it doesn't exist
  if [[ ${DIR:-1} != "/" ]]; then DIR="${DIR}/"; fi
  
  # return value for directory
  echo "${DIR}"
}