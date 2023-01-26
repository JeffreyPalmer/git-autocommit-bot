# What is this?
The idea behind this tool is to automatically tag a git repository with
information relating to a generated file (I use this for generative art) such
that that output can be tracked and recreated as necessary.


# How should it work?

There should either be a config file that is read, or it should accept command line params

When a file is created:
1. Create a commit in a branch that is specifically for the saving of these
   types of commits. This branch is a separate history, so that the actual
   development history is not corrupted by these constant commits.
2. Always create a commit, even if there have been no code changes since the
   last commit? Or should a tag be created instead? It's probably better to
   always have commits that contain the information about the image that was
   generated, so that it can be easily searched with a single command.
3. Also, the commit should be pushed to that other branch without any changes to
   the currently active branch (which would be disruptive to the active
   development process).
4. Simply store the name of the file that was created as the commit message,
   which leaves all of the understanding of that information in the hands of the
   user.



   
# Required Tools
- [Entr](https://eradman.com/entrproject/) - Runs arbitrary commands when files changes
- [fswatch](https://emcrisostomo.github.io/fswatch/) - Cross-platform filesystem change watcher
- [Rsync](https://rsync.samba.org/) - Synchronizes different directories

# Things to Figure Out
- How to create a disconnected branch
- How to create a commit and attach it to a branch that's not HEAD
- How to always create a commit, even if no files have changed (empty-commit?)

# How to Set Things Up

?? Create a script to do all of this?

1. Use git worktree with a bare repository?
2. Run a watcher script

Should also probably have some type of configuration file for the active sync processes?


# Notes

## Notes on fswatch

This will only match files that have this naming scheme, and ignore everything else.

``` sh
fswatch --event Created -e ".*" -i "wip-.*\\.png$"  ~/Downloads | xargs -I{} echo TEST: {}
```

## Notes on rsync

Need to be able to completely mirror a directory, based on a signal from the
directory watcher?

The `--exclude='.git/` will exclude the git repository data from the copy, since
that's not needed.

The `--filter=':- .gitignore'` flag will parse the contents of a `.gitignore`
file and exclude them from the transfer, avoiding things like copying the
node_modules directory, etc.

(This needs to be run from within the watcher folder.)

``` sh
rsync -a --verbose --exclude='.git/' --filter=':- .gitignore' ~/src/personal/generative/vera-examples/ .
```


## Notes on git worktrees

Should I use a bare repository? 

No - this comes with some unexpected issues regarding fetching (see [this blog
  bost](https://morgan.cugerone.com/blog/workarounds-to-git-worktree-using-bare-repository-and-cannot-fetch-remote-branches/)
  for details)
  
Maybe recommend a separate directory for all of the change tracking worktree
repositories?

This command will retrieve the parent directory of the `autocommit` directory,
assuming that the branch name is `autocommit`:

``` sh
git worktree list | tr -s " " | grep -v autocommit | cut -d " " -f 
```


Probably should create a specific branch for these commits (configurable?).
  
## Notes on git commit creation

Create a (possibly empty) commit on the current branch by automatically
committing all changes.

``` sh
git commit -a --allow-empty -m 'message'
```

# How to run this

Notice that the regular expression format is best handled by a single-quoted
string specification.

``` sh
~/src/personal/git-autocommit-bot/watch.sh -r 'wip-.*.png$' ~/Downloads
```
