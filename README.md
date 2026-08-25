<p align="center">
  <img src="assets/aarp-logo-400.png" alt="AARP Logo" width="300">
</p>

<h1 align="center">AARP - Agentic Audit & Roadmap Pipeline</h1>

<p align="center">
  <b>A multi-tier agentic system for continuous auditing, vertical analysis, and guided evolution of Git repositories.</b>
</p>

AARP is a lightweight, shell-based orchestration framework for reviewing an
existing software repository with multiple AI agents. It maps the target
repository, runs focused audits, turns the findings into a prioritized
engineering roadmap, and optionally helps remediate the highest-priority
items progressively.

AARP is **not a web application** and does not provide a hosted dashboard. It
runs locally from its own checkout. A target repository can be reviewed from a
local checkout or cloned from Git without copying AARP's scripts or
`.openclaude/` directory into the target.

## What AARP does

The pipeline uses the `openclaude` command-line agent and OpenRouter as the
model provider. OpenRouter provides one endpoint through which the model can
be changed without rewriting the pipeline.

The current implementation combines an optional documentation phase with four
audit and remediation phases:

0. **Documentation Architect** — optionally reverse-engineers the target into
   human-readable architecture, administrator, user, and interface guides.
1. **Context mapping** — an architect agent examines the repository and
   creates `PROJECT_CONTEXT.md`, a technical blueprint for the other agents.
2. **Parallel deep audit** — three specialist agents review the repository
   independently:
   - UX, accessibility, and front-end performance;
   - application security using OWASP/CWE-oriented criteria;
   - database, storage, query performance, and resilience.
3. **Roadmap synthesis** — an engineering-director agent combines the
   context and audit findings into `ROADMAP.md`, grouped into P0, P1, and P2
   work.
4. **Human-approved roadmap remediation** — after a human reviews the roadmap,
   the operator may ask an agent to address the next unresolved item in
   priority order (P0, then P1, then P2) on an isolated task branch. Merging
   and pushing remain interactive choices.

The pipeline is deliberately human-in-the-loop: analysis may be automated,
but remediation is not allowed to bypass the operator's approval checkpoint.

## Repository layout

```text
.
├── .openclaude/
│   ├── prompts/       # Role instructions for mapping and specialist audits
│   └── templates/     # Report templates and roadmap structure
├── scripts/
│   ├── orchestrator.sh
│   ├── documentation_helpers.sh
│   ├── roadmap_helpers.sh
│   └── fix_regression.sh
├── reviews/            # Generated target checkouts, reports, and logs
├── GIT_AI_WORKFLOW.md # Branching and human-approval rules
└── README.md
```

The `.replit` file currently declares a Bash environment only. There is no
application server, package manifest, database, or frontend to install.
`reviews/` is generated only when an explicit target is selected and is
ignored by Git.

## Prerequisites

Before running AARP, install and configure:

- Bash;
- Git;
- the `openclaude` command-line tool;
- an OpenRouter account and the credentials required by the OpenClaude
  provider configuration.

Configure credentials through your local environment or the configuration
mechanism documented by OpenClaude. Do not commit API keys, tokens, or
provider configuration containing secrets to the target repository.

The scripts select models through optional environment variables:

```bash
export MODEL_GENERAL="thinkingmachines/inkling:free"
export MODEL_REASONING="cohere/north-mini-code:free"
export MODEL_DOCUMENTATION="google/gemini-2.5-flash"
```

If they are not set, the values above are used by `orchestrator.sh`. The
Documentation Architect defaults to `google/gemini-2.5-flash` because the
current OpenClaude configuration declares a large context window for it,
which is useful when documenting an entire repository. Override the variable
when a different supported model better matches the target's size or cost
requirements.

`fix_regression.sh` uses `cohere/north-mini-code:free` for reasoning by
default. Both scripts also configure conservative temperature, timeout,
retry, and telemetry-related settings internally.

The regression helper explicitly sets:

```bash
export OPENCLAUDE_PROVIDER="openrouter"
```

The main orchestrator expects OpenClaude to already be configured for the
chosen provider. Verify the provider setup in your environment before
starting a full audit.

## Recommended setup

Keep the AARP framework checkout separate from the repository being reviewed.
Do not copy `scripts/`, `.openclaude/`, or the other AARP files into the target
repository:

