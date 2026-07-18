#!/usr/bin/env bash

################################################################################
# Crash log parsing helpers
################################################################################

parse_crash_reasons() {
    local output="$1"
    local log_file="$2"

    local reasons=()

    if [[ -f "$log_file" ]]; then
        while IFS= read -r line; do
            case "$line" in
                *"Attempted to load class"*|*"NoClassDefFoundError"*|*"invalid dist"*|*"MixinTransformerError"*|*"ClassNotFoundException"*)
                    reasons+=("$line")
                    ;;
            esac
        done < "$log_file"
    fi

    if (( ${#reasons[@]} > 0 )); then
        printf '%s\n' "${reasons[@]}"
    fi
}

find_crash_log() {
    local output="$1"

    local candidate="$output/logs/latest.log"
    if [[ -f "$candidate" ]]; then
        echo "$candidate"
        return 0
    fi

    local crash_dir="$output/crash-reports"
    if [[ -d "$crash_dir" ]]; then
        find "$crash_dir" -maxdepth 1 -type f | sort | head -n 1
        return 0
    fi

    return 1
}
