---
name: dotfiles-health
description: Audit the health of this dotfiles repo — stow sync drift, secret leakage, dead config, plugin/tool freshness, and shell startup time. Run periodically (e.g. monthly) or after larger config changes. Investigates via parallel subagents, then fixes safe issues and reports the rest.
---

# Dotfiles health check

Audit this GNU Stow-based dotfiles repo (`~/dev/dotfiles`, target `$HOME`) against the six health dimensions below. Delegate investigation to parallel read-only subagents, synthesize, then fix.

## Health definition (six dimensions)

1. **Sync completeness (drift)**
   - Every file in each stow package must be reachable from `$HOME` via symlink (directory folding counts: a parent dir symlinked into the repo covers its contents).
   - No plain files sitting in `$HOME` where a symlink should be; no `*.bak` remnants from `stow --adopt`.
   - Reverse check: configs in `$HOME`/`~/.config` worth managing but not in the repo (skip caches, history, state, credentials). Known intentional locals: `~/.config/git/config.local`, `~/.ssh/config.local`, `$ZDOTDIR/.zshrc.local`, `~/.config/gh/hosts.yml`.
   - `git status` must be clean; uncommitted changes are drift (config TUIs like ccstatusline write through the symlink into the repo — commit those).

2. **Local/secret separation**
   - `git grep` tracked files for tokens (`ghp_`, `sk-`, `AKIA`, `xox`, private keys), real email addresses, hostnames/IPs. The GitHub noreply email in `git/config` is intentionally public.
   - Verify the `.local` include mechanisms still exist (git `include.path`, ssh `Include`, zsh hook at end of `.zshrc`) and `install.sh` still generates the templates.
   - Spot-check git history with `git log --all --diff-filter=A --name-only` and a few `git log -S` patterns.

3. **Dead / vestigial config**
   - zsh files: PATH entries to nonexistent dirs, init code for uninstalled commands **without** `(( $+commands[...] ))` / OS guards, duplicate exports, duplicate PATH entries (`echo $PATH | tr ':' '\n' | sort | uniq -d` in a clean login shell).
   - macOS-only config is fine if OS-gated (this repo is shared with macOS); flag only unguarded breakage.
   - `install.sh` package arrays vs actual repo dirs; tools referenced by config but installed by neither the Linux path nor the Brewfile.
   - Load-order invariants: compinit before fzf-tab; fzf-tab before autosuggestions/syntax-highlighting (see sheldon `plugins.toml` defer ordering).

4. **Freshness**
   - `sheldon lock --update` candidates: compare each clone under `~/.local/share/sheldon/repos` against upstream (`git fetch` + rev-list count). Some upstreams are legitimately dormant (zsh-defer, tmux-sensible) — behind-count matters, not age.
   - tmux plugins: `~/.config/tmux/plugins/tpm/bin/update_plugins all`.
   - Self-updating tools: `uv self update`, `deno upgrade`, `pnpm self-update`, `bun upgrade`.
   - Pinned versions inside `install.sh` (e.g. the nvm install URL) vs latest release.
   - apt-managed tools (fzf, zoxide, bat, tmux) lag badly on Ubuntu — **report only, do not replace**; swapping to manual binaries is a user decision.

5. **Shell startup time**
   - Benchmark `zsh -i -c exit` ×10. **Must run in a clean environment** (`env -i HOME=$HOME TERM=xterm zsh -i -c exit` or from a fresh login shell): the inherited tool-shell environment carries `ZDOTDIR`/`skip_global_compinit` state that skews results by >100ms.
   - Targets: <100ms excellent (currently ~17ms), <300ms good, >700ms investigate.
   - If regressed: profile with zprof via a throwaway `ZDOTDIR` (never edit the real `.zshrc` for measurement). Known past sinks: Ubuntu's global compinit in `/etc/zsh/zshrc` (opted out via `skip_global_compinit=1` in `.zshenv`), eager `nvm.sh` (now a lazy stub), per-start completion generation for uv/uvx/deno (now cached under `$XDG_CACHE_HOME/zsh/completions`, regenerated when the binary is newer).

6. **Installer integrity**
   - `bash -n install.sh`; package arrays match repo dirs; every command install.sh invokes (e.g. `wget`) is in its own apt list; idempotency guards (`has`) on each install block; Brewfile covers what zsh config assumes on macOS.

## Procedure

1. Launch parallel **read-only** investigation subagents, one per dimension (1–4 and 6 can each be one agent; 5 needs Bash for benchmarking but must not persist changes — temp files go to the scratchpad, use throwaway `ZDOTDIR`). Tell every investigator explicitly: change nothing, report findings with file:line, separate "definitely broken" from "user judgment needed".
2. Synthesize findings and **present them to the user before changing anything** — even "obviously safe" fixes. Config choices often encode intent that isn't visible in the file (e.g. bun installed via official script on purpose, tools deliberately not in the installer). Propose a fix list, get approval, then apply. Classify proposals:
   - **Fix candidates** (after approval, via fix subagents): drift commits, `.bak` removal after diffing, dead-code removal, guards, plugin updates, install.sh pin bumps.
   - **Report only**: apt tool replacement, moving packages between OS lists, anything touching auth/credentials, judgment calls (alias duplicates, package restructuring).
3. Fix subagents must not overlap on files (zsh/sheldon/install.sh = one agent; keep `sheldon lock --update` sequenced *after* any plugins.toml edit) and must not commit — commit from the top level in logical chunks after verification.
4. Verify after fixes: `zsh -n` on all zsh files, `zsh -i -c exit` with empty stderr on a pty, clean-env startup benchmark, `sheldon lock` succeeds, `stow -v` dry-run shows no conflicts, `git status` clean after commits.
5. Report per dimension: pass/fail, what was fixed, what needs the user's decision.

## Repo-specific gotchas

- `stow` folding: `~/.config/git`, `~/.ssh`, `~/.config/tmux`, `~/.claude`, `~/.config/gh` are real dirs with intentional unmanaged cohabitants (locals, plugins, credentials) — per-file symlinks there are correct, not drift.
- `claude` and `gh` are stow packages holding only the shareable subset (`~/.claude/settings.json`; `gh/config.yml`). Never pull `hosts.yml`, `.credentials.json`, or anything credential-shaped into the repo.
- The pty-less `can't change option: zle` warning from `zsh -i` is a tty artifact, not a config error.
- cmux/karabiner are macOS-only and correctly absent on Linux.
