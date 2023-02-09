#!/usr/bin/env sh
#
# Sync the current directory with the parent, and then create a git commit on the current branch
#
# TODO: Add error checking
#
# The parameter to this script is the name of the file that triggered the script to run
# - That file should ideally have the hash and any other required information in its name
# SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
# echo ${SCRIPT_DIR}
TRIGGER_PATH=$1

# This will remove any path information from the argument
TRIGGER_FILE=${TRIGGER_PATH##*/}

if [ ! "${TRIGGER_FILE}" -o "${TRIGGER_FILE}" == " " ]; then
    echo "Error: Didn't receive a trigger filename. Aborting"
    exit -1
fi

# Get the name of the autocommit branch from the current worktree
BRANCH=`git branch --show-current`
if [ ! "${BRANCH}" -o "${BRANCH}" == " " ]; then
    echo "Error: Unable to retrieve current branch name. Is this a git worktree?"
    exit -1
fi

# TODO: Add a check to make sure that this is not the main branch?


# Find the parent repository of this worktree
REPO_DIR=`git worktree list | tr -s " " | grep -v ${BRANCH} | cut -d " " -f 1`
if [[ $? -ne 0 ]]; then
    echo "Error attempting to retrieve the source repository. Aborting"
    exit -1
fi

if [ ! "${REPO_DIR}" -o "${REPO_DIR}" == " " -o ! -d "${REPO_DIR}" ]; then
    echo "Error: source repository couldn't be found. Aborting"
    exit -1
fi

# Now, rsync the content of the parent directory to this directory
# TODO: Check for failure
rsync --quiet --archive --exclude='.git/' --filter=':- .gitignore' ${REPO_DIR}/ .

# Create a commit using the name of the file that triggered this run as the commit message
# Be sure to allow empty commits as nothing may have changed but we still want to create a commit
# Need to run `git add --all` to ensure that new files are captured because `git commit --all` ignores them
git add --all
git commit --quiet --allow-empty --message ${TRIGGER_FILE}

# TODO: Put this behind a verbose flag?
printf "Created commit for %s\n" ${TRIGGER_FILE}
