#!/usr/bin/env bash

################################################################################
# Mod lookup helpers
################################################################################

normalize_name() {
    local value="$1"

    value="${value,,}"
    value="${value//[._-]/ }"
    value="${value//[^a-z0-9]/ }"
    value=$(echo "$value" | tr -s ' ')
    value="${value# }"
    value="${value% }"

    echo "$value"
}

mod_display_name() {
    local path="$1"
    local name

    name="$(basename "$path")"
    name="${name%.jar}"

    echo "$name"
}

lookup_mod_file() {
    local output="$1"
    local context="$2"

    local mods_dir="$output/mods"
    local candidate=""

    [[ -d "$mods_dir" ]] || return 1

    local normalized_context
    normalized_context=$(normalize_name "$context")

    while IFS= read -r jar_path; do
        local jar_name
        jar_name="$(basename "$jar_path")"

        local normalized_jar
        normalized_jar=$(normalize_name "$jar_name")

        if [[ -z "$normalized_context" ]]; then
            echo "$jar_path"
            return 0
        fi

        if [[ "$normalized_jar" == *"$normalized_context"* ]] || [[ "$normalized_context" == *"$normalized_jar"* ]]; then
            echo "$jar_path"
            return 0
        fi

        local tokens
        tokens=$(echo "$normalized_context" | tr ' ' '\n' | awk 'length($0) > 3' | sort -u | tr '\n' ' ')

        for token in $tokens; do
            if [[ "$normalized_jar" == *"$token"* ]]; then
                echo "$jar_path"
                return 0
            fi
        done
    done < <(find "$mods_dir" -maxdepth 1 -type f -name '*.jar' | sort)

    return 1
}
