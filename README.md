# Git Autocommit Bot
A tool for generative artists to automatically record ephemeral image sources.

# What is this?
This tool watches a specified directory for the creation of files with names
that match a specified pattern, and then automatically creates a git commit in a
source repository that represents the code that created that file.

I use this while creating generative art projects so that each output created
during the development process can be tracked back to a specific code/hash
combination, allowing me to easily recreate them as needed. 

NOTE: Since this only uses the filename as the commit message, be sure to put
the random number seed (and anything else you need to retain) into the filename
so that it's automatically included in the commit message.

This is a very basic set of shell scripts, but it solves my specific problem.
YMMV.

# WARNING!
* This has only been tested on MacOS! Other platforms may require changes.
* Make sure you're running the script in the correct directory or `rsync` will
  probably ruin your day.

# Required Tools
- [git](https://git-scm.com/) - Source code version control system
- [fswatch](https://emcrisostomo.github.io/fswatch/) - Cross-platform filesystem
  change watcher
- [rsync](https://rsync.samba.org/) - Synchronizes different directories

If you're on MacOS, you can use [`homebrew`](https://brew.sh/) to easily get
these via `brew install git fswatch rsync`.

# How to Use

1. Clone this repository onto your machine.
2. Create a [git worktree](https://git-scm.com/docs/git-worktree) branch of your
   in-development repository that will be used to record snapshots. I typically
   create a directory that contains all such repositories, so that they're out
   of my way when I'm doing other work.
   
   For example, if I have a development repository at
   `~/src/genart/my-new-project`, I create a directory called
   `~/src/autocommit-repos` that I use to store all of my active autocommit
   worktrees.
   
   Once you have a place to create your autocommit worktree, create it like
   this:

   ``` sh
   cd ~/src/genart/my-new-project
   git worktree add ~/src/autocommit-repos/my-new-project-autocommits -b autocommits
   ```

   This command creates an active git worktree for your current repository in
   the directory `~/src/autocommit-repos/my-new-project-autocommits` and checks
   out the branch `autocommits` in that repository. (You can name the branch
   whatever you want - just be sure that it's different from your active branch
   name.)
3. Go into this new directory and run the watcher script, providing a regular
   expression that will match the files that you want to trigger the autocommit
   snapshot process. 
   
   The command format is `watch.sh -r <regex> <directory to watch>`. For
   example:

   ``` sh
   cd ~/src/autocommit-repos/my-new-project-autocommits
   ~/src/git-autocommit-bot/watch.sh -r 'wip-.*.png$' ~/Downloads
   ```

   (Note that the regular expression format is best handled by a single-quoted
   string specification.)

# How exactly does this work?

When you run the `watch.sh` script:

1. An `fswatch` process is created that will watch for the creation of files
   that match the regular expression specified.
2. When a matching file is created, an `rsync` process is spawned that will copy
   everything that isn't ignored by the `.gitignore` file in original repository
   into your autocommits worktree.
3. A (potentially empty) commit will be created with the name of the file that
   was created as the commit message.

That's it.

Because all of these commits are on a separate branch, be sure to include them
when you push to your remote repository. I typically push all of my local
commits and branches via the following git command.

``` sh
git push origin --all
```

# Why?
I created this instead of using an existing tool like
[dura](https://github.com/tkellogg/dura) for two reasons:

1. I wanted a specific type of git history to be created for snapshots that was
   separate from my actual development commit history.
2. I like to tinker, and I had a feeling that this was possible with some simple
   shell script glue.

# Things I Learned Along the Way

## fswatch

`fswatch` requires you to exclude everything (via `-e '.*'`), and then specify the specific
pattern that should be matched (via `-i '<pattern>'`). This will only match files that have this naming
scheme, and ignore everything else.

``` sh
fswatch --event Created -e '.*' -i 'wip-.*.png$' ~/Downloads | xargs -I{} echo TEST: {}
```

## rsync

The `--exclude='.git/` will exclude the git repository data from the copy, since
that's not needed.

The `--filter=':- .gitignore'` flag will parse the contents of a `.gitignore`
file and exclude them from the transfer, avoiding things like copying the
`node_modules` directory, etc.

## git worktree

Don't use a bare repository with worktrees inside of them, as that comes with
some unexpected issues regarding fetching (see [this blog
post](https://morgan.cugerone.com/blog/workarounds-to-git-worktree-using-bare-repository-and-cannot-fetch-remote-branches/)).

## git commits

Create a (possibly empty) commit on the current branch by automatically
committing all changes.

``` sh
git add --all
git commit --allow-empty --message 'message'
```

# To Dos

## Notifications

Maybe add support for notifications?

A simple notification can be send from MacOS by running the following command:

``` sh
osascript -e 'display notification "notification message text"'
```

