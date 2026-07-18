#!/usr/bin/env bash

################################################################################
# Mod downloads
################################################################################

################################################################################
# Download one file
#
# Input:
# path
# sha1
# sha512
# url
################################################################################

download_one() {

    local path="$1"
    local sha1_expected="$2"
    local sha512_expected="$3"
    local url="$4"

    local target="$OUTPUT/$path"

    local directory
    directory=$(dirname "$target")

    mkdir -p "$directory"


    #
    # Already exists?
    #

    if [[ -f "$target" ]]; then

        if [[ -n "$sha512_expected" ]] &&
           verify_sha512 "$target" "$sha512_expected"
        then
            echo "OK   $path"
            return
        fi


        if [[ -n "$sha1_expected" ]] &&
           verify_sha1 "$target" "$sha1_expected"
        then
            echo "OK   $path"
            return
        fi

        echo "BAD  $path (redownload)"

        rm -f "$target"

    fi


    local cache_file
    cache_file=$(cache_path_for "$path" "$sha1_expected" "$sha512_expected" "$url")

    if [[ -f "$cache_file" ]]; then
        if [[ -n "$sha512_expected" ]] && verify_sha512 "$cache_file" "$sha512_expected"; then
            cp "$cache_file" "$target"
            echo "CACHE $path"
            return 0
        fi

        if [[ -n "$sha1_expected" ]] && verify_sha1 "$cache_file" "$sha1_expected"; then
            cp "$cache_file" "$target"
            echo "CACHE $path"
            return 0
        fi
    fi


    #
    # Download
    #

    echo "GET  $path"

    local temp_file
    temp_file=$(mktemp)

    curl \
        --fail \
        --location \
        --silent \
        --show-error \
        "$url" \
        -o "$temp_file"

    mkdir -p "$(dirname "$cache_file")"
    mv "$temp_file" "$cache_file"
    cp "$cache_file" "$target"


    #
    # Verify
    #

    if [[ -n "$sha512_expected" ]]; then

        verify_sha512 \
            "$target" \
            "$sha512_expected" \
        || error "SHA512 failed: $path"

    elif [[ -n "$sha1_expected" ]]; then

        verify_sha1 \
            "$target" \
            "$sha1_expected" \
        || error "SHA1 failed: $path"

    fi


}


################################################################################
# Worker wrapper
################################################################################

download_worker() {

    local line="$1"

    IFS=$'\t' read -r \
        path \
        sha1 \
        sha512 \
        url \
        <<< "$line"


    download_one \
        "$path" \
        "$sha1" \
        "$sha512" \
        "$url"

}


################################################################################
# Download all files
################################################################################

download_mods() {

    local index="$1"
    local output="$2"

    export OUTPUT="$output"


    local count
    count=$(mod_count "$index")

    echo
    echo "Files to download: $count"
    echo


    while IFS=$'\t' read -r path sha1 sha512 url
    do

        download_one \
            "$path" \
            "$sha1" \
            "$sha512" \
            "$url"

    done < <(filter_download_table "$index")

}