# Development Workflow Guide

This guide walks you through building a standards-compliant protocol implementation step by step, using the template's AI agents and slash commands in VS Code Copilot Chat.

---

## Prerequisites

1. Project initialized with `bash init-standard-project.sh`
2. VS Code with GitHub Copilot Chat extension installed
3. The generated `01-stakeholder-requirements/standard-discovery.md` reviewed

---

## Workflow Overview

```
Step 0: Initialize Project         bash init-standard-project.sh
                │
Step 1: Project Kickoff            /project-kickoff
                │
Step 2: Elicit Requirements        /requirements-elicit
                │
Step 3: Validate Requirements      /requirements-validate
                │
Step 4: Architecture Design        /architecture-starter
                │
Step 5: Phase Gate 03→04           /phase-gate-check → /phase-transition_3to4
                │
Step 6: Detailed Design            /phase-transition_4to5
                │
Step 7: TDD Red Phase              /tdd-compile
                │
Step 8: Build & Lint               /compile → /lint
                │
Step 9: Traceability               /traceability-builder
                │
Step 10: Verification              /test-validate
```

---

## Step 0: Initialize Project

```bash
# Copy the template
cp -r IEEE_DEV_TDD_TEMPLATE/ my-project/
cd my-project/

# Run the interactive wizard
bash init-standard-project.sh
```

The wizard will ask about your standard, technical stack, and project details. See [TEMPLATE_USAGE.md](../TEMPLATE_USAGE.md) for the full reference.

**Non-interactive example** (IEEE 802.1X-2020):

```bash
export STANDARD_ORG="IEEE"
export STANDARD_NUMBER="802.1X"
export STANDARD_YEAR="2020"
export STANDARD_NAME="IEEE 802.1X-2020"
export STANDARD_SHORT="802.1X"
export STANDARD_DESCRIPTION="Port-based network access control"
export PROTOCOL_LAYER="Network"
export KEY_PROTOCOL_FEATURES="EAP state machine, EAPOL frames, PAE, authenticator, supplicant"
export PRIMARY_LANGUAGE="C++"
export LANGUAGE_STANDARD="17"
export TEST_FRAMEWORK="GoogleTest"
export BUILD_SYSTEM="CMake"
export TARGET_PLATFORMS="cross-platform"
export ORG_NAME="myorg"
export REPO_NAME="IEEE_802_1X_2020"
export CODEOWNER="myorg"
export LICENSE_TYPE="MIT"

bash init-standard-project.sh --defaults
```

---

## Step 1: Project Kickoff (Phase 01)

Open VS Code Copilot Chat and run:

```
/project-kickoff
```

### Example Prompt

> I'm implementing IEEE 802.1X-2020, a port-based network access control protocol.
> The standard defines how network devices authenticate before granting access.
> Key stakeholders are network equipment manufacturers, enterprise IT departments,
> and security teams. The core features are the EAP state machine, EAPOL frame
> handling, Port Access Entity (PAE), and authenticator/supplicant roles.

### What Copilot Does

1. Runs a structured brainstorming session (divergent → convergent)
2. Creates a Stakeholder Requirements Specification
3. Identifies key stakeholders and their concerns
4. Produces a project charter with success criteria

### Output Location

- `01-stakeholder-requirements/` — Stakeholder requirements documents

---

## Step 2: Elicit Requirements (Phase 02)

```
/requirements-elicit
```

### Example Prompt

> Define the functional requirements for the EAP state machine in IEEE 802.1X-2020.
> The authenticator PAE must support the following EAP methods per the specification.
> Key sections: Section 8.1 (EAPOL), Section 12.4 (PAE state machines).

### What Copilot Does

1. Asks clarifying questions across 8 dimensions (functional, non-functional, etc.)
2. Generates GitHub Issue bodies in the correct template format
3. Creates requirement specifications with acceptance criteria

### Follow-up Commands

```
/requirements-refine     # Refine ambiguous requirements
/requirements-complete   # Check for completeness
/user-story-expansion    # Expand requirements into user stories
```