```text
/path/to/AARP/              # AARP framework checkout
/path/to/repository-under-review/  # Existing target checkout
```

This separation prevents framework files and audit artifacts from being
confused with the target's own source files. It also lets AARP inspect a
disposable snapshot during phases 1–3 and leaves the target untouched until
the human approval before phase 4.

If AARP was previously copied into the target repository, restore or reclone
the target as a clean checkout, keep AARP in its own directory, and use the
explicit `--target` command below.

## Using AARP with a target repository

Use `--target` to point AARP at a local Git checkout or a Git URL. The
orchestrator keeps its prompts, templates, and scripts in the AARP checkout,
and does not inject them into the target:

```bash
# Review an existing local checkout.
bash scripts/orchestrator.sh --target /path/to/repository-under-review

# Clone and review a GitHub repository.
bash scripts/orchestrator.sh \
  --target https://github.com/ORG/REPOSITORY.git
```

To run only the Documentation Architect and skip context mapping, audits,
roadmap synthesis, and remediation:

```bash
bash scripts/orchestrator.sh \
  --target /path/to/repository-under-review \
  --only-doc
```

For a URL target, AARP clones the repository into its review workspace. For a
local target, it leaves the original checkout where it is. For either target,
phases 1–3 inspect a disposable snapshot rather than the target checkout, and
generated reports and logs remain outside the target:

```text
reviews/<repository-name>-<stable-id>/
├── repository/              # Managed checkout, only for URL or bare-Git targets
├── source/                  # Disposable audit snapshot used by phases 1–3
├── reports/
│   ├── PROJECT_CONTEXT.md
│   ├── AUDIT_UX_UI.md
│   ├── AUDIT_SECURITY.md
│   ├── AUDIT_DB.md
│   ├── ROADMAP.md
│   └── documentation/       # Staged human-readable documentation bundle
└── logs/
    ├── audit_ux.log
    ├── audit_sec.log
    └── audit_db.log
```

The review directory is derived from the target name and a stable target
identity, so two local checkouts with the same folder name do not share
reports. Rerunning the same command resumes its existing snapshot and reports.
A Git source is reused only when the existing checkout has the same `origin`;
a mismatched checkout is rejected instead of being silently reviewed. Use
`--review-dir PATH` when a different predictable location is preferred:

```bash
bash scripts/orchestrator.sh \
  --target /path/to/repository-under-review \
  --review-dir /path/to/review-output
```

For local targets, `--review-dir` must remain outside the target checkout.
The review workspace records only a target identity key to prevent a custom
directory from being reused for a different target. To begin a fully fresh
review, choose a new review directory or remove the existing review workspace
after preserving any reports you need.

The no-argument command remains available for backwards compatibility:

```bash
bash scripts/orchestrator.sh
```

It reviews the repository containing the script and writes reports to that
repository's root, as older AARP checkouts expect. It does **not** use the
current working directory as an implicit target. Use the explicit
`--target` workflow for every other repository; this keeps AARP framework
files and review artifacts separate from the target. The pipeline itself does
not commit audit artifacts during phases 1–3.

The supported Git-source forms include HTTPS, SSH, SCP-style SSH
(`user@host:path/to/repository.git`), `git://`, `file://`, and a local bare
Git repository. A normal local target must be an existing Git checkout.

## Documentation Architect Agent

The **Documentation Architect Agent** (`documentation-architect`) produces
human-facing documentation that complements, rather than replaces,
`PROJECT_CONTEXT.md`. The context report is concise material for AI agents;
the documentation bundle is organized for developers, administrators, product
managers, and users.

At the start of an execution, AARP looks for `docs/`, `doc/`, or `documents/`
in the isolated target snapshot. If none exists, it asks before generating a
new documentation set. Declining leaves the target untouched. When the module
runs, it writes and validates the following staged files:

| File | Purpose |
| --- | --- |
| `ARCHITECTURE.md` | Components, dependencies, data/control flow, and external integrations |
| `ADMIN_GUIDE.md` | Prerequisites, configuration, environment, logging, operations, and recovery |
| `USER_GUIDE.md` | Getting started, common workflows, troubleshooting, and support boundaries |
| `API_REF.md` | Verified APIs or CLIs; explicitly records when no interface is present |

Every document separates verified evidence from inferences and information
that could not be verified. The checkpoint validation intentionally stays
minimal: it only requires every expected file to exist and be non-empty, so
content and residual template text do not cause unnecessary stops.

The agent writes only to
`reviews/<repository-name>-<stable-id>/reports/documentation/` (or the
equivalent report directory in legacy mode). After validation, the operator
may explicitly ask AARP to copy the bundle into an isolated
`docs/documentation-...` Git branch for review and push. The target repository
is never modified while the documentation is being analyzed or generated.

After an approved remediation merge in an explicit `--target` workflow, AARP
can regenerate this staging bundle from a fresh target snapshot and again
offer a separate documentation branch. The legacy in-place workflow keeps this
post-merge refresh manual because it has no isolated snapshot.

## Generated artifacts and resume behavior

When the corresponding report does not already exist in the review directory,
the orchestrator asks OpenClaude to create:

| File | Purpose |
| --- | --- |
| `PROJECT_CONTEXT.md` | Architectural and operational context for the target repository |
| `AUDIT_UX_UI.md` | UX, accessibility, responsive-layout, and front-end performance findings |
| `AUDIT_SECURITY.md` | Security findings with severity, CWE, risk, and remediation guidance |
| `AUDIT_DB.md` | Database and storage findings with resource impact and query/migration guidance |
| `ROADMAP.md` | Prioritized P0/P1/P2 remediation backlog and HITL status structure |
| `documentation/` | Staged Architecture, Administrator, User, and API reference documentation |

The orchestrator is stateful by convention: if one of these files already
exists, its phase skips that generation step. This allows an interrupted
run to be resumed, but it also means that stale reports are treated as
checkpoints. Remove or rename a report only after deciding that it should be
regenerated. The current checkpoint gate intentionally uses only a minimal
condition: the report must be a regular, non-empty file. Its content is not
semantically validated at this stage, so reports can vary freely between
repositories; stricter checks can be added later without changing the output
layout.

For an explicit target, parallel specialist output is redirected to:

```text
reviews/<repository-name>-<stable-id>/logs/audit_ux.log
reviews/<repository-name>-<stable-id>/logs/audit_sec.log
reviews/<repository-name>-<stable-id>/logs/audit_db.log
```

The reports are in the sibling `reports/` directory shown above. With the
backwards-compatible no-argument command, reports and logs continue to use
`PROJECT_CONTEXT.md`, the audit files, `ROADMAP.md`, and `logs/` in the AARP
repository root.

## Human-in-the-loop remediation

After `ROADMAP.md` is generated, the orchestrator pauses and asks whether the
operator authorizes phase 4. It prints the exact report path before prompting.
Answering anything other than `s` pauses the pipeline safely and allows it to
be resumed later.

When phase 4 is authorized:

- AARP displays the first unresolved task in priority order P0 → P1 → P2,
  including its priority, ID, available summary, and effort;
- the operator chooses explicitly between `s` (start), `skip` (leave the task
  open and continue with the next one in this run), and `exit` (pause without
  invoking OpenClaude); `skip` is temporary and the task is offered again on
  the next run;
- the agent is instructed to create the branch matching the priority:
  `fix/p0-<task-name>`, `feat/p1-<feature-name>`, or
  `refactor/p2-<task-name>`, then apply the requested change and commit it;
- before merging, the operator can push the task branch to the remote and
  deploy it independently for testing;
- after a successful merge, AARP marks the confirmed task as merged in
  `ROADMAP.md`; failed or declined merges leave the roadmap unchanged;
- if no unresolved P0, P1, or P2 task remains, phase 4 exits without invoking
  OpenClaude; if only skipped tasks remain, AARP reports them and a later run
  resumes from them;
- the operator can approve or decline an automatic merge;
- after the merge, the operator can separately approve or decline pushing
  `release/v2.0.0` to the remote;
- if the merge is declined after testing, the task branch remains available
  while the roadmap and release branch remain unchanged.

For explicit targets, phases 1–3 run without
`--dangerously-skip-permissions` against the review snapshot. After the
operator authorizes phase 4, the orchestrator switches to the actual target
checkout and starts the remediation agent with
`--dangerously-skip-permissions`. Use phase 4 only in a disposable or
appropriately controlled working copy, review all generated changes, and
never treat the agent as a substitute for code review or security testing.

