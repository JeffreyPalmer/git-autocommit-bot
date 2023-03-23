#!/usr/bin/env sh

set -o nounset   # abort on unbound variable
set -o pipefail  # don't hide errors within pipes
#
## Watch the directory provided for new files and trigger a script when files are created
#
# The base directory that this script was run from
#
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SRC_BRANCH=main

while getopts ':r:b:' OPTION; do
    case "$OPTION" in
        r)
            REGEX="$OPTARG"
            ;;
        b)
            SRC_BRANCH="$OPTARG"
            ;;
        *)
            printf "$0 -r <regex> -b <branch> <watch directory> \n"
            exit
            ;;
    esac
done
shift "$(($OPTIND - 1))"
WATCH_DIR=$1

printf "SRC_BRANCH: %s\n" ${SRC_BRANCH}

if [ ! "${WATCH_DIR}" -o "${WATCH_DIR}" == " " -o ! -d "${WATCH_DIR}" ]; then
    printf "Error: Didn't receive a directory to watch. Aborting\n"
    exit -1
fi

if [ ! "${REGEX}" -o "${REGEX}" == " " ]; then
    printf "Error: Didn't receive a regular expression to watch. Aborting\n"
    exit -1
fi

# Get the name of the autocommit branch from the current worktree
BRANCH=$(git branch --show-current)
if [ ! "${BRANCH}" -o "${BRANCH}" == " " ]; then
    printf "Error: Unable to retrieve current branch name. Is this a git worktree? Aborting.\n"
    exit -1
fi

NUM_WORKTREES=$(git worktree list | grep "\[${SRC_BRANCH}\]" | expr $(wc -l))
if [ ${NUM_WORKTREES} -ne 1 ]; then
    printf "Error: Unable to determine the correct source for changes. Please use the -b <branch> option. Aborting.\n"
    exit -1
fi

AUTOCOMMIT_DIR=$(git worktree list | tr -s " " | grep "\[${BRANCH}\]" | cut -d " " -f 1)

# Find the parent repository of this worktree
REPO_DIR=$(git worktree list | tr -s " " | grep "\[${SRC_BRANCH}\]" | cut -d " " -f 1)
if [ ! "${REPO_DIR}" -o "${REPO_DIR}" == " " -o ! -d "${REPO_DIR}" ]; then
    printf "Error: source repository couldn't be found. Aborting\n"
    exit -1
fi

printf "Source repo     : %s\n" "${REPO_DIR}"
printf "Autocommit repo : %s\n" "${AUTOCOMMIT_DIR}"
printf "\nWatching '%s'\nPress Ctrl-C to stop.\n" "${WATCH_DIR}"
fswatch --event Created -e '.*' -i "${REGEX}" "${WATCH_DIR}" | xargs -I{} "${SCRIPT_DIR}/sync-and-commit.sh" "${REPO_DIR}" {}