### Output Location

- `02-requirements/functional/` — Functional requirements
- `02-requirements/non-functional/` — Quality attributes
- `02-requirements/user-stories/` — User stories with acceptance criteria

---

## Step 3: Validate Requirements

```
/requirements-validate
```

### Example Prompt

> Validate the requirements in 02-requirements/ against IEEE 802.1X-2020.
> Check for completeness, consistency, testability, and traceability.

### What Copilot Does

1. Checks each requirement for SMART properties
2. Validates acceptance criteria are testable
3. Identifies missing non-functional requirements
4. Produces a validation report

---

## Step 4: Architecture Design (Phase 03)

```
/architecture-starter
```

### Example Prompt

> Design the component architecture for IEEE 802.1X-2020 implementation.
> The system needs: EAP state machine, EAPOL frame parser/builder,
> PAE (authenticator and supplicant), and a hardware abstraction layer.
> Must be hardware-agnostic with dependency injection.

### What Copilot Does

1. Creates architecture views (context, component, deployment)
2. Generates Architecture Decision Records (ADRs)
3. Defines component boundaries and interfaces
4. Produces architecture specification documents

### Follow-up Commands

```
/standards-validate      # Validate against IEEE/ISO standards
/sfmea-create           # Software Failure Mode Effects Analysis
```

### Output Location

- `03-architecture/views/` — Architecture viewpoints
- `03-architecture/decisions/` — ADRs
- `03-architecture/components/` — Component specifications

---

## Step 5: Phase Gate Check (Phase 03 → 04)

Before moving to detailed design, verify all Phase 03 exit criteria are met:

```
/phase-gate-check
```

### Example Prompt

> Check phase gate criteria for Phase 03 (Architecture) completion.
> Verify all architecture decisions are documented, components defined,
> and requirements traced to architectural elements.

If the gate passes:

```
/phase-transition_3to4
```

---

## Step 6: Detailed Design (Phase 04 → 05)

```
/phase-transition_4to5
```

### Example Prompt

> Transition from design to implementation for the EAP state machine component.
> The state machine has states: INITIALIZE, DISABLED, IDLE, RECEIVED,
> INTEGRITY_CHECK, METHOD_REQUEST, METHOD_RESPONSE, SUCCESS, FAILURE.

---

## Step 7: TDD Red Phase (Phase 05)

This is where protocol implementation begins. Always write a failing test first.

```
/tdd-compile
```

### Example Prompt

> Write a failing test for EAP state machine initialization.
> The state machine should start in INITIALIZE state, accept a
> network interface via dependency injection, and transition to
> IDLE state after initialization completes.
> Reference: IEEE 802.1X-2020 Section 12.4.

### What the TDD Agent Does

1. Creates a test file with a failing test (Red)
2. Implements minimum code to pass (Green)
3. Suggests refactoring opportunities (Refactor)
4. Ensures >80% code coverage

### Follow-up Commands

```
/compile              # Verify the code compiles
/lint                 # Run static analysis
/test-validate        # Validate test quality
/test-gap-filler      # Find and fill test coverage gaps
```

---

## Step 8: Build & Validate

```
/compile
```

### Example Prompt

> Build the project and verify all tests pass.

For C/C++ projects:
```bash
cmake -S . -B build && cmake --build build && ctest --test-dir build
```

For Python projects:
```bash
pip install -e '.[dev]' && pytest -v
```

For Rust projects:
```bash
cargo build && cargo test
```

```
/lint
```

### Example Prompt

> Run static analysis on the implementation code.
> Check for IEEE 802.1X protocol compliance issues.

---

## Step 9: Traceability

```
/traceability-builder
```

### Example Prompt

> Build the traceability matrix linking requirements to tests and code.
> Verify all requirements in 02-requirements/ have corresponding tests.

### Follow-up

```
/traceability-validate   # Validate completeness of traceability
/code-to-requirements    # Reverse-engineer requirements from code
```

---

## Step 10: Verification & Validation (Phase 07)

```
/test-validate
```

