#!/usr/bin/env bash
# =============================================================================
# init-standard-project.sh
# =============================================================================
# Interactive wizard to initialize a new standards-compliant project from this
# template. Conducts a structured discovery session ("superpower brainstorming"),
# gathers technical stack preferences, and generates a standard-specific project.
#
# Usage:
#   bash init-standard-project.sh              # Interactive mode
#   bash init-standard-project.sh --defaults   # Use environment variables
#   bash init-standard-project.sh --dry-run    # Show what would be generated
#
# Environment variables (for non-interactive use):
#   STANDARD_NAME, STANDARD_SHORT, STANDARD_ORG, STANDARD_NUMBER,
#   STANDARD_YEAR, PROJECT_NAME, PROJECT_LIB_NAME, PROJECT_NAMESPACE,
#   STANDARD_NS_NUMBER, STANDARD_NS_YEAR, HEADER_GUARD_PREFIX,
#   ORG_NAME, REPO_NAME, CODEOWNER, LICENSE_TYPE,
#   SPEC_LOCATION, SPEC_SECTIONS_SCOPE, STANDARD_DESCRIPTION,
#   PROTOCOL_LAYER, RELATED_STANDARDS, KEY_PROTOCOL_FEATURES,
#   DEVICE_TYPES, TIMING_REQUIREMENTS, TRANSPORT_MAPPINGS,
#   PRIMARY_LANGUAGE, LANGUAGE_STANDARD, TEST_FRAMEWORK, BUILD_SYSTEM,
#   BASE_PROJECT, BASE_PROJECT_INTEGRATION, EXTERNAL_DEPENDENCIES,
#   TARGET_PLATFORMS
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if already initialized
if [[ -f "$SCRIPT_DIR/.github/template_init_done" ]]; then
    echo "ERROR: This project has already been initialized."
    echo "       Remove .github/template_init_done to re-initialize (DANGEROUS)."
    exit 1
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Standards-Compliant Project Initializer                   ║${NC}"
echo -e "${BLUE}║   IEEE/ISO/IEC/ITU/AVnu/AES Template                       ║${NC}"
echo -e "${BLUE}║   Enhanced Discovery & Multi-Language Support               ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ─── Prompt helpers ──────────────────────────────────────────────────────────
prompt() {
    local var_name="$1"
    local prompt_text="$2"
    local default_val="${3:-}"
    local current_val="${!var_name:-$default_val}"

    if [[ -n "$current_val" ]] && [[ "${USE_DEFAULTS:-false}" == "true" ]]; then
        printf -v "$var_name" '%s' "$current_val"
        return
    fi

    if [[ -n "$default_val" ]]; then
        read -rp "  $prompt_text [$default_val]: " input
        printf -v "$var_name" '%s' "${input:-$default_val}"
    else
        read -rp "  $prompt_text: " input
        while [[ -z "$input" ]]; do
            echo -e "    ${RED}This field is required.${NC}"
            read -rp "  $prompt_text: " input
        done
        printf -v "$var_name" '%s' "$input"
    fi
}

prompt_optional() {
    local var_name="$1"
    local prompt_text="$2"
    local default_val="${3:-}"
    local current_val="${!var_name:-$default_val}"

    # In --defaults mode, accept whatever value we have (even empty)
    if [[ "${USE_DEFAULTS:-false}" == "true" ]]; then
        printf -v "$var_name" '%s' "$current_val"
        return
    fi

    if [[ -n "$default_val" ]]; then
        read -rp "  $prompt_text [$default_val]: " input
        printf -v "$var_name" '%s' "${input:-$default_val}"
    else
        read -rp "  $prompt_text (optional, press Enter to skip): " input
        printf -v "$var_name" '%s' "${input:-}"
    fi
}

prompt_choice() {
    local var_name="$1"
    local prompt_text="$2"
    local choices="$3"
    local default_val="${4:-}"
    local current_val="${!var_name:-$default_val}"

    # In --defaults mode, accept whatever value we have
    if [[ "${USE_DEFAULTS:-false}" == "true" ]]; then
        printf -v "$var_name" '%s' "${current_val:-$default_val}"
        return
    fi

    echo -e "  ${CYAN}Options: ${choices}${NC}"
    if [[ -n "$default_val" ]]; then
        read -rp "  $prompt_text [$default_val]: " input
        printf -v "$var_name" '%s' "${input:-$default_val}"
    else
        read -rp "  $prompt_text: " input
        printf -v "$var_name" '%s' "${input:-$default_val}"
    fi
}

# ─── Handle flags ────────────────────────────────────────────────────────────
DRY_RUN=false
if [[ "${1:-}" == "--defaults" ]]; then
    USE_DEFAULTS=true
