#!/usr/bin/env bash

set -euo pipefail

################################################################################
# Globals
################################################################################

API="https://api.modrinth.com/v2"
CACHE_DIR="${CACHE_DIR:-${SCRIPT_DIR:-$PWD}/cache}"

################################################################################
# Colors
################################################################################

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
RESET="\033[0m"

################################################################################
# Logging
################################################################################

log() {
    printf "${GREEN}==>${RESET} %s\n" "$*"
}

warn() {
    printf "${YELLOW}==>${RESET} %s\n" "$*" >&2
}

error() {
    printf "${RED}ERROR:${RESET} %s\n" "$*" >&2
    exit 1
}

################################################################################
# Requirements
################################################################################

require() {

    command -v "$1" >/dev/null 2>&1 || \
        error "Required program '$1' is missing."

}

################################################################################
# HTTP
################################################################################

http_get() {

    echo $1 >&2


    curl \
        --fail \
        --silent \
        --show-error \
        --location \
        "$1"

}

################################################################################
# Download
################################################################################

download_file() {

    local url="$1"
    local outfile="$2"

    local cache_file
    cache_file=$(cache_path_for "$outfile" "" "" "$url")

    mkdir -p "$(dirname "$outfile")"

    if [[ -f "$cache_file" ]]; then
        cp "$cache_file" "$outfile"
        echo "CACHE $outfile"
        return 0
    fi

    local temp_file
    temp_file=$(mktemp)

    curl \
        --fail \
        --location \
        --progress-bar \
        "$url" \
        -o "$temp_file"

    mkdir -p "$(dirname "$cache_file")"
    mv "$temp_file" "$cache_file"
    cp "$cache_file" "$outfile"

}

################################################################################
# JSON helper
################################################################################

json() {

    jq -r "$1"

}

################################################################################
# SHA512
################################################################################

sha512() {

    if command -v sha512sum >/dev/null; then
        sha512sum "$1" | awk '{print $1}'
        return
    fi

    if command -v shasum >/dev/null; then
        shasum -a 512 "$1" | awk '{print $1}'
        return
    fi

    error "No SHA512 utility found."

}

################################################################################
# SHA1
################################################################################

sha1() {

    if command -v sha1sum >/dev/null; then
        sha1sum "$1" | awk '{print $1}'
        return
    fi

    if command -v shasum >/dev/null; then
        shasum -a 1 "$1" | awk '{print $1}'
        return
    fi

    error "No SHA1 utility found."

}

################################################################################
# Verify hashes
################################################################################

verify_sha512() {

    local file="$1"
    local expected="$2"

    local got
    got=$(sha512 "$file")

    [[ "$got" == "$expected" ]]

}

verify_sha1() {

    local file="$1"
    local expected="$2"

    local got
    got=$(sha1 "$file")

    [[ "$got" == "$expected" ]]

}

################################################################################
# Filesystem
################################################################################

ensure_dir() {

    mkdir -p "$1"

}

################################################################################
# Cache helpers
################################################################################

cache_root() {

    mkdir -p "$CACHE_DIR"
    echo "$CACHE_DIR"

}

cache_path_for() {

    local path="$1"
    local sha1_expected="$2"
    local sha512_expected="$3"
    local url="$4"

    local key=""
    local safe_path

    if [[ -n "$sha512_expected" ]]; then
        key="$sha512_expected"
    elif [[ -n "$sha1_expected" ]]; then
        key="$sha1_expected"
    else
        key=$(printf '%s' "$url" | sha256sum | awk '{print $1}')
    fi

    safe_path="${path//\//__}"

    echo "$(cache_root)/${key}-${safe_path}"

}

################################################################################
# Temp file
################################################################################

tmpfile() {

    mktemp

}

################################################################################
# CPU count
################################################################################

cpu_count() {

    if command -v nproc >/dev/null; then
        nproc
        return
    fi

    getconf _NPROCESSORS_ONLN

}

################################################################################
# Parallel download jobs
################################################################################

download_jobs() {

    local cpus
    cpus=$(cpu_count)

    if (( cpus < 2 )); then
        echo 2
    elif (( cpus > 16 )); then
        echo 16
    else
        echo "$cpus"
    fi

}