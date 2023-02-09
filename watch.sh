#!/usr/bin/env sh

#
## Watch the directory provided for new files and trigger a script when files are created
#
# The base directory that this script was run from
#
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

while getopts ':r:' OPTION; do
    case "$OPTION" in
        r)
            REGEX="$OPTARG"
            ;;
        *)
            echo "$0 -r <regex> <watch directory>"
            exit
            ;;
    esac
done
shift "$(($OPTIND - 1))"
WATCH_DIR=$1

if [ ! "${WATCH_DIR}" -o "${WATCH_DIR}" == " " -o ! -d "${WATCH_DIR}" ]; then
    echo "Error: Didn't receive a directory to watch. Aborting"
    exit -1
fi

if [ ! "${REGEX}" -o "${REGEX}" == " " ]; then
    echo "Error: Didn't receive a regular expression to watch. Aborting"
    exit -1
fi

# Get the name of the autocommit branch from the current worktree
BRANCH=`git branch --show-current`
if [ ! "${BRANCH}" -o "${BRANCH}" == " " ]; then
    echo "Error: Unable to retrieve current branch name. Is this a git worktree? Aborting."
    exit -1
fi

AUTOCOMMIT_DIR=`git worktree list | tr -s " " | grep "\[${BRANCH}\]" | cut -d " " -f 1`

# Find the parent repository of this worktree
REPO_DIR=`git worktree list | tr -s " " | grep -v "\[${BRANCH}\]" | cut -d " " -f 1`
if [[ $? -ne 0 ]]; then
    echo "Error attempting to retrieve the source repository. Aborting"
    exit -1
fi

if [ ! "${REPO_DIR}" -o "${REPO_DIR}" == " " -o ! -d "${REPO_DIR}" ]; then
    echo "Error: source repository couldn't be found. Aborting"
    exit -1
fi

printf "Source repo     : %s\n" ${REPO_DIR}
printf "Autocommit repo : %s\n" ${AUTOCOMMIT_DIR}
printf "\nWatching '%s'\nPress Ctrl-C to stop.\n" ${WATCH_DIR}
fswatch --event Created -e '.*' -i "${REGEX}" ${WATCH_DIR} | xargs -I{} ${SCRIPT_DIR}/sync-and-commit.sh {}