elif [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

# =============================================================================
# SECTION 1: Standard Information
# =============================================================================
echo -e "${YELLOW}━━ Section 1/6: Standard Information ━━${NC}"
echo ""
prompt STANDARD_ORG    "Standards organization (IEEE/ISO/IEC/ITU/AVnu/AES)" "IEEE"
prompt STANDARD_NUMBER "Standard number (e.g., 1588, 802.1, 1722.1)" ""
prompt STANDARD_YEAR   "Publication year (e.g., 2019, 2021)" ""
prompt STANDARD_NAME   "Full standard name (e.g., IEEE 1588-2019)" "${STANDARD_ORG} ${STANDARD_NUMBER}-${STANDARD_YEAR}"
prompt STANDARD_SHORT  "Short identifier (e.g., PTPv2, gPTP, AVDECC)" ""

# =============================================================================
# SECTION 2: Standard Discovery (Superpower Brainstorming)
# =============================================================================
echo ""
echo -e "${YELLOW}━━ Section 2/6: Standard Discovery ━━${NC}"
echo -e "  ${CYAN}Let's understand the standard you're implementing.${NC}"
echo -e "  ${CYAN}This information will customize AI agents and project scaffolding.${NC}"
echo ""

prompt_optional SPEC_LOCATION       "Path or URL to specification document (PDF)"
prompt_optional SPEC_SECTIONS_SCOPE "In-scope sections/clauses (e.g., Sections 9-13, Annex C)"
prompt          STANDARD_DESCRIPTION "One-line description of what this standard defines" ""

prompt_choice PROTOCOL_LAYER "Protocol layer" \
    "Application, Transport, Network, Physical, Cross-layer, Other" "Cross-layer"

prompt_optional RELATED_STANDARDS "Related standards (comma-separated, e.g., IEEE 802.1AS-2021, IEEE 1722-2016)"

echo ""
echo -e "  ${CYAN}Protocol features and scope:${NC}"
prompt KEY_PROTOCOL_FEATURES "Key protocol features to implement (comma-separated)" ""
prompt_optional DEVICE_TYPES        "Target device types (comma-separated)"
prompt_optional TIMING_REQUIREMENTS "Real-time timing requirements (e.g., sub-microsecond, none)" "none"
prompt_optional TRANSPORT_MAPPINGS  "Network transports to support (e.g., UDP/IPv4, IEEE 802.3)"

# =============================================================================
# SECTION 3: Technical Stack
# =============================================================================
echo ""
echo -e "${YELLOW}━━ Section 3/6: Technical Stack ━━${NC}"
echo -e "  ${CYAN}Choose the language, toolchain, and build system for your project.${NC}"
echo ""

prompt_choice PRIMARY_LANGUAGE "Primary implementation language" \
    "C++, C, Python, Rust, Go, Mixed" "C++"

# Determine language-specific defaults
case "$PRIMARY_LANGUAGE" in
    C++)
        DEFAULT_LANG_STD="17"
        DEFAULT_TEST_FW="GoogleTest"
        DEFAULT_BUILD_SYS="CMake"
        echo -e "  ${CYAN}C++ version options: 14, 17, 20, 23${NC}"
        ;;
    C)
        DEFAULT_LANG_STD="11"
        DEFAULT_TEST_FW="Unity"
        DEFAULT_BUILD_SYS="CMake"
        echo -e "  ${CYAN}C standard options: 11, 17, 23${NC}"
        ;;
    Python)
        DEFAULT_LANG_STD="3.10"
        DEFAULT_TEST_FW="pytest"
        DEFAULT_BUILD_SYS="setuptools"
        echo -e "  ${CYAN}Python version options: 3.10, 3.11, 3.12, 3.13${NC}"
        ;;
    Rust)
        DEFAULT_LANG_STD="2021"
        DEFAULT_TEST_FW="built-in"
        DEFAULT_BUILD_SYS="Cargo"
        echo -e "  ${CYAN}Rust edition options: 2021, 2024${NC}"
        ;;
    Go)
        DEFAULT_LANG_STD="1.21"
        DEFAULT_TEST_FW="testing"
        DEFAULT_BUILD_SYS="go-modules"
        echo -e "  ${CYAN}Go version options: 1.21, 1.22, 1.23${NC}"
        ;;
    Mixed)
        DEFAULT_LANG_STD="17"
        DEFAULT_TEST_FW="GoogleTest"
        DEFAULT_BUILD_SYS="CMake"
        echo -e "  ${CYAN}Mixed mode: C/C++ primary with secondary languages.${NC}"
        echo -e "  ${CYAN}C++ standard will be used for the CMake configuration.${NC}"
        ;;
    *)
        DEFAULT_LANG_STD="17"
        DEFAULT_TEST_FW="GoogleTest"
        DEFAULT_BUILD_SYS="CMake"
        ;;
esac

prompt LANGUAGE_STANDARD "Language standard/version" "$DEFAULT_LANG_STD"
prompt TEST_FRAMEWORK    "Test framework" "$DEFAULT_TEST_FW"
prompt BUILD_SYSTEM      "Build system" "$DEFAULT_BUILD_SYS"

echo ""
echo -e "  ${CYAN}Existing project and dependencies:${NC}"
prompt_optional BASE_PROJECT "Existing project this builds upon (path, Git URL, or none)" "none"

if [[ "$BASE_PROJECT" != "none" && -n "$BASE_PROJECT" ]]; then
    prompt_choice BASE_PROJECT_INTEGRATION "How to integrate base project" \
        "submodule, fork, library-dependency" "submodule"
else
    BASE_PROJECT_INTEGRATION="none"
fi

prompt_optional EXTERNAL_DEPENDENCIES "External library dependencies (comma-separated)"

prompt_choice TARGET_PLATFORMS "Target platforms" \
    "embedded, linux, windows, cross-platform, all" "cross-platform"

# =============================================================================
# SECTION 4: Project Information
# =============================================================================
echo ""
echo -e "${YELLOW}━━ Section 4/6: Project Information ━━${NC}"
echo ""

