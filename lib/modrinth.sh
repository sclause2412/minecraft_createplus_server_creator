#!/usr/bin/env bash

################################################################################
# Modrinth API
################################################################################

modrinth_versions() {

    local project="$1"

    http_get \
        "$API/project/$project/version"

}

################################################################################
# Resolve version
################################################################################

resolve_version() {

    local project="$1"
    local wanted="$2"

    local versions
    versions="$(modrinth_versions "$project")"

    if [[ "$wanted" == "latest" ]]; then

        echo "$versions" |
            jq -r '.[0].version_number'

        return
    fi

    echo "$versions" |
        jq -e --arg version "$wanted" '
            .[]
            | select(.version_number==$version)
            | .version_number
        ' >/dev/null || error "Version '$wanted' not found."

    echo "$wanted"

}

################################################################################
# Version JSON
################################################################################

version_json() {

    local project="$1"
    local version="$2"

    modrinth_versions "$project" |
        jq \
        --arg version "$version" '
            .[]
            | select(.version_number==$version)
        '

}

################################################################################
# Download MRPACK
################################################################################

download_mrpack() {

    local project="$1"
    local version="$2"
    local outfile="$3"

    local url

    url=$(
        version_json "$project" "$version" |
        jq -r '.files[0].url'
    )

    [[ -z "$url" ]] && error "Could not locate MRPACK."

    download_file \
        "$url" \
        "$outfile"

}

################################################################################
# Extract
################################################################################

extract_mrpack() {

    local mrpack="$1"
    local workdir="$2"

    unzip \
        -q \
        "$mrpack" \
        -d "$workdir"

}

################################################################################
# Metadata
################################################################################

minecraft_version() {

    local index="$1"

    jq -r '
        .dependencies.minecraft
    ' "$index"

}

################################################################################

loader_name() {

    local index="$1"

    jq -r '
        keys_unsorted as $k
        | .dependencies
        | keys[]
        | select(. != "minecraft")
    ' "$index"

}

################################################################################

loader_version() {

    local index="$1"

    jq -r '
        .dependencies
        | to_entries[]
        | select(.key!="minecraft")
        | .value
    ' "$index"

}

################################################################################
# File count
################################################################################

mod_count() {

    local index="$1"

    jq '
        .files
        | length
    ' "$index"

}

################################################################################
# Print all files
################################################################################

list_files() {

    local index="$1"

    jq -c '
        .files[]
    ' "$index"

}

################################################################################
# Overrides
################################################################################

copy_overrides() {

    local workdir="$1"
    local output="$2"

    if [[ ! -d "$workdir/overrides" ]]; then
        return
    fi

    cp \
        -a \
        "$workdir/overrides/." \
        "$output/"

}

################################################################################
# Loader sanity
################################################################################

assert_neoforge() {

    local loader

    loader=$(loader_name "$1")

    [[ "$loader" == "neoforge" ]] || \
        error "This modpack does not use NeoForge."

}

################################################################################
# Show summary
################################################################################

show_summary() {

    local index="$1"

    log "Minecraft: $(minecraft_version "$index")"
    log "Loader: $(loader_name "$index")"
    log "Loader version: $(loader_version "$index")"
    log "Mods: $(mod_count "$index")"

}

################################################################################
# Download list
#
# Ausgabe:
#
# path<TAB>sha1<TAB>sha512<TAB>url
#
################################################################################

download_table() {

    local index="$1"

    jq -r '

        .files[]

        |

        [
            .path,

            .hashes.sha1,

            .hashes.sha512,

            .downloads[0],

            .env.server

        ]

        | @tsv

    ' "$index"

}