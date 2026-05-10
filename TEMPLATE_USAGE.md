# Template Usage Guide

## What Is This Template?

**IEEE_DEV_TDD_TEMPLATE** is a reusable project template for building **standards-compliant protocol implementations** using IEEE/ISO/IEC software engineering practices. It provides:

- **9-phase ISO/IEEE lifecycle** directory structure (ISO/IEC/IEEE 12207:2017)
- **7 AI agents** for VS Code Copilot Chat (TDD, Requirements, Architecture, Testing, Documentation, Security)
- **42+ prompt files** for guided development workflows
- **Spec-kit templates** for requirements, architecture, and reliability documentation
- **CI/CD pipelines** (GitHub Actions) with standards compliance validation
- **Traceability tooling** linking requirements → design → code → tests
- **TDD infrastructure** with CMake + Google Test

## Who Is It For?

- Teams implementing **IEEE, ISO, IEC, ITU, AVnu, or AES standards** in C/C++
- Projects requiring **standards traceability** and **conformance testing**
- Developers wanting **AI-assisted, test-driven** protocol development

## Quick Start

### 1. Copy the Template

```bash
cp -r IEEE_DEV_TDD_TEMPLATE/ my-new-project/
cd my-new-project/
```

### 2. Run the Initializer

```bash
bash init-standard-project.sh
```

The interactive wizard will ask for:

| Placeholder | Description | Example |
|-------------|-------------|---------|
| `STANDARD_ORG` | Standards body | `IEEE` |
| `STANDARD_NUMBER` | Standard number | `802.1X` |
| `STANDARD_YEAR` | Publication year | `2020` |
| `STANDARD_NAME` | Full name | `IEEE 802.1X-2020` |
| `STANDARD_SHORT` | Short identifier | `802.1X` |
| `PROJECT_NAME` | CMake/folder name | `IEEE_802_1X_2020` |
| `PROJECT_LIB_NAME` | Library target | `ieee_802_1x_2020` |
| `PROJECT_NAMESPACE` | C++ namespace | `IEEE::_802_1::X::_2020` |
| `ORG_NAME` | GitHub org/user | `myorg` |
| `REPO_NAME` | GitHub repo | `IEEE_802_1X_2020` |
| `CODEOWNER` | Default reviewer | `myorg` |
| `LICENSE_TYPE` | License | `MIT` |

### 3. Verify

```bash
cmake -S . -B build && cmake --build build
grep -r '{{' .  # Should return zero matches
```

### 4. Start Development

```bash
# Create your first stakeholder requirement
# Open 01-stakeholder-requirements/ and define business needs

# Write your first failing test (TDD Red phase)
# Add a test file in tests/

# Implement minimum code to pass (TDD Green phase)
# Add source in src/ or lib/Standards/
```

## Non-Interactive Initialization

Set environment variables and use `--defaults`:

```bash
export STANDARD_ORG="IEEE"
export STANDARD_NUMBER="1722.1"
export STANDARD_YEAR="2021"
export STANDARD_NAME="IEEE 1722.1-2021"
export STANDARD_SHORT="AVDECC"
export PROJECT_NAME="IEEE_1722_1_2021"
export PROJECT_LIB_NAME="ieee_1722_1_2021"
export PROJECT_NAMESPACE="IEEE::_1722_1::_2021"
export STANDARD_NS_NUMBER="_1722_1"
export STANDARD_NS_YEAR="_2021"
export HEADER_GUARD_PREFIX="IEEE_1722_1_2021"
export ORG_NAME="myorg"
export REPO_NAME="IEEE_1722_1_2021"
export CODEOWNER="myorg"
export LICENSE_TYPE="Apache-2.0"

bash init-standard-project.sh --defaults
```

## Template Placeholders Reference

| Placeholder | Description | Used In |
|-------------|-------------|---------|
| `IEEE 802.1X-2020` | Full standard name | All .md, instructions, prompts |
| `802.1X-2020` | Short identifier | Instructions, docs |
| `IEEE` | Standards organization | Folder structure, namespaces |
| `802.1X` | Standard number | Folder structure |
| `2020` | Publication year | Folder structure, namespaces |
| `wpa_supplicant-8021X-2020` | Project/CMake name | CMakeLists.txt, README, scripts |
| `wpa_supplicant_8021x` | Library target name | CMakeLists.txt, instructions |
| `ieee802_1x` | C++ root namespace | Instructions, headers |
| `802_1X` | Namespace for number | Instructions, headers |
| `2020` | Namespace for year | Instructions, headers |
| `IEEE802_1X_2020` | Header guard prefix | Instructions |
| `wpa_supplicant` | GitHub organization | README badges, scripts, workflows |
| `wpa_supplicant-8021X-2020` | GitHub repository name | README badges, scripts |
| `@johnfu-ai` | Default code owner | CODEOWNERS |
| `none` | License identifier | LICENSE file |
| `C11` | Language version (e.g., 17) | CMakeLists.txt |

## Enhanced Initialization (NEW)

The initializer now includes three additional interview sections beyond the original standard and project information:

### Standard Discovery ("Superpower Brainstorming")

The wizard conducts a structured discovery session to understand the standard:

