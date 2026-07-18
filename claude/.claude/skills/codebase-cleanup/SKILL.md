---
name: codebase-cleanup
description: Use when auditing or cleaning a codebase for dead code, cruft, scope creep, or architectural drift — especially organically grown or vibe-coded projects. Not for greenfield projects, single-file or single-function tidying, security audits, single bug fixes, or performance work. Triggers on requests like "clean up this repo", "find dead code", "audit this codebase for cruft".
---

# Codebase Cleanup

Ask **"should this exist?"** before "how can I improve this?" — the core failure mode in cleanup is refactoring code that should be deleted, or adding abstractions to an already over-abstracted mess. Removal over refactoring; simplification over restructuring; verify after every change.

## Step 1: Understand project intent

Before touching code, learn what the project is *supposed* to be. Read in order: README/CLAUDE.md → design docs → recent git log → dependency manifest. The gap between stated intent and actual code is your removal-candidate list: features present in code but absent from docs deserve the "should this exist?" question first.

## Step 2: Establish the baseline (once)

Run every standard check the project has and **record the numbers**: linter (warning count), tests (pass/fail/skipped counts), build (warnings, output size). This baseline serves two purposes — it is the health snapshot you diff against after every change, and its failures are themselves findings (linter warnings nobody fixed reveal patterns the team stopped caring about; skipped tests are false confidence).

**If the build or tests are broken now, that is finding #1. Fix or flag it before any cleanup — never stack cleanup on a broken baseline.**

## Step 3: Scan

Scan by pattern across the whole codebase; never go file-by-file. Count everything — "23 TODOs, 4 unused files" is actionable, "lots of dead code" is not.

### Prefer dedicated dead-code tools over grep

grep alone produces false results on dynamic imports, string-based references, re-exports, reflection, and template usage. Use a real analyzer when the ecosystem has one, and treat grep as the fallback, not the method:

| Stack | Tools |
|---|---|
| JS/TS | `knip` (unused files/exports/deps; supersedes ts-prune and covers depcheck's job) |
| Python | `ruff` (unused imports/vars), `vulture` (dead functions/classes) |
| Go | `deadcode` (golang.org/x/tools), `staticcheck` (U1000) |
| Rust | compiler `dead_code` warnings (note: misses unused `pub` items in lib crates), `cargo-machete` or `cargo-udeps` (more thorough; needs nightly) for unused deps |
| Static sites / CSS | list assets on disk, then grep content for each basename — unreferenced = orphan candidate; `purgecss` for unused CSS rules (false-positives on dynamically constructed class names — the evidence rule below applies to its output too) |

**Evidence rule:** a grep-only "no usages found" makes something a *candidate*, not a confirmed delete. Before putting anything in T1, confirm by a second independent method: a dedicated tool, a call-path trace from entry points, or an explicit search for dynamic/string-based references (`import(`, `getattr`, `require(variable)`, config/CI/docs mentions).

### What to scan for

- **Dead code:** unused imports/exports, functions defined but never called, files nothing imports, orphaned assets, commented-out blocks, alternate implementations (`app_v2.js`, `layout_old.html`), "coming soon" placeholders, stale feature flags
- **Quality:** swallowed errors (empty `catch {}`, `except: pass`, `.unwrap()` outside tests), TODO/FIXME/HACK, duplicated logic, very long functions/files (~100 lines / ~500 lines as rough heuristics — calibrate to the repo's norms, not as hard rules)
- **Scope creep:** features unrelated to stated purpose, modules that could be separate projects, dependencies pulled in for one non-core feature
- **Config/meta staleness:** linter rules disabled project-wide, CI steps skipped or `allow_failure`, configs for tools no longer used, `.gitignore`/editor configs that don't match reality
- **Tests:** always-pass tests, coverage-chasing tests that assert nothing behavioral, `test1`/`test2` naming

### Scaling the scan

Pick the execution mode by repo size and session mode. In every mode, scan and verify agents are read-only and return structured summaries only (counts + candidate lists, never raw file dumps); deletions are always executed in the main session, after the Step 5 owner checkpoint.

- **Small repo** (scans finish in seconds — a blog, a dotfiles repo, <~10k LOC): run everything in the main session.
- **Large repo** (tens of kLOC+, or many scan dimensions): fan the scan dimensions out to parallel read-only subagents (Explore/general-purpose), one per dimension above.
- **Ultracode / Workflow mode** — only when BOTH hold: (1) the Workflow tool is available in the current session, and (2) ultracode is on or the user explicitly asked for Workflow/multi-agent execution. Repo size alone never selects this mode. If the Workflow tool is absent, use the subagent fan-out above — do not emulate Workflow with other mechanisms.

  Structure — parallel per-dimension pipelines, so each dimension's verification starts as soon as its own scan returns:
  1. **Scanner** (one per dimension): returns `{findings: [{file, kind, evidence, tier_guess}]}` via `schema`.
  2. **Verifier** (one per dimension, receives its scanner's T1 candidate list): prompted to *refute* each candidate's deadness — hunt for dynamic imports, string references, template/config/CI/docs usage, reflection.

  Only use the barriered alternative (all scanners → dedup → verifiers) if you need cross-dimension dedup before verifying, at the cost of waiting for the slowest scanner.

  Route each verifier outcome three ways:
  - **Refuted with concrete evidence** → drop from T1; record the found reference as the reason.
  - **Inconclusive** → "needs human review".
  - **Survived refutation** → propose as T1 delete.

## Step 4: Question existence, then classify

For every major feature/module ask, in order: Does it align with stated purpose? Is it actually used (trace from entry points)? Could it be a separate project? Was it ever finished? Only after "yes, this should exist" does "how can it improve?" become a valid question.

Classify every finding:

| Tier | What | Effort |
|---|---|---|
| **T1** | Safe deletes: dead code, unused files, orphaned assets | Minutes |
| **T2** | Isolated fixes: error handling, stale TODOs, linter warnings | Hours |
| **T3** | Focused refactors: extract god object, consolidate duplication | Days |
| **T4** | Architectural changes across modules | Weeks |

## Step 5: Owner checkpoint

**Present findings before changing anything.** Group by tier, lead with the T1 list ("N things I can safely delete now — proceed?"), ask which questionable features they value, and which T3/T4 directions matter to them. Never assume — a "questionable" feature may be their favorite part. T3/T4 work only starts on explicit request.

## Step 6: Execute safe-to-dangerous

Strict order T1 → T2 → T3 → T4 (T4 on its own branch). This prevents spending a week refactoring a module that should have been deleted in five minutes.

After **each** change, not at the end: build + tests pass, no new warnings vs. the Step 2 baseline, commit the working state. If broken: revert, then investigate.

## Red flags — you're doing cleanup wrong

- You're writing more code than you're deleting, or creating new files
- You suggested an "event bus" / "registry pattern" / new abstraction during a dead-code pass
- Your plan has 5+ phases spanning weeks instead of starting with T1 and reassessing
- You flagged something dead on grep evidence alone
- You haven't asked the owner what they want to keep
- You're making change #2 before verifying change #1