Branch conventions are defined in
[`GIT_AI_WORKFLOW.md`](GIT_AI_WORKFLOW.md). That document describes a
`release/vX.Y.Z` integration branch and protected `main`; the current script
uses the concrete default `release/v2.0.0` when entering phase 4. Ensure the
branch exists and matches your release process before authorizing remediation.

## Regression recovery

Use `fix_regression.sh` after a test failure or runtime regression. It accepts
the error description as an argument or interactively through standard input:

```bash
bash scripts/fix_regression.sh "Describe the failing test or runtime error"
```

If no argument is supplied, the script reads the description until
end-of-file:

```bash
bash scripts/fix_regression.sh
```

The helper:

1. records the last three commits, including their patches, in
   `logs/recent_commits.patch`;
2. sends the error description and available context files to OpenClaude;
3. asks the agent to propose a short plan, apply a fix, and create a
   `fix(regression): ...` commit;
4. prints the resulting Git status.

Review the generated patch and commit before merging or pushing. The helper
also uses `--dangerously-skip-permissions` and can modify the working tree.

## Templates and prompts

The AARP repository contains role prompts in `.openclaude/prompts/` and
mandatory report templates in `.openclaude/templates/`. During phases 1–3, the
orchestrator passes the relevant role instructions and template to OpenClaude
while its working directory is the disposable audit snapshot for an explicit
target:

| Phase | Output | Template |
| --- | --- | --- |
| Context mapping | `PROJECT_CONTEXT.md` | `PROJECT_CONTEXT.template.md` |
| UX/UI audit | `AUDIT_UX_UI.md` | `AUDIT_UX_PERF.template.md` |
| Security audit | `AUDIT_SECURITY.md` | `AUDIT_APPSEC.template.md` |
| Database audit | `AUDIT_DB.md` | `AUDIT_DATABASE.template.md` |
| Roadmap synthesis | `ROADMAP.md` | `ROADMAP.template.md` |
| Documentation Architect | `documentation/*.md` | `DOCUMENTATION_ARCHITECT.template.md` |

Each prompt instructs the agent to preserve the attached template structure,
replace placeholders with repository-specific evidence, and avoid leaving
template instructions in the final report. The orchestrator validates that all
required templates are present before starting the pipeline.

The output filenames intentionally use clear report names while the template
filenames identify their domain. The AppSec template therefore produces the
`AUDIT_SECURITY.md` report, and the UX/performance template produces
`AUDIT_UX_UI.md`.

## Current limitations

The current repository is an intentionally small foundation. In particular:

- `fix_regression.sh` still follows the legacy in-place workflow and is not
  target-aware;
- there is no web interface, API, job queue, persistent run database, or
  hosted execution service;
- the main orchestrator assumes that OpenClaude is installed and configured;
- the orchestrator and regression helper contain model/provider defaults that
  may need to be adjusted for the available OpenRouter models;
- generated reports are checkpoint files in the review directory, not
  versioned run records;
- the current resume mechanism uses file existence and does not validate
  report freshness or schema;
- phase 4 processes the P0/P1/P2 roadmap progressively, and its
  branch/release assumptions require alignment with the target repository;
- no claim is made that an AI-generated audit is complete, correct, or a
  replacement for human security, performance, or architecture review.

## Related files

- [`scripts/orchestrator.sh`](scripts/orchestrator.sh) — four-phase pipeline
  and interactive roadmap remediation loop
- [`scripts/documentation_helpers.sh`](scripts/documentation_helpers.sh) —
  documentation source detection and bundle validation
- [`scripts/roadmap_helpers.sh`](scripts/roadmap_helpers.sh) — roadmap task
  selection, priority-to-branch mapping, and status updates
- [`scripts/fix_regression.sh`](scripts/fix_regression.sh) — regression
  analysis and agent-assisted fix helper
- [`GIT_AI_WORKFLOW.md`](GIT_AI_WORKFLOW.md) — Git isolation and HITL rules
- [`.openclaude/prompts/`](.openclaude/prompts/) — agent role instructions
- [`.openclaude/templates/`](.openclaude/templates/) — reference report
  structures
- [`.openclaude/system.md`](.openclaude/system.md) — OpenClaude operating
  constraints

## License

AARP is released under the [MIT License](LICENSE).