| Field | Description | Example |
|-------|-------------|---------|
| `SPEC_LOCATION` | Path/URL to specification PDF | `/docs/IEEE-802.1X-2020.pdf` |
| `SPEC_SECTIONS_SCOPE` | In-scope specification sections | `Sections 8-12, Annex A` |
| `STANDARD_DESCRIPTION` | One-line description | `Port-based network access control` |
| `PROTOCOL_LAYER` | OSI layer classification | `Network` |
| `RELATED_STANDARDS` | Related standards | `IEEE 802.1Q-2018, RFC 3748` |
| `KEY_PROTOCOL_FEATURES` | Core features to implement | `EAP state machine, EAPOL frames` |
| `DEVICE_TYPES` | Target device types | `Authenticator, Supplicant` |
| `TIMING_REQUIREMENTS` | Real-time constraints | `none` or `sub-microsecond` |
| `TRANSPORT_MAPPINGS` | Network transports | `IEEE 802.3 Ethernet` |

Results are persisted to `01-stakeholder-requirements/standard-discovery.md`.

### Technical Stack Selection

Choose the development technology stack:

| Field | Description | Options | Default |
|-------|-------------|---------|---------|
| `PRIMARY_LANGUAGE` | Implementation language | C++, C, Python, Rust, Go, Mixed | C++ |
| `LANGUAGE_STANDARD` | Language version | C++14/17/20/23, C11/17, etc. | C++17 |
| `TEST_FRAMEWORK` | Testing framework | GoogleTest, Unity, pytest, etc. | GoogleTest |
| `BUILD_SYSTEM` | Build system | CMake, Cargo, setuptools, etc. | CMake |
| `BASE_PROJECT` | Existing project to extend | path/URL or "none" | none |
| `BASE_PROJECT_INTEGRATION` | How to integrate | submodule, fork, library-dependency | - |
| `EXTERNAL_DEPENDENCIES` | External libraries | comma-separated list | - |
| `TARGET_PLATFORMS` | Target platforms | embedded, linux, windows, all | cross-platform |

Results are persisted to `03-architecture/technical-stack.md`.

## Multi-Language Support

The template supports multiple implementation languages. The init wizard automatically:

| Language | Build System | Test Framework | Walking Skeleton | Directory Structure |
|----------|-------------|----------------|-----------------|-------------------|
| **C++** | CMake | GoogleTest | `examples/walking_skeleton/main.cpp` | `include/`, `lib/Standards/`, `src/` |
| **C** | CMake | Unity | `examples/walking_skeleton/main.c` | `include/`, `lib/Standards/`, `src/` |
| **Python** | setuptools | pytest | `examples/walking_skeleton/main.py` | `src/<package>/`, `tests/` |
| **Rust** | Cargo | built-in | `examples/walking_skeleton/main.rs` | `src/`, `tests/` |
| **Mixed** | CMake (C/C++) | GoogleTest | `examples/walking_skeleton/main.cpp` | `include/`, `lib/Standards/`, `src/` |

For each language, the wizard:
1. Installs the correct build configuration (CMakeLists.txt, pyproject.toml, Cargo.toml)
2. Copies the language-specific walking skeleton example
3. Creates appropriate directory structure
4. Generates an initial test file
5. Configures the test framework

## What's Included

### Canonical AI Assets (`ai/`)

`ai/` is the source-of-truth for portable AI content. Use `python3 scripts/sync-ai-adapters.py` to refresh `.github/` compatibility files.

### AI Agents (`ai/agents/`)
| Agent | Role |
|-------|------|
| `tdd-driver.md` | TDD execution (Red-Green-Refactor) |
| `requirements-analyst.md` | Requirements engineering |
| `architecture-strategist.md` | Architecture decisions |
| `testing-specialist.md` | Test quality and coverage |
| `documentation-expert.md` | Documentation generation |
| `security-analyst.md` | Security analysis |

### Phase Instructions (`ai/instructions/`)
Auto-apply when editing files in the corresponding phase directory:
- `phase-01-stakeholder-requirements.instructions.md`
- `phase-02-requirements.instructions.md`
- `phase-03-architecture.instructions.md`
- `phase-04-design.instructions.md`
- `phase-05-implementation.instructions.md`
- `phase-06-integration.instructions.md`
- `phase-07-verification-validation.instructions.md`
- `phase-08-transition.instructions.md`
- `phase-09-operation-maintenance.instructions.md`

### Prompt Files (`ai/prompts/`)
42+ guided workflow prompts for common tasks like test generation, requirements elicitation, architecture review, and traceability validation.

### Skills (`ai/skills/`)
Focused IEEE 802.1X-2020 capabilities that can be combined by different tools without copying full agent personas.

### Spec-Kit Templates (`spec-kit-templates/`)
Markdown templates with YAML front matter for:
- Requirements specifications
- Architecture specifications
- Operational profiles
- Software reliability program plans
- User stories

## Updating from Upstream Template

To pull improvements from the template into an existing project:

```bash
git remote add template https://github.com/your-org/IEEE_DEV_TDD_TEMPLATE.git
git fetch template
git merge template/main --allow-unrelated-histories
# Resolve conflicts (your project-specific changes take priority)
```

## What's NOT Included

- No protocol implementation code (you write this via TDD)
- No project-specific requirements, architecture, or test content
- No vendor/OS-specific code
- No gap analyses or compliance matrices (generated per-project)

## Development Workflow

After initialization, follow the step-by-step slash command workflow in **[docs/DEVELOPMENT-WORKFLOW-GUIDE.md](docs/DEVELOPMENT-WORKFLOW-GUIDE.md)** to go from project kickoff to your first protocol feature.
