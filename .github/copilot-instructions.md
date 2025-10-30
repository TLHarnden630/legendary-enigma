<!--
  Generated: initial template because no discoverable project files were present in the workspace.
  Please update the "Concrete commands" and "Key files" sections with actual values from the repo.
-->
# Copilot / AI agent instructions — repository template

Purpose
- Quickly orient an AI coding agent so it can be productive in this repository.

How to start (first 60s)
- Scan for top-level language and build files: `package.json`, `pyproject.toml`, `requirements.txt`, `go.mod`, `Cargo.toml`, `pom.xml`, `Makefile`, `Dockerfile`, `README.md`.
- Look for source directories: `src/`, `cmd/`, `pkg/`, `internal/`, `lib/`, `app/`, `services/`, `tests/`.
- If none of the above are present, stop and ask the human: "I can't find build/test metadata (package.json, pyproject.toml, go.mod, etc.). Please supply the project's build and test commands or point me to the entrypoint files." 

Concrete commands (PLACEHOLDER — edit me)
- Node.js: if `package.json` exists run `npm ci` then `npm test` or `npm run build` if present.
- Python: if `pyproject.toml` or `requirements.txt` exists create venv, install, then run `pytest` if `tests/` present.
- Go: if `go.mod` exists run `go test ./...` and `go build ./...`.
- Docker: if `Dockerfile` present, build with `docker build -t <name> .`.

What to document here (project-specific — update this file)
- Entrypoints and service boundaries (e.g., `cmd/api/main.go`, `src/server/index.ts`, `app.py`).
- How to run the app locally, including env vars and sample .env values.
- Build, test and lint commands used by CI.
- Any special debugging steps (e.g., using `dlv` for Go, `inspect` flags for Node, running inside a specific container image).

Project patterns and conventions to look for
- Configuration: check `config/`, `configs/`, `env/`, or `*.env` files — these often contain required env var names.
- Services: `services/` or `internal/` typically hold domain services — treat them as stable boundaries.
- Migrations: look for `migrations/`, `alembic/`, or SQL files and note the database used in docs.
- Shared libraries: `pkg/` or `lib/` indicate internal packages that should not be published separately.

Integration points and dependencies
- Note any `Dockerfile`, `docker-compose.yml`, cloud infra (Terraform, Pulumi) or `ci/` or `.github/workflows` files — these reveal deployment and integration tests.
- If external APIs are called, record the client wrappers and any stubs/mocks under `test/` or `mocks/`.

Examples of useful repository-specific hints (replace these with repo facts)
- "The API server is implemented in `src/server/index.ts` and is started by `npm run start`; tests live in `test/` and use Jest."
- "Background workers live in `worker/` and are invoked by `scripts/run-worker.sh` — don't change scheduling without checking `infrastructure/cron.yaml`."

When to ask for help
- If build/test commands are missing or tests fail consistently, ask the maintainer for:
  - exact build/test commands
  - required environment variables and secrets (or test values)
  - key architectural docs or design decisions (location or a short summary)

Editing / merging guidance for humans
- If you update this file, prefer small, concrete entries: exact commands, file paths, and a 1–2 line summary of the architecture.
- Keep examples short and factual — AI agents will use these as authoritative instructions.

Contact the maintainers
- If present, the repository `README.md` or `MAINTAINERS` file usually contains owner contact info — consult them if uncertain.

Status: template created because no discoverable project files were found. Please revise.