### Example Prompt

> Validate the test suite against the requirements.
> Verify acceptance criteria from user stories are covered.

### Follow-up Commands

```
/acceptance-test-generate   # Generate acceptance tests from user stories
/reliability-test-design    # Design reliability tests
/reliability-plan-create    # Create reliability program plan
/operational-profile-create # Create operational profile
```

---

## Complete Slash Command Reference

### Phase 01: Stakeholder Requirements

| Command | Purpose |
|---------|---------|
| `/project-kickoff` | Structured brainstorming and project charter |
| `/requirements-elicit` | Elicit requirements through structured questioning |

### Phase 02: Requirements

| Command | Purpose |
|---------|---------|
| `/requirements-elicit` | Elicit new requirements |
| `/requirements-refine` | Refine ambiguous requirements |
| `/requirements-complete` | Check requirements completeness |
| `/requirements-validate` | Validate requirements quality |
| `/user-story-expansion` | Expand requirements into user stories |
| `/standards-validate` | Validate against IEEE/ISO standards |

### Phase 03: Architecture

| Command | Purpose |
|---------|---------|
| `/architecture-starter` | Create architecture views and ADRs |
| `/sfmea-create` | Software Failure Mode Effects Analysis |
| `/phase-gate-check` | Verify phase exit criteria |
| `/phase-transition_3to4` | Transition from architecture to design |

### Phase 04-05: Design & Implementation

| Command | Purpose |
|---------|---------|
| `/phase-transition_4to5` | Transition from design to implementation |
| `/tdd-compile` | TDD Red-Green-Refactor cycle |
| `/compile` | Build and verify compilation |
| `/lint` | Run static analysis |

### Phase 06-07: Integration & Verification

| Command | Purpose |
|---------|---------|
| `/test-validate` | Validate test suite quality |
| `/test-gap-filler` | Find and fill test coverage gaps |
| `/acceptance-test-generate` | Generate acceptance tests |
| `/traceability-builder` | Build traceability matrix |
| `/traceability-validate` | Validate traceability completeness |
| `/code-to-requirements` | Reverse-engineer requirements from code |

### Reliability & Quality

| Command | Purpose |
|---------|---------|
| `/reliability-plan-create` | Create reliability program plan |
| `/reliability-test-design` | Design reliability tests |
| `/reliability-release-decision` | Release readiness decision |
| `/operational-profile-create` | Create operational profile |
| `/srg-model-fit` | Software Reliability Growth model fitting |

### Cross-Cutting

| Command | Purpose |
|---------|---------|
| `/repository-audit` | Full repository health audit |
| `/corrective-action-loop` | Systematic issue resolution |

---

## AI Agents

The template includes 6 specialized agents accessible via `@agent-name` in Copilot Chat:

| Agent | Purpose |
|-------|---------|
| `@TDDDriver` | Red-Green-Refactor TDD execution |
| `@RequirementsAnalyst` | Requirements engineering |
| `@ArchitectureStrategist` | Architecture decisions and views |
| `@TestingSpecialist` | Test quality and coverage |
| `@DocumentationExpert` | Documentation generation |
| `@SecurityAnalyst` | Security analysis and compliance |

### Example Agent Usage

```
@TDDDriver Write a failing test for EAPOL frame parsing per IEEE 802.1X-2020 Section 11.3
```

```
@RequirementsAnalyst Analyze Section 8.1 of IEEE 802.1X-2020 and extract functional requirements
```

```
@ArchitectureStrategist Design the PAE component with authenticator and supplicant roles
```

---

## Tips

1. **Always start with a failing test** — The TDD cycle is: Red → Green → Refactor
2. **Reference the standard** — Include section numbers in prompts for better AI context
3. **Use the discovery document** — `01-stakeholder-requirements/standard-discovery.md` feeds into AI agents
4. **Check traceability regularly** — Run `/traceability-validate` after each feature
5. **Phase gates matter** — Don't skip `/phase-gate-check` between phases
6. **Small commits** — Each commit should compile and pass all tests
