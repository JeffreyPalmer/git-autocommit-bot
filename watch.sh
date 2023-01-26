#!/usr/bin/env sh

# Watch the directory provided for new files and trigger a script when files are created
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

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
printf "Watching '%s'\nPress Ctrl-C to stop.\n" ${WATCH_DIR}

fswatch --event Created -e '.*' -i "${REGEX}" ${WATCH_DIR} | xargs -I{} ${SCRIPT_DIR}/sync-and-commit.sh {}
