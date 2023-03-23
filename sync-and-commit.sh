#!/usr/bin/env sh

set -o errexit   # abort on nonzero exitstatus
set -o nounset   # abort on unbound variable
set -o pipefail  # don't hide errors within pipes
#
# Sync the current directory with the parent, and then create a git commit on the current branch
#
# TODO: Add error checking
#
# The first parameter of this script is the source repository directory
# The second parameter to this script is the name of the file that triggered the script to run
# - That file should ideally have the hash and any other required information in its name
REPO_DIR=$1
TRIGGER_PATH=$2

# This will remove any path information from the argument
TRIGGER_FILE=${TRIGGER_PATH##*/}

if [ ! "${TRIGGER_FILE}" -o "${TRIGGER_FILE}" == " " ]; then
    echo "Error: Didn't receive a trigger filename. Aborting"
    exit -1
fi

# Double-check the parent repository of this worktree
if [ ! "${REPO_DIR}" -o "${REPO_DIR}" == " " -o ! -d "${REPO_DIR}" ]; then
    echo "Error: source repository couldn't be found. Aborting"
    exit -1
fi

# Now, rsync the content of the parent directory to this directory
rsync --quiet --archive --exclude='.git/' --filter=':- .gitignore' "${REPO_DIR}/" .

# Create a commit using the name of the file that triggered this run as the commit message
# Be sure to allow empty commits as nothing may have changed but we still want to create a commit
# Need to run `git add --all` to ensure that new files are captured because `git commit --all` ignores them
git add --all
git commit --quiet --allow-empty --message "${TRIGGER_FILE}"

# TODO: Put this behind a verbose flag?
printf "Created commit for %s\n" "${TRIGGER_FILE}"
