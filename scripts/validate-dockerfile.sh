#!/bin/bash
# =============================================================================
# validate-dockerfile.sh - Validate Dockerfile COPY statements
# =============================================================================
#
# Validates that all COPY source paths in a Dockerfile exist in the filesystem.
# This prevents build failures due to missing directories or files.
#
# Usage:
#   ./validate-dockerfile.sh <Dockerfile>
#   ./validate-dockerfile.sh services/widget-core/Dockerfile
#
# Exit codes:
#   0 - All COPY sources exist
#   1 - One or more COPY sources missing
#   2 - Usage error (no Dockerfile specified or file not found)
#
# Features:
#   - Parses COPY statements from Dockerfile
#   - Verifies each source path exists relative to Dockerfile directory
#   - Supports glob patterns (e.g., config*, *.txt)
#   - Skips multi-stage COPY --from statements
#   - Handles multiple sources in single COPY statement
#
# Integration:
#   - CI/CD: Add as pre-build step
#   - Pre-commit: Optional hook for local validation
#
# Author: @refactor_agent
# Date: 2025-11-18
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# =============================================================================
# Functions
# =============================================================================

usage() {
    echo "Usage: $0 <Dockerfile>"
    echo ""
    echo "Validates that all COPY source paths in a Dockerfile exist."
    echo ""
    echo "Examples:"
    echo "  $0 services/widget-core/Dockerfile"
    echo "  $0 ./Dockerfile"
    exit 2
}

log_error() {
    echo -e "${RED}❌ ERROR:${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}⚠️  WARNING:${NC} $1"
}

log_success() {
    echo -e "${GREEN}✅${NC} $1"
}

log_info() {
    echo -e "   $1"
}

# Check if a path exists (supports globs)
path_exists() {
    local base_dir="$1"
    local path="$2"

    # Handle absolute paths
    if [[ "$path" == /* ]]; then
        [[ -e "$path" ]] && return 0
        # Try glob expansion
        compgen -G "$path" > /dev/null 2>&1 && return 0
        return 1
    fi

    # Handle relative paths
    local full_path="$base_dir/$path"

    # Direct existence check
    [[ -e "$full_path" ]] && return 0

    # Try glob expansion
    compgen -G "$full_path" > /dev/null 2>&1 && return 0

    return 1
}

# Extract COPY sources from a Dockerfile
extract_copy_sources() {
    local dockerfile="$1"

    # Parse COPY statements
    # - Skip comments
    # - Skip --from= (multi-stage builds)
    # - Extract source paths (everything except last argument which is destination)
    grep -E "^[[:space:]]*COPY[[:space:]]+" "$dockerfile" 2>/dev/null | while read -r line; do
        # Skip if it's a multi-stage COPY --from
        if [[ "$line" =~ --from= ]]; then
            continue
        fi

        # Remove COPY keyword and leading whitespace
        local args
        args=$(echo "$line" | sed -E 's/^[[:space:]]*COPY[[:space:]]+//')

        # Remove flags (--chown, --chmod, etc.)
        args=$(echo "$args" | sed -E 's/--[a-z]+=\S+[[:space:]]*//g')

        # Remove shell operators and everything after (|| true, && echo, etc.)
        args=$(echo "$args" | sed -E 's/[[:space:]]*(\|\||&&).*$//')

        # Split into array - all but last element are sources
        local -a parts
        read -ra parts <<< "$args"

        # Get all sources (everything except the last element which is destination)
        local num_parts=${#parts[@]}
        if [[ $num_parts -ge 2 ]]; then
            for ((i=0; i<num_parts-1; i++)); do
                echo "${parts[i]}"
            done
        fi
    done
}

# =============================================================================
# Main
# =============================================================================

main() {
    # Check arguments
    if [[ $# -lt 1 ]]; then
        usage
    fi

    local dockerfile="$1"

    # Verify Dockerfile exists
    if [[ ! -f "$dockerfile" ]]; then
        log_error "Dockerfile not found: $dockerfile"
        exit 2
    fi

    # Get directory containing Dockerfile (build context)
    local dockerfile_dir
    dockerfile_dir=$(dirname "$dockerfile")

    echo "Validating COPY statements in: $dockerfile"
    echo "Build context: $dockerfile_dir"
    echo ""

    # Track results
    local missing_count=0
    local found_count=0
    local skipped_count=0

    # Extract sources to a temporary file to avoid subshell issues
    local tmp_sources
    tmp_sources=$(mktemp)
    extract_copy_sources "$dockerfile" > "$tmp_sources"

    # Validate each COPY source
    while IFS= read -r source; do
        # Skip empty lines
        [[ -z "$source" ]] && continue

        # Skip variables like $BUILD_DIR
        if [[ "$source" == *'$'* ]]; then
            log_warning "Skipping variable: $source"
            ((skipped_count++))
            continue
        fi

        # Check if source exists
        if path_exists "$dockerfile_dir" "$source"; then
            log_success "Found: $source"
            ((found_count++))
        else
            log_error "Missing: $source"
            ((missing_count++))
        fi
    done < "$tmp_sources"

    # Cleanup
    rm -f "$tmp_sources"

    # Summary
    echo ""
    echo "=========================================="
    echo "Validation Summary"
    echo "=========================================="
    echo "  Found:   $found_count"
    echo "  Missing: $missing_count"
    echo "  Skipped: $skipped_count"
    echo ""

    if [[ $missing_count -gt 0 ]]; then
        log_error "Validation FAILED - $missing_count missing source(s)"
        echo ""
        echo "Please ensure all COPY source paths exist before building."
        echo "If using Dockerfile.minimal for pilot builds, this may be expected."
        exit 1
    elif [[ $found_count -eq 0 && $skipped_count -eq 0 ]]; then
        log_warning "No COPY statements found in Dockerfile"
        exit 0
    else
        log_success "Validation PASSED - All COPY sources exist"
        exit 0
    fi
}

# Run main
main "$@"