# Derive defaults from standard info
DEFAULT_PROJECT_NAME="${STANDARD_ORG}_${STANDARD_NUMBER//./_}_${STANDARD_YEAR}"
DEFAULT_LIB_NAME="$(echo "${STANDARD_ORG}_${STANDARD_NUMBER//./_}_${STANDARD_YEAR}" | tr '[:upper:]' '[:lower:]')"
DEFAULT_NS_NUMBER="_${STANDARD_NUMBER//./_}"
DEFAULT_NS_YEAR="_${STANDARD_YEAR}"
DEFAULT_HEADER_GUARD="${STANDARD_ORG}_${STANDARD_NUMBER//./_}_${STANDARD_YEAR}"
DEFAULT_NAMESPACE="${STANDARD_ORG}::${DEFAULT_NS_NUMBER}::${DEFAULT_NS_YEAR}"

prompt PROJECT_NAME       "Project name (used in build system, folders)" "$DEFAULT_PROJECT_NAME"
prompt PROJECT_LIB_NAME   "Library target name (lowercase)" "$DEFAULT_LIB_NAME"

# Language-specific naming
case "$PRIMARY_LANGUAGE" in
    C++|C|Mixed)
        prompt PROJECT_NAMESPACE    "C/C++ namespace (e.g., IEEE::_1588::_2019)" "$DEFAULT_NAMESPACE"
        prompt STANDARD_NS_NUMBER   "Namespace for standard number" "$DEFAULT_NS_NUMBER"
        prompt STANDARD_NS_YEAR     "Namespace for year" "$DEFAULT_NS_YEAR"
        prompt HEADER_GUARD_PREFIX  "Header guard prefix" "$DEFAULT_HEADER_GUARD"
        ;;
    Python)
        PROJECT_NAMESPACE="${PROJECT_LIB_NAME}"
        STANDARD_NS_NUMBER="$DEFAULT_NS_NUMBER"
        STANDARD_NS_YEAR="$DEFAULT_NS_YEAR"
        HEADER_GUARD_PREFIX="$DEFAULT_HEADER_GUARD"
        echo -e "  Python package name: ${GREEN}${PROJECT_LIB_NAME}${NC}"
        ;;
    Rust)
        PROJECT_NAMESPACE="${PROJECT_LIB_NAME//-/_}"
        STANDARD_NS_NUMBER="$DEFAULT_NS_NUMBER"
        STANDARD_NS_YEAR="$DEFAULT_NS_YEAR"
        HEADER_GUARD_PREFIX="$DEFAULT_HEADER_GUARD"
        echo -e "  Rust crate name: ${GREEN}${PROJECT_LIB_NAME}${NC}"
        ;;
    *)
        PROJECT_NAMESPACE="$DEFAULT_NAMESPACE"
        STANDARD_NS_NUMBER="$DEFAULT_NS_NUMBER"
        STANDARD_NS_YEAR="$DEFAULT_NS_YEAR"
        HEADER_GUARD_PREFIX="$DEFAULT_HEADER_GUARD"
        ;;
esac

# =============================================================================
# SECTION 5: Repository Information
# =============================================================================
echo ""
echo -e "${YELLOW}━━ Section 5/6: Repository Information ━━${NC}"
echo ""
prompt ORG_NAME   "GitHub organization/username" ""
prompt REPO_NAME  "GitHub repository name" "$PROJECT_NAME"
prompt CODEOWNER  "Default code owner (GitHub username)" "$ORG_NAME"

# =============================================================================
# SECTION 6: License
# =============================================================================
echo ""
echo -e "${YELLOW}━━ Section 6/6: License ━━${NC}"
echo "  Available licenses: MIT, Apache-2.0, BSD-3-Clause, GPL-3.0, none"
prompt LICENSE_TYPE "License type" "none"

