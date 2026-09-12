# Documentation Architect — Output Contract

Analyze only the repository snapshot supplied by the orchestrator. Write the
five files below in the exact staging directory supplied at runtime. Write
facts verified from the repository, clearly label reasonable inferences, and
state when information cannot be verified. Do not invent product behavior,
configuration, APIs, or operations.

Create every listed file, even when a topic is absent from the repository.
For example, `API_REF.md` must state that no API or CLI was verified when that
is the case.

## FILE OUTPUT: OVERVIEW.md

```markdown
# Project Overview

## What this project is
One compact, human-readable summary of the verified purpose, audience, and
business value of the project. A reader should understand the project in under
two minutes.

## How it works
High-level description of the main flow: entry points, core components, and
how data or requests move through the system.

## Where to read next
Pointers to ARCHITECTURE.md, ADMIN_GUIDE.md, USER_GUIDE.md, and API_REF.md
with one line each about what they cover.

## Evidence classification
### Verified
### Inferred
### Not verifiable
```

## FILE OUTPUT: ARCHITECTURE.md

```markdown
# Architecture

## System overview
Describe the verified purpose, major components, dependencies, data flow, and
external integrations. Include notable constraints and unresolved questions.

## Evidence classification
### Verified
### Inferred
### Not verifiable
```

## FILE OUTPUT: ADMIN_GUIDE.md

```markdown
# Administrator Guide

## Setup and prerequisites
Document verified runtimes, dependencies, configuration, environment variables,
deployment or start procedures, logs, health checks, operations, recovery, and
security considerations.

## Evidence classification
### Verified
### Inferred
### Not verifiable
```

## FILE OUTPUT: USER_GUIDE.md

```markdown
# User Guide

## Getting started
Document verified user-facing workflows, common actions, prerequisites,
troubleshooting, limitations, and support boundaries.

## Evidence classification
### Verified
### Inferred
### Not verifiable
```

## FILE OUTPUT: API_REF.md

```markdown
# API Reference

## Interfaces
Document verified HTTP APIs, CLI commands, events, or other public interfaces,
including authentication, parameters, responses, errors, examples, and
compatibility notes. If none exists, state that plainly.

## Evidence classification
### Verified
### Inferred
### Not verifiable
```