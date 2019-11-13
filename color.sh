#!/usr/bin/env bash
#
# Author: Daniel Banta
# Created: 2019-11-04
RED=$'\033[5;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
BLUE=$'\033[0;34m'
GREY=$'\033[90;40m'
RESET=$'\033[0m'
BOLD=$'\033[1m'

ERROR="${RED}[ERROR]${RESET}"
INFO="${GREY}[INFO]${RESET}"
DONE="${BLUE} ... done${RESET}"
SUCCESS="${GREEN} ... success${RESET}"
MOVE="${BOLD}[MOVE]${RESET}"
DELETE="${YELLOW}[DELETE]${RESET}"


HELP_MSG="This script compares two directories and deletes duplicates and moves the rest to an import folder.\n\
USAGE: ${BOLD}./main.sh [OPTIONS] \"SOURCE\" \"TARGET\"${RESET} \
\n\n \
\t${BOLD}SOURCE${RESET}:\tThis is the directory that contains possible duplicates \n\
\t${BOLD}TARGET${RESET}:\tContains the files that you want to keep and that you want to import the SOURCE to \n\
\t${GREY}Please note that the quotation marks are required to accept paths with space in the name${RESET} \n\
\n\n \
The following options are available:\n\n \
\t${BOLD}-d${RESET}\tDon't delete duplicate files from SOURCE folder \n\
\t${BOLD}-D${RESET}\tDelete empty folders and metadata files from TARGET. On default only SOURCE will be cleaned of those files and folders \n\
\t${BOLD}-m${RESET}\tKeep unmatched files in SOURCE and don't move them to the import folder in TARGET \n\
\t${BOLD}-M${RESET}:\tThe default MD5 Checksum file will created in /tmp, i.e. will not be saved.\n\t\tActivate this option if you want to save the MD5 Checksum file for referencing it later. It will be saved to ~/.checksums \n\
\t${BOLD}-v${RESET}\tVerbose - Show additional information during the run of the script \n\
\t${BOLD}-y${RESET}\tAssume 'yes' to all \n\
\t${BOLD}--help${RESET}\tShow this help message \n\
\n"