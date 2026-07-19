#!/usr/bin/env bash
#
# Modrinth Modpack Server Builder
#
# Builds a dedicated NeoForge server from a Modrinth modpack source.
#

set -euo pipefail


################################################################################
# Paths
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"


################################################################################
# Libraries
################################################################################

source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/java.sh"
source "$SCRIPT_DIR/lib/modrinth.sh"
source "$SCRIPT_DIR/lib/filter.sh"
source "$SCRIPT_DIR/lib/download.sh"
source "$SCRIPT_DIR/lib/neoforge.sh"
source "$SCRIPT_DIR/lib/server.sh"
source "$SCRIPT_DIR/lib/cleanup.sh"


################################################################################
# Error handling
################################################################################

trap 'error "Unexpected error on line $LINENO."' ERR


################################################################################
# Configuration
################################################################################

PROJECT_SLUG=""
VERSION="latest"
MODE="build"
WORKDIR="$PWD/work"
OUTPUT="$PWD/server"
MRPACK=""
INDEX=""
SOURCE_INPUT=""


################################################################################
# CLI parsing
################################################################################

usage() {
    cat <<EOF2
Usage: ./create-modrinth-server.sh <modpack-url|slug|.mrpack-file> [--version VERSION]

Examples:
  ./create-modrinth-server.sh https://modrinth.com/modpack/example-mod
  ./create-modrinth-server.sh example-mod
  ./create-modrinth-server.sh ./example-mod.mrpack

Options:
  --version VERSION  Resolve a specific Modrinth version.
  -h, --help         Show this help text.
EOF2
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --version)
            [[ $# -ge 2 ]] || error "Missing value for --version"
            VERSION="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            if [[ -n "$SOURCE_INPUT" ]]; then
                error "Only one modpack source may be provided."
            fi
            SOURCE_INPUT="$1"
            shift
            ;;
    esac
done

[[ -n "$SOURCE_INPUT" ]] || error "A Modrinth URL, slug, or .mrpack file must be provided."


################################################################################
# Banner
################################################################################

echo
echo "======================================================="
echo "          Modrinth Modpack Server Builder"
echo "======================================================="
echo


################################################################################
# Helpers
################################################################################

download_pack() {
    echo
    echo "Preparing modpack input..."

    if [[ -n "$SOURCE_INPUT" ]]; then
        if [[ -f "$SOURCE_INPUT" ]] && [[ "$SOURCE_INPUT" == *.mrpack ]]; then
            MRPACK="$SOURCE_INPUT"
            echo "Using local .mrpack file: $MRPACK"
        elif [[ "$SOURCE_INPUT" =~ ^https?:// ]]; then
            PROJECT_SLUG=$(slug_from_modrinth_url "$SOURCE_INPUT")
            [[ -n "$PROJECT_SLUG" ]] || error "Could not determine Modrinth project slug from URL: $SOURCE_INPUT"
            echo "Resolved Modrinth project: $PROJECT_SLUG"
        else
            PROJECT_SLUG="$SOURCE_INPUT"
            echo "Using Modrinth project slug: $PROJECT_SLUG"
        fi
    fi

    if [[ -z "$MRPACK" ]]; then
        echo
        echo "Resolving Modrinth version..."

        VERSION=$(resolve_version "$PROJECT_SLUG" "$VERSION")

        echo
        echo "Using version:"
        echo "$VERSION"
        echo

        echo "Downloading Modrinth modpack..."

        MRPACK="$WORKDIR/modpack.mrpack"

        download_mrpack "$PROJECT_SLUG" "$VERSION" "$MRPACK"
    fi

    echo
    echo "Extracting modpack..."

    extract_mrpack "$MRPACK" "$WORKDIR"

    INDEX="$WORKDIR/modrinth.index.json"

    echo
    echo "Modpack information:"
    echo

    show_summary "$INDEX"

    assert_neoforge "$INDEX"
}

install_loader() {
    echo
    echo "Installing NeoForge..."

    install_neoforge "$INDEX" "$OUTPUT"
}

install_mods() {
    echo
    echo "Downloading mods..."

    export OUTPUT

    download_mods "$INDEX" "$OUTPUT"
}

patch_run_sh() {
    echo
    echo "Preparing server..."

    prepare_server "$OUTPUT"
}

run_build() {
    echo
    echo "Preparing workspace..."

    rm -rf "$WORKDIR"
    mkdir -p "$WORKDIR"
    mkdir -p "$OUTPUT"

    require curl
    require jq
    require unzip
    require java
    check_java

    download_pack
    install_loader
    install_mods
    patch_run_sh

    echo
    echo "Cleaning up..."
    cleanup_server "$OUTPUT"

    echo
    echo "======================================================="
    echo "Modpack server successfully created."
    echo
    echo "Location:"
    echo
    echo "  $OUTPUT"
    echo
    echo "Start:"
    echo
    echo "  cd \"$OUTPUT\""
    echo "  ./start.sh"
    echo
    echo "======================================================="
}


################################################################################
# Main
################################################################################

run_build