# =============================================================================
# SUMMARY & CONFIRM
# =============================================================================
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}${BOLD}  Summary${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${BOLD}Standard${NC}"
echo "    Name:           $STANDARD_NAME ($STANDARD_SHORT)"
echo "    Organization:   $STANDARD_ORG"
echo "    Description:    $STANDARD_DESCRIPTION"
echo "    Protocol Layer: $PROTOCOL_LAYER"
[[ -n "${RELATED_STANDARDS:-}" ]] && echo "    Related:        $RELATED_STANDARDS"
[[ -n "${SPEC_LOCATION:-}" ]]     && echo "    Specification:  $SPEC_LOCATION"
echo ""
echo -e "  ${BOLD}Technical Stack${NC}"
echo "    Language:       $PRIMARY_LANGUAGE ($LANGUAGE_STANDARD)"
echo "    Test Framework: $TEST_FRAMEWORK"
echo "    Build System:   $BUILD_SYSTEM"
echo "    Platforms:      $TARGET_PLATFORMS"
[[ "$BASE_PROJECT" != "none" && -n "$BASE_PROJECT" ]] && \
    echo "    Base Project:   $BASE_PROJECT ($BASE_PROJECT_INTEGRATION)"
[[ -n "${EXTERNAL_DEPENDENCIES:-}" ]] && \
    echo "    Dependencies:   $EXTERNAL_DEPENDENCIES"
echo ""
echo -e "  ${BOLD}Project${NC}"
echo "    Project:        $PROJECT_NAME"
echo "    Library:        $PROJECT_LIB_NAME"
echo "    Repository:     $ORG_NAME/$REPO_NAME"
echo "    Code Owner:     $CODEOWNER"
echo "    License:        $LICENSE_TYPE"
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${YELLOW}DRY RUN — no files will be modified.${NC}"
    exit 0
fi

if [[ "${USE_DEFAULTS:-false}" != "true" ]]; then
    read -rp "  Proceed with initialization? [Y/n]: " confirm
    if [[ "${confirm,,}" == "n" ]]; then
        echo "Aborted."
        exit 0
    fi
fi

# =============================================================================
# APPLY TEMPLATE SUBSTITUTIONS
# =============================================================================
echo ""
echo -e "${BLUE}Applying template substitutions...${NC}"

cd "$SCRIPT_DIR"

# Compute derived values for language-specific templates
LANGUAGE_STANDARD_VERSION="$LANGUAGE_STANDARD"
# Python needs a no-dot version for ruff target-version (e.g., "310" from "3.10")
LANGUAGE_STANDARD_VERSION_NODOT="${LANGUAGE_STANDARD//./}"

# Build sed expression
SED_ARGS=(
    -e "s|{{STANDARD_NAME}}|${STANDARD_NAME}|g"
    -e "s|{{STANDARD_SHORT}}|${STANDARD_SHORT}|g"
    -e "s|{{STANDARD_ORG}}|${STANDARD_ORG}|g"
    -e "s|{{STANDARD_NUMBER}}|${STANDARD_NUMBER}|g"
    -e "s|{{STANDARD_YEAR}}|${STANDARD_YEAR}|g"
    -e "s|{{PROJECT_NAME}}|${PROJECT_NAME}|g"
    -e "s|{{PROJECT_LIB_NAME}}|${PROJECT_LIB_NAME}|g"
    -e "s|{{PROJECT_NAMESPACE}}|${PROJECT_NAMESPACE}|g"
    -e "s|{{STANDARD_NS_NUMBER}}|${STANDARD_NS_NUMBER}|g"
    -e "s|{{STANDARD_NS_YEAR}}|${STANDARD_NS_YEAR}|g"
    -e "s|{{HEADER_GUARD_PREFIX}}|${HEADER_GUARD_PREFIX}|g"
    -e "s|{{ORG_NAME}}|${ORG_NAME}|g"
    -e "s|{{REPO_NAME}}|${REPO_NAME}|g"
    -e "s|{{CODEOWNER}}|${CODEOWNER}|g"
    -e "s|{{LICENSE_TYPE}}|${LICENSE_TYPE}|g"
    -e "s|{{LANGUAGE_STANDARD_VERSION}}|${LANGUAGE_STANDARD_VERSION}|g"
    -e "s|{{LANGUAGE_STANDARD_VERSION_NODOT}}|${LANGUAGE_STANDARD_VERSION_NODOT}|g"
)

# Apply to all text files (excluding templates directory and this script)
find . -type f \( \
    -name '*.md' -o -name '*.yml' -o -name '*.yaml' \
    -o -name 'CMakeLists.txt' -o -name '*.cmake' -o -name '*.cmake.in' \
    -o -name 'Doxyfile' \
    -o -name '*.sh' -o -name '*.ps1' -o -name '*.cmd' \
    -o -name '*.py' -o -name '*.json' \
    -o -name '*.cpp' -o -name '*.hpp' -o -name '*.h' -o -name '*.c' \
    -o -name '*.rs' -o -name '*.toml' \
    -o -name 'CODEOWNERS' -o -name '.gitignore' \
\) ! -path './.git/*' ! -path './scripts/templates/*' ! -name 'init-standard-project.sh' \
  -exec sed -i "${SED_ARGS[@]}" {} +

echo -e "  ${GREEN}✓${NC} Placeholder substitution complete"

# =============================================================================
# INSTALL LANGUAGE-SPECIFIC BUILD SYSTEM
# =============================================================================
echo -e "${BLUE}Setting up build system for ${PRIMARY_LANGUAGE}...${NC}"

TEMPLATES_DIR="scripts/templates"

case "$PRIMARY_LANGUAGE" in
    C++)
        # Replace CMakeLists.txt with C++ template
        cp "$TEMPLATES_DIR/cmake_cpp.txt" CMakeLists.txt
        sed -i "${SED_ARGS[@]}" CMakeLists.txt
        # Install C++ walking skeleton
        cp "$TEMPLATES_DIR/examples/walking_skeleton_cpp.cpp" examples/walking_skeleton/main.cpp
        sed -i "${SED_ARGS[@]}" examples/walking_skeleton/main.cpp
        echo -e "  ${GREEN}✓${NC} C++ (${LANGUAGE_STANDARD}) build system configured"
        ;;
    C)
        # Replace CMakeLists.txt with C template
        cp "$TEMPLATES_DIR/cmake_c.txt" CMakeLists.txt
        sed -i "${SED_ARGS[@]}" CMakeLists.txt
        # Install C walking skeleton
        cp "$TEMPLATES_DIR/examples/walking_skeleton_c.c" examples/walking_skeleton/main.c
        rm -f examples/walking_skeleton/main.cpp
        # Update examples CMakeLists.txt for C
        cat > examples/CMakeLists.txt << 'CMEOF'
if(BUILD_EXAMPLES)
    add_executable(walking_skeleton
        walking_skeleton/main.c
    )
    # Link against the protocol library when it exists:
    # target_link_libraries(walking_skeleton PRIVATE ${PROJECT_NAME})
endif()
CMEOF
        sed -i "${SED_ARGS[@]}" examples/walking_skeleton/main.c
        echo -e "  ${GREEN}✓${NC} C (${LANGUAGE_STANDARD}) build system configured"
        ;;
    Python)
        # Replace CMakeLists.txt with pyproject.toml
        cp "$TEMPLATES_DIR/pyproject_toml.txt" pyproject.toml
        sed -i "${SED_ARGS[@]}" pyproject.toml
        # Create Python package structure
        mkdir -p "src/${PROJECT_LIB_NAME}"
        cat > "src/${PROJECT_LIB_NAME}/__init__.py" << PYEOF
"""${STANDARD_NAME} - Hardware-agnostic protocol implementation."""

__version__ = "0.1.0"
PYEOF
        # Install Python walking skeleton
        mkdir -p examples/walking_skeleton
        cp "$TEMPLATES_DIR/examples/walking_skeleton_python.py" examples/walking_skeleton/main.py
        sed -i "${SED_ARGS[@]}" examples/walking_skeleton/main.py
        rm -f examples/walking_skeleton/main.cpp
        # Create pytest config
        mkdir -p tests
        cat > tests/__init__.py << 'TESTEOF'
"""Test package."""
TESTEOF
        cat > "tests/test_${PROJECT_LIB_NAME}_init.py" << TESTEOF
"""
Initial test for ${STANDARD_NAME} implementation.

Verifies that the package can be imported and basic protocol
engine can be initialized with a mock interface.
"""
import pytest


def test_package_import():
    """Verify the package can be imported."""
    import ${PROJECT_LIB_NAME}
    assert hasattr(${PROJECT_LIB_NAME}, '__version__')


def test_version():
    """Verify version string is set."""
    import ${PROJECT_LIB_NAME}
    assert ${PROJECT_LIB_NAME}.__version__ == "0.1.0"
TESTEOF
        # Remove C++ specific files
        rm -f CMakeLists.txt tests/CMakeLists.txt examples/CMakeLists.txt
        echo -e "  ${GREEN}✓${NC} Python (${LANGUAGE_STANDARD}) project configured"
        ;;
    Rust)
        # Replace CMakeLists.txt with Cargo.toml
        cp "$TEMPLATES_DIR/cargo_toml.txt" Cargo.toml
        sed -i "${SED_ARGS[@]}" Cargo.toml
        # Create Rust source structure
        mkdir -p src
        cat > src/lib.rs << RSEOF
//! ${STANDARD_NAME} - Hardware-agnostic protocol implementation.
//!
//! See: ${STANDARD_NAME} specification for authoritative requirements.

/// Protocol version
pub const VERSION: &str = "0.1.0";

/// Abstract hardware abstraction layer for network I/O and timing.
pub trait NetworkInterface {
    /// Send a packet. Returns Ok(()) on success.
    fn send_packet(&self, packet: &[u8]) -> Result<(), i32>;
    /// Receive a packet into the provided buffer. Returns bytes read.
    fn receive_packet(&self, buffer: &mut [u8]) -> Result<usize, i32>;
    /// Return current time in nanoseconds.
    fn get_time_ns(&self) -> u64;
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_version() {
        assert_eq!(VERSION, "0.1.0");
    }
}
RSEOF
        # Install Rust walking skeleton
        mkdir -p examples/walking_skeleton
        cp "$TEMPLATES_DIR/examples/walking_skeleton_rust.rs" examples/walking_skeleton/main.rs
        sed -i "${SED_ARGS[@]}" examples/walking_skeleton/main.rs
        rm -f examples/walking_skeleton/main.cpp
        # Remove C++ specific files
        rm -f CMakeLists.txt tests/CMakeLists.txt examples/CMakeLists.txt
        echo -e "  ${GREEN}✓${NC} Rust (edition ${LANGUAGE_STANDARD}) project configured"
        ;;
    Mixed)
        # Use C++ template with both C and CXX languages
        cp "$TEMPLATES_DIR/cmake_cpp.txt" CMakeLists.txt
        # Add C language to CMakeLists.txt
        sed -i 's/LANGUAGES CXX/LANGUAGES C CXX/' CMakeLists.txt
        sed -i "${SED_ARGS[@]}" CMakeLists.txt
        cp "$TEMPLATES_DIR/examples/walking_skeleton_cpp.cpp" examples/walking_skeleton/main.cpp
        sed -i "${SED_ARGS[@]}" examples/walking_skeleton/main.cpp
        echo -e "  ${GREEN}✓${NC} Mixed C/C++ (${LANGUAGE_STANDARD}) build system configured"
        ;;
    *)
        echo -e "  ${YELLOW}⚠${NC} Language '${PRIMARY_LANGUAGE}' not yet templated. Using default CMakeLists.txt."
        ;;
esac

# =============================================================================
# CREATE STANDARDS DIRECTORY STRUCTURE (C/C++ only)
# =============================================================================
case "$PRIMARY_LANGUAGE" in
    C++|C|Mixed)
        echo -e "${BLUE}Creating standards directory structure...${NC}"
        STANDARDS_DIR="lib/Standards/${STANDARD_ORG}/${STANDARD_NUMBER}/${STANDARD_YEAR}"
        mkdir -p "$STANDARDS_DIR"/{core,messages,conformity}
        touch "$STANDARDS_DIR"/{core,messages,conformity}/.gitkeep
        echo -e "  ${GREEN}✓${NC} Created $STANDARDS_DIR/"

        # Generate standard-specific header structure
        echo -e "${BLUE}Generating header stubs...${NC}"
        INCLUDE_DIR="include/${STANDARD_ORG}/${STANDARD_NUMBER//.//}/${STANDARD_YEAR}"
        mkdir -p "$INCLUDE_DIR"

        cat > "$INCLUDE_DIR/${PROJECT_LIB_NAME}.hpp" << HDREOF
#ifndef ${HEADER_GUARD_PREFIX}_HPP
#define ${HEADER_GUARD_PREFIX}_HPP

/**
 * @file ${PROJECT_LIB_NAME}.hpp
 * @brief Top-level header for ${STANDARD_NAME} implementation
 *
 * This is the main include file for the ${STANDARD_SHORT} protocol library.
 * It provides the public API for the hardware-agnostic protocol implementation.
 *
 * @see ${STANDARD_NAME} specification for authoritative requirements.
 */

namespace ${STANDARD_ORG} {
namespace ${STANDARD_NS_NUMBER} {
namespace ${STANDARD_NS_YEAR} {

// TODO: Add protocol API declarations here.
// Key features to implement: ${KEY_PROTOCOL_FEATURES}

} // namespace ${STANDARD_NS_YEAR}
} // namespace ${STANDARD_NS_NUMBER}
} // namespace ${STANDARD_ORG}

#endif // ${HEADER_GUARD_PREFIX}_HPP
HDREOF

        cat > "$INCLUDE_DIR/types.hpp" << TYPEOF
#ifndef ${HEADER_GUARD_PREFIX}_TYPES_HPP
#define ${HEADER_GUARD_PREFIX}_TYPES_HPP

/**
 * @file types.hpp
 * @brief ${STANDARD_NAME} data types
 *
 * Defines protocol data types for ${STANDARD_SHORT} implementation.
 * Implement per specification requirements.
 *
 * @see ${STANDARD_NAME} specification for data type definitions.
 */

#include <cstdint>

namespace ${STANDARD_ORG} {
namespace ${STANDARD_NS_NUMBER} {
namespace ${STANDARD_NS_YEAR} {

// TODO: Define protocol data types here.

} // namespace ${STANDARD_NS_YEAR}
} // namespace ${STANDARD_NS_NUMBER}
} // namespace ${STANDARD_ORG}

#endif // ${HEADER_GUARD_PREFIX}_TYPES_HPP
TYPEOF

        cat > "$INCLUDE_DIR/messages.hpp" << MSGEOF
#ifndef ${HEADER_GUARD_PREFIX}_MESSAGES_HPP
#define ${HEADER_GUARD_PREFIX}_MESSAGES_HPP

/**
 * @file messages.hpp
 * @brief ${STANDARD_NAME} message formats
 *
 * Defines protocol message structures for ${STANDARD_SHORT} implementation.
 * Implement per specification message format sections.
 *
 * @see ${STANDARD_NAME} specification for message format definitions.
 */

#include "types.hpp"

namespace ${STANDARD_ORG} {
namespace ${STANDARD_NS_NUMBER} {
namespace ${STANDARD_NS_YEAR} {

// TODO: Define protocol message structures here.

} // namespace ${STANDARD_NS_YEAR}
} // namespace ${STANDARD_NS_NUMBER}
} // namespace ${STANDARD_ORG}

#endif // ${HEADER_GUARD_PREFIX}_MESSAGES_HPP
MSGEOF
        echo -e "  ${GREEN}✓${NC} Created header stubs in $INCLUDE_DIR/"
        ;;
    *)
        echo -e "  ${CYAN}ℹ${NC} Skipping C/C++ directory structure for ${PRIMARY_LANGUAGE} project"
        ;;
esac

# =============================================================================
# GENERATE INITIAL TEST FILE
# =============================================================================
case "$PRIMARY_LANGUAGE" in
    C++|Mixed)
        echo -e "${BLUE}Generating initial test file...${NC}"
        INCLUDE_DIR="include/${STANDARD_ORG}/${STANDARD_NUMBER//.//}/${STANDARD_YEAR}"
        cat > "tests/test_${PROJECT_LIB_NAME}_init.cpp" << TESTEOF
/**
 * @file test_${PROJECT_LIB_NAME}_init.cpp
 * @brief Initial TDD test for ${STANDARD_NAME} implementation
 *
 * Verifies that the library headers compile and basic initialization works.
 * This is the first "Red" test — make it pass, then add protocol-specific tests.
 *
 * Key protocol features to test:
 *   ${KEY_PROTOCOL_FEATURES}
 *
 * @see ${STANDARD_NAME} specification for authoritative requirements.
 */

#include <gtest/gtest.h>
#include "${INCLUDE_DIR}/${PROJECT_LIB_NAME}.hpp"

namespace {

TEST(${PROJECT_NAME}_Init, HeaderCompiles) {
    // This test verifies the top-level header compiles without errors.
    SUCCEED();
}

// TODO: Add protocol-specific tests following TDD Red-Green-Refactor:
// 1. Write a failing test for the next protocol feature
// 2. Implement minimum code to pass
// 3. Refactor while keeping tests green

} // namespace
TESTEOF
        # Update tests/CMakeLists.txt to include the init test
        cat > tests/CMakeLists.txt << TCMEOF
# Tests for ${PROJECT_NAME}
# TDD: Write failing tests FIRST, then implement code to pass them.

add_executable(test_${PROJECT_LIB_NAME}_init
    test_${PROJECT_LIB_NAME}_init.cpp
)
target_include_directories(test_${PROJECT_LIB_NAME}_init PRIVATE
    \${CMAKE_SOURCE_DIR}
)
target_link_libraries(test_${PROJECT_LIB_NAME}_init
    GTest::gtest_main
    \${PROJECT_NAME}_interface
)
gtest_discover_tests(test_${PROJECT_LIB_NAME}_init)
TCMEOF
        echo -e "  ${GREEN}✓${NC} Created tests/test_${PROJECT_LIB_NAME}_init.cpp"
        ;;
esac

# =============================================================================
# HANDLE BASE PROJECT INTEGRATION
# =============================================================================
if [[ "$BASE_PROJECT" != "none" && -n "$BASE_PROJECT" ]]; then
    echo -e "${BLUE}Configuring base project integration...${NC}"

    case "$BASE_PROJECT_INTEGRATION" in
        submodule)
            # Generate .gitmodules entry (do NOT auto-clone)
            cat >> .gitmodules << SUBEOF

[submodule "external/base-project"]
	path = external/base-project
	url = ${BASE_PROJECT}
SUBEOF
            mkdir -p external
            cat > external/README.md << EXTEOF
# External Dependencies

## Base Project

- **URL**: ${BASE_PROJECT}
- **Integration**: Git submodule
- **Purpose**: Foundation for ${STANDARD_NAME} implementation

### Setup

\`\`\`bash
git submodule update --init --recursive
\`\`\`

### Adapter Layer

Create an adapter layer to isolate your domain from the base project's API.
Do not depend directly on internal structures — use the adapter pattern.

See: \`ai/instructions/submodules.instructions.md\` for governance rules.
EXTEOF
            echo -e "  ${GREEN}✓${NC} Generated .gitmodules and external/README.md (NOT auto-cloned)"
            echo -e "  ${CYAN}ℹ${NC} Run 'git submodule update --init' when ready"
            ;;
        fork|library-dependency)
            mkdir -p external
            cat > external/README.md << EXTEOF
# External Dependencies

## Base Project

- **URL**: ${BASE_PROJECT}
- **Integration**: ${BASE_PROJECT_INTEGRATION}
- **Purpose**: Foundation for ${STANDARD_NAME} implementation

### Setup

$(if [[ "$BASE_PROJECT_INTEGRATION" == "fork" ]]; then
    echo "This project is a fork of the base project."
    echo "Add the upstream remote:"
    echo ""
    echo '```bash'
    echo "git remote add upstream ${BASE_PROJECT}"
    echo '```'
else
    echo "Add this as a dependency in your build configuration."
fi)
EXTEOF
            echo -e "  ${GREEN}✓${NC} Documented base project (${BASE_PROJECT_INTEGRATION})"
            ;;
    esac
fi

# =============================================================================
# GENERATE STANDARD DISCOVERY DOCUMENT
# =============================================================================
echo -e "${BLUE}Generating standard discovery document...${NC}"

cat > "01-stakeholder-requirements/standard-discovery.md" << DISCEOF
# Standard Discovery: ${STANDARD_NAME}

> Generated by init-standard-project.sh on $(date -u +"%Y-%m-%d")

## Standard Identity

| Field | Value |
|-------|-------|
| Full Name | ${STANDARD_NAME} |
| Short Identifier | ${STANDARD_SHORT} |
| Organization | ${STANDARD_ORG} |
| Number | ${STANDARD_NUMBER} |
| Year | ${STANDARD_YEAR} |
| Protocol Layer | ${PROTOCOL_LAYER} |

## Description

${STANDARD_DESCRIPTION}

## Specification Reference

$(if [[ -n "${SPEC_LOCATION:-}" ]]; then
    echo "- **Document**: ${SPEC_LOCATION}"
else
    echo "- **Document**: _(not provided — add path or URL to specification)_"
fi)
$(if [[ -n "${SPEC_SECTIONS_SCOPE:-}" ]]; then
    echo "- **In-Scope Sections**: ${SPEC_SECTIONS_SCOPE}"
else
    echo "- **In-Scope Sections**: _(define which specification sections are in scope)_"
fi)

## Related Standards

$(if [[ -n "${RELATED_STANDARDS:-}" ]]; then
    IFS=',' read -ra STDS <<< "$RELATED_STANDARDS"
    for std in "${STDS[@]}"; do
        echo "- $(echo "$std" | xargs)"
    done
else
    echo "_(none specified)_"
fi)

## Key Protocol Features

$(if [[ -n "${KEY_PROTOCOL_FEATURES:-}" ]]; then
    IFS=',' read -ra FEATS <<< "$KEY_PROTOCOL_FEATURES"
    for feat in "${FEATS[@]}"; do
        echo "- [ ] $(echo "$feat" | xargs)"
    done
else
    echo "_(none specified — define key protocol features to implement)_"
fi)

## Target Device Types

$(if [[ -n "${DEVICE_TYPES:-}" ]]; then
    IFS=',' read -ra DEVS <<< "$DEVICE_TYPES"
    for dev in "${DEVS[@]}"; do
        echo "- $(echo "$dev" | xargs)"
    done
else
    echo "_(none specified)_"
fi)

## Timing Requirements

${TIMING_REQUIREMENTS:-none}

## Transport Mappings

$(if [[ -n "${TRANSPORT_MAPPINGS:-}" ]]; then
    IFS=',' read -ra TRANS <<< "$TRANSPORT_MAPPINGS"
    for t in "${TRANS[@]}"; do
        echo "- $(echo "$t" | xargs)"
    done
else
    echo "_(none specified)_"
fi)

## Next Steps

