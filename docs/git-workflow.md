# Git workflow

WraithVim combines three plugins with its own conflict resolver:

| Tool | Used for |
|---|---|
| gitsigns.nvim | signs in the gutter, hunk navigation, staging and reset, blame, branch name |
| vim-fugitive | status, commit, amend, push, pull, everything `:Git` can do |
| diffview.nvim | side-by-side diffs of all changes, repository and file history |
| WraithVim conflicts | three-way merge-conflict resolution on Git's index stages |

Every Git command WraithVim runs itself (stage/unstage file, conflict
handling) is started without a shell, with the file path as a separate
argument, so names with spaces, quotes or `$()` are safe.

## Everyday flow

| Step | Keys | Command |
|---|---|---|
| See what changed | `<leader>gs` | `:GitStatus` (fugitive) |
| Review all changes side by side | `<leader>gd`, close with `<leader>gD` | `:GitDiff` |
| Jump between hunks | `]h` / `[h` | |
| Preview a hunk | `<leader>gv` | |
| Stage / unstage a hunk | `<leader>gh` (normal or visual for selected lines) | |
| Reset a hunk | `<leader>gr` | |
| Stage / reset the whole buffer | `<leader>gS` / `<leader>gR` | |
| Stage / unstage the file | `<leader>ga` / `<leader>gu` | `:GitStage` / `:GitUnstage` |
| Commit | `<leader>gc` | `:GitCommit` |
| Amend | `<leader>gC` | `:GitAmend` |
| Push / pull | `<leader>gp` / `<leader>gP` | `:GitPush` / `:GitPull` |
| Switch branch | `<leader>gb`, or click the branch in the statusline | `:GitBranches` |
| History | `<leader>gl` (repository), `<leader>gf` (current file) | `:GitLog`, `:GitFileHistory` |
| Who changed this line | `<leader>gB` | |
| Changed files in the explorer | `<leader>eg` | |

In fugitive's status window: `s` stages, `u` unstages, `-` toggles, `=` shows
an inline diff, `cc` commits, `ca` amends, `dv` opens a vertical diff, `g?`
lists everything.

The branch shown in the statusline and tab header comes from gitsigns. It
watches `.git` through inotify events and does not poll. WraithVim never runs
`git status` on a timer.

## Merge conflicts

Diffview can show conflicts, but WraithVim ships its own resolver so the whole
cycle (inspect, choose, save, stage, verify) works the same way every time. It
reads Git's **index stages** directly:

| Stage | Pane | Meaning |
|---|---|---|
| 1 | BASE | the common ancestor |
| 2 | OURS | your side (`HEAD`) |
| 3 | THEIRS | the side being merged in |
| working tree | RESULT | the file on disk, which you edit |

During a **rebase**, Git's "ours" is the branch you are rebasing *onto* and
"theirs" is your commit. The panes are labelled `OURS (upstream)` and
`THEIRS (your commit)` to make that explicit.

### Step by step

1. **Find conflicts.** `<leader>gx` / `:Conflicts` fills the quickfix list
   with every conflicted file and its kind (both modified, deleted by them, …).
2. **Open the resolver.** `<leader>gm` / `:Conflict [file]` opens a new tab:

   ```text
   ┌──────────────┬──────────────┬──────────────┐
   │ OURS         │ BASE         │ THEIRS       │   read-only, from the index
   ├──────────────┴──────────────┴──────────────┤
   │ RESULT  path  (both modified, merge)       │   the working-tree file
   └────────────────────────────────────────────┘
   ```

   All panes with content are in diff mode, and the cursor starts on the first
   conflict. Without an argument the resolver uses the current file, or asks
   which file when there are several.
3. **Choose or combine**, for the conflict under the cursor in RESULT:

   | Keys | Takes |
   |---|---|
   | `<leader>co` | ours |
   | `<leader>ct` | theirs |
   | `<leader>cb` | both (ours, then theirs) |
   | `<leader>c0` | base |
   | `<leader>cn` | none (delete the block) |
   | `]x` / `[x` | jump to next / previous conflict |

   `:ConflictChoose theirs all` applies a choice to every conflict in the
   file. You can also edit RESULT freely, or press `dp` in a stage pane to put a
   diff hunk into RESULT. Every change is an ordinary buffer edit: `u` undoes
   it and nothing is written until you save.
4. **Whole-file choices.** `:ConflictChoose! ours` (or `theirs`/`base`)
   replaces RESULT with that complete version after a confirmation. If the
   chosen side **deleted** the file, WraithVim asks whether to delete it and
   stage the deletion (`git rm`). For binary files it offers
   `git checkout --ours/--theirs`.
5. **Save** with `:w` (or `<C-s>`).
6. **Mark resolved.** `<leader>cr` / `:ConflictResolve`:
   - asks to save if the buffer is modified;
   - reads the file from disk and, if conflict markers remain, asks before
     staging (the default answer is **No**);
   - runs `git add -- <file>` and verifies with `git ls-files -u` that the file
     is no longer unmerged;
   - closes the resolver tab and reports how many conflicted files remain,
     offering to open the next one.
7. **Finish** the merge with `<leader>gc` (or `git rebase --continue` /
   `git cherry-pick --continue` in the terminal).

### Unusual states

| Situation | What you see | How to resolve |
|---|---|---|
| Added on both sides (no stage 1) | BASE pane explains there is no common ancestor | edit RESULT as usual |
| Modified by us, deleted by them | THEIRS pane says the file was deleted | keep: edit and resolve; delete: `:ConflictChoose! theirs` |
| Deleted by us, modified by them | OURS pane says the file was deleted | `:ConflictChoose! ours` deletes; otherwise resolve RESULT |
| Deleted on both sides / file missing | a notification explains it | `:ConflictChoose!` with the side to keep, or `git rm` |
| Binary file | stage panes say "binary" | `:ConflictChoose! ours` / `theirs` |
| Unterminated or partial markers | not treated as a conflict region | edit by hand; staging still checks for markers |

WraithVim never overwrites the working-tree file without an explicit action:
whole-file replacement and deletion are always confirmed, and staging a file
that still contains markers is refused unless you confirm it.

`:ConflictClose` (`<leader>cq` in RESULT) closes the resolver tab without
staging anything.
