# AGENTS.md

This document guides coding agents working in this repository.
It is intentionally practical and command-focused for fast, safe edits.

## Repository Overview

- Project type: bootc image customization repo (Containerfile + shell scripts + Justfile).
- Primary build artifact: OCI image built from `Containerfile`.
- Key customization logic: `build_files/build.sh`.
- CI workflows: `.github/workflows/build.yml` and `.github/workflows/build-disk.yml`.
- There is currently no unit test framework in this repo.

## Source of Truth Files

- `Containerfile` for image composition and final container lint.
- `build_files/build.sh` for package installation and system customization.
- `Justfile` for local developer workflows (build, lint, format, VM image tasks).
- `.github/workflows/build.yml` for CI container build/push/sign behavior.
- `.github/workflows/build-disk.yml` for disk image build behavior.

## Build Commands

Use `just` recipes first; they encode project conventions.

- Show available tasks:
  - `just --list`
- Build container image locally (default image/tag from env):
  - `just build`
- Build container image with explicit image and tag:
  - `just build localhost/bazzite-nwg latest`
- Build VM disk image (qcow2):
  - `just build-qcow2`
- Build raw disk image:
  - `just build-raw`
- Build ISO disk image:
  - `just build-iso`
- Rebuild container + qcow2 in one flow:
  - `just rebuild-qcow2`

Notes:

- `just build` runs `podman build --pull=newer --tag <image>:<tag> .`.
- Build scripts may require rootful Podman for some VM/disk operations.
- Disk builds rely on Bootc Image Builder container (`BIB_IMAGE`).

## Lint / Format / Validation Commands

- Lint shell scripts (`*.sh`) with ShellCheck:
  - `just lint`
- Format shell scripts (`*.sh`) with shfmt:
  - `just format`
- Validate Justfile syntax recursively:
  - `just check`
- Auto-fix Justfile formatting recursively:
  - `just fix`
- Validate final built image in Dockerfile stage:
  - `bootc container lint` (already executed in `Containerfile` build stage)

## Test Commands

There is no dedicated test suite (no pytest/jest/go test/cargo test) configured.

Use this validation ladder instead:

1. `just check`
2. `just lint`
3. `just format` (if needed)
4. `just build`
5. Optional functional verification with VM image run:
   - `just build-qcow2`
   - `just run-vm-qcow2`

## Running a Single Test

No single-test runner exists because no unit/integration test harness is present.

Closest equivalents for targeted validation:

- Validate one shell script directly:
  - `shellcheck build_files/build.sh`
- Format-check one shell script directly:
  - `shfmt -d build_files/build.sh`
- Validate one Justfile only:
  - `just --unstable --fmt --check -f Justfile`

If you add a real test framework, update this section with exact single-test commands.

## CI Behavior You Must Preserve

From `.github/workflows/build.yml`:

- PRs build image but do not push/sign.
- Pushes to default branch build + push to GHCR + cosign sign.
- Metadata tags include `latest`, date-based tags, and PR/SHA tags where applicable.
- Build uses pinned actions and lowercase image naming in env prep.

From `.github/workflows/build-disk.yml`:

- Disk image workflow is `workflow_dispatch` and PR-triggered for specific path changes.
- Matrix builds `qcow2` and `anaconda-iso`.
- Supports optional upload to S3 via repo secrets.

Do not casually change workflow triggers, permissions, or signing logic.

## Code Style Guidelines

This repo is shell/Containerfile/Justfile heavy. Follow these conventions.

### Shell Scripts (`*.sh`)

- Shebang:
  - Prefer `#!/usr/bin/env bash` for portable scripts.
  - Existing file uses `#!/bin/bash`; keep consistency within touched file.
- Strict mode:
  - Use `set -euo pipefail` (or existing variant `set -ouex pipefail`).
- Quoting:
  - Quote variable expansions unless intentionally word-splitting.
  - Quote paths and URLs.
- Command safety:
  - Prefer explicit absolute binaries only where existing style does so.
  - Check command availability when required (`command -v ...`).
- Temporary files:
  - Use `mktemp` with predictable prefixes; clean up afterward.
- Error handling:
  - Fail fast on command errors.
  - For expected non-zero probes, temporarily relax strict mode (`set +e`) and restore.
- Logging:
  - Keep concise, action-oriented echo messages.
- Dependencies:
  - Build-time dependencies should be removed when no longer needed.

### Justfile

- Keep recipes small and composable.
- Prefer existing helper recipes (`sudoif`, `_build-bib`, `_rootful_load_image`) instead of duplicating logic.
- Maintain current naming pattern:
  - Public recipes: descriptive verb-noun (`build-qcow2`, `run-vm-iso`).
  - Internal recipes: prefixed with `_`.
- Preserve groups and aliases where relevant.

### Containerfile

- Keep multi-stage layout (`ctx` stage + final base image) unless intentional redesign.
- Place customization logic in `build_files/build.sh`, not inline in many `RUN` layers.
- Preserve cache mounts/tmpfs mounts pattern for build speed and cleanliness.
- Keep final `RUN bootc container lint` unless replacing with equivalent validation.

### Imports / Modules / Types

- This repository has no typed language modules (no TS/Python/Rust/Go source tree).
- "Imports" guidance applies to shell sourcing only:
  - Source only required files (example: `/etc/os-release`).
  - Avoid sourcing user-controlled files without validation.

### Naming Conventions

- Environment variables: `UPPER_SNAKE_CASE`.
- Shell local variables: `lower_snake_case` (or existing concise style in file).
- Just recipe names: kebab-case.
- File names:
  - Shell scripts: `.sh` suffix.
  - Configs: descriptive names under `disk_config/`.

### Formatting

- Use `shfmt` for shell scripts.
- Keep line length readable; break long command invocations with continuation lines.
- Align multi-line argument blocks for readability.
- Keep comments meaningful; avoid narrating obvious commands.

### Error Handling Expectations

- Validate assumptions before destructive operations (`rm -rf`, moving output dirs).
- In scripts that need root, use existing escalation helper patterns.
- For network downloads, prefer `curl -L` and verify selected artifact names/patterns.
- Clean up partial artifacts on failure when practical.

## Security and Secrets

- Never commit secrets (especially `cosign.key`).
- `cosign.pub` is safe to commit; private key is not.
- Do not hardcode credentials in scripts or workflow files.
- Keep GitHub Actions permissions minimal when editing workflows.

## Agent Workflow Checklist (Recommended)

Before editing:

- Read `Justfile`, `Containerfile`, and target script fully.
- Check CI workflows for assumptions impacted by your change.

While editing:

- Make minimal, scoped changes.
- Preserve existing behavior unless change request says otherwise.

Before finishing:

- Run `just check`.
- Run `just lint`.
- Run `just format` if shell changes were made.
- If build logic changed, run `just build`.

## Cursor/Copilot Rules

No Cursor rules were found:

- `.cursor/rules/` not present.
- `.cursorrules` not present.

No Copilot instructions file was found:

- `.github/copilot-instructions.md` not present.

If these files are added later, update this document and treat those rules as authoritative.

## Known Gaps / Maintenance Notes

- `build-disk.yml` references `./disk_config/iso.toml`, but repo currently has
  `disk_config/iso-kde.toml` and `disk_config/iso-gnome.toml`.
- Keep AGENTS.md in sync when adding new tooling, tests, or language code.
- If a test framework is introduced, add both full-suite and single-test commands.