1. Review and refine this discovery document
2. Run \`/project-kickoff\` in VS Code Copilot Chat to begin structured brainstorming
3. Create stakeholder requirements in \`01-stakeholder-requirements/\`
4. Elicit detailed requirements with \`/requirements-elicit\`
DISCEOF

echo -e "  ${GREEN}✓${NC} Created 01-stakeholder-requirements/standard-discovery.md"

# =============================================================================
# GENERATE TECHNICAL STACK DOCUMENT
# =============================================================================
echo -e "${BLUE}Generating technical stack document...${NC}"

cat > "03-architecture/technical-stack.md" << TECHEOF
# Technical Stack: ${STANDARD_NAME}

> Generated by init-standard-project.sh on $(date -u +"%Y-%m-%d")

## Language & Toolchain

| Component | Selection |
|-----------|-----------|
| Primary Language | ${PRIMARY_LANGUAGE} |
| Language Standard | ${LANGUAGE_STANDARD} |
| Test Framework | ${TEST_FRAMEWORK} |
| Build System | ${BUILD_SYSTEM} |
| Target Platforms | ${TARGET_PLATFORMS} |

## Base Project

$(if [[ "$BASE_PROJECT" != "none" && -n "$BASE_PROJECT" ]]; then
    echo "| Field | Value |"
    echo "|-------|-------|"
    echo "| Project | ${BASE_PROJECT} |"
    echo "| Integration | ${BASE_PROJECT_INTEGRATION} |"
    echo ""
    echo "See \`external/README.md\` for setup instructions."
else
    echo "No base project — this is a greenfield implementation."
fi)

## External Dependencies

$(if [[ -n "${EXTERNAL_DEPENDENCIES:-}" ]]; then
    IFS=',' read -ra DEPS <<< "$EXTERNAL_DEPENDENCIES"
    for dep in "${DEPS[@]}"; do
        echo "- $(echo "$dep" | xargs)"
    done
else
    echo "_(none specified)_"
fi)

## Architecture Decisions

- **Hardware Abstraction**: Dependency injection via $(case "$PRIMARY_LANGUAGE" in
    C++|Mixed) echo "C++ interfaces/function objects" ;;
    C) echo "C function pointers" ;;
    Python) echo "Python abstract base classes (ABC)" ;;
    Rust) echo "Rust traits" ;;
    *) echo "language-idiomatic interfaces" ;;
esac)
- **Protocol Layer**: Standards-only implementation (no vendor/OS code)
- **Testing**: TDD Red-Green-Refactor with ${TEST_FRAMEWORK}
TECHEOF

echo -e "  ${GREEN}✓${NC} Created 03-architecture/technical-stack.md"

# ─── Create LICENSE file ──────────────────────────────────────────────────────
if [[ "$LICENSE_TYPE" != "none" ]]; then
    echo -e "${BLUE}Creating LICENSE file...${NC}"
    YEAR=$(date +%Y)
    case "$LICENSE_TYPE" in
        MIT)
            cat > LICENSE << EOF
MIT License

Copyright (c) $YEAR $ORG_NAME

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF
            ;;
        Apache-2.0)
            cat > LICENSE << EOF
                                 Apache License
                           Version 2.0, January 2004
                        http://www.apache.org/licenses/

   Copyright $YEAR $ORG_NAME

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
EOF
            ;;
        BSD-3-Clause)
            cat > LICENSE << EOF
BSD 3-Clause License

Copyright (c) $YEAR, $ORG_NAME
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
EOF
            ;;
        GPL-3.0)
            cat > LICENSE << EOF
GNU GENERAL PUBLIC LICENSE
Version 3, 29 June 2007

Copyright (c) $YEAR $ORG_NAME

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <https://www.gnu.org/licenses/>.
EOF
            ;;
        *)
            echo -e "  ${YELLOW}⚠${NC} Unknown license type: $LICENSE_TYPE. Skipping LICENSE creation."
            ;;
    esac
    if [[ -f LICENSE ]]; then
        echo -e "  ${GREEN}✓${NC} Created LICENSE ($LICENSE_TYPE)"
    fi
fi

# =============================================================================
# CLEAN UP TEMPLATE FILES
# =============================================================================
echo -e "${BLUE}Cleaning up template artifacts...${NC}"

# Remove template-specific files that should not be in initialized projects
rm -rf scripts/templates/

echo -e "  ${GREEN}✓${NC} Template artifacts removed"

# =============================================================================
# MARK AS INITIALIZED
# =============================================================================
echo -e "${BLUE}Finalizing...${NC}"
touch .github/template_init_done

# =============================================================================
# INITIALIZE GIT REPOSITORY
# =============================================================================
if [[ ! -d .git ]]; then
    git init
    git add -A
    git commit -m "Initial commit from IEEE_DEV_TDD_TEMPLATE

Initialized project: $PROJECT_NAME
Standard: $STANDARD_NAME ($STANDARD_SHORT)
Organization: $STANDARD_ORG
Language: $PRIMARY_LANGUAGE ($LANGUAGE_STANDARD)
Test Framework: $TEST_FRAMEWORK
Build System: $BUILD_SYSTEM
"
    echo -e "  ${GREEN}✓${NC} Git repository initialized with initial commit"
else
    echo -e "  ${YELLOW}⚠${NC} Git repository already exists, skipping git init"
fi

# =============================================================================
# SUCCESS
# =============================================================================
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Project initialized successfully!                        ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${BOLD}Generated artifacts:${NC}"
echo "    - 01-stakeholder-requirements/standard-discovery.md  (technical charter)"
echo "    - 03-architecture/technical-stack.md                 (stack decisions)"
case "$PRIMARY_LANGUAGE" in
    C++|C|Mixed)
        echo "    - include/${STANDARD_ORG}/.../${STANDARD_YEAR}/*.hpp            (header stubs)"
        echo "    - lib/Standards/${STANDARD_ORG}/.../${STANDARD_YEAR}/            (implementation dirs)"
        echo "    - tests/test_${PROJECT_LIB_NAME}_init.cpp            (initial TDD test)"
        ;;
    Python)
        echo "    - src/${PROJECT_LIB_NAME}/                           (Python package)"
        echo "    - pyproject.toml                                     (build config)"
        echo "    - tests/test_${PROJECT_LIB_NAME}_init.py             (initial test)"
        ;;
    Rust)
        echo "    - src/lib.rs                                         (library root)"
        echo "    - Cargo.toml                                         (build config)"
        ;;
esac
[[ "$BASE_PROJECT" != "none" && -n "$BASE_PROJECT" ]] && \
    echo "    - external/README.md                                 (base project docs)"
echo ""
echo -e "  ${BOLD}Next steps:${NC}"
echo "    1. Review the generated files"
echo "    2. Open project in VS Code and use Copilot Chat slash commands:"
echo ""
echo -e "       ${CYAN}/project-kickoff${NC}       — Structured brainstorming session"
echo -e "       ${CYAN}/requirements-elicit${NC}   — Elicit requirements from the standard"
echo -e "       ${CYAN}/architecture-starter${NC}  — Design component architecture"
echo -e "       ${CYAN}/tdd-compile${NC}           — Write your first failing test"
echo ""
echo "    3. See docs/DEVELOPMENT-WORKFLOW-GUIDE.md for the full workflow"
echo ""
case "$PRIMARY_LANGUAGE" in
    C++|C|Mixed)
        echo "    Build: cmake -S . -B build && cmake --build build && ctest --test-dir build"
        ;;
    Python)
        echo "    Build: pip install -e '.[dev]' && pytest"
        ;;
    Rust)
        echo "    Build: cargo build && cargo test"
        ;;
esac
echo ""
echo -e "  ${BLUE}Happy standards-compliant coding!${NC}"
