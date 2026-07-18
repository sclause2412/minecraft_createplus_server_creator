#!/usr/bin/env bash

################################################################################
# Automatic server repair loop
################################################################################

start_server() {
    local output="$1"

    echo
    echo "Starting server..."
    echo

    (
        cd "$output"
        ./start.sh
    )
}

remove_mod() {
    local output="$1"
    local mod_path="$2"
    local reason="$3"

    local mod_name
    mod_name=$(basename "$mod_path")
    local disabled_dir="$output/mods.disabled"
    mkdir -p "$disabled_dir"

    if [[ -f "$disabled_dir/$mod_name" ]]; then
        return 0
    fi

    mv "$mod_path" "$disabled_dir/$mod_name"

    cat >> "$output/removed-mods.txt" <<EOF
$mod_name
Grund:
$reason

--------------------------------

EOF
}

parse_server_failure() {
    local output="$1"
    local log_file="$2"

    local reasons
    reasons=$(parse_crash_reasons "$output" "$log_file")

    if [[ -n "$reasons" ]]; then
        echo "$reasons" | head -n 10
        return 0
    fi

    echo "Unbekannter Server-Fehler"
}

retry_server() {
    local output="$1"
    local max_attempts="${2:-8}"

    local attempt=1
    local removed_any=0

    : > "$output/removed-mods.txt"

    while (( attempt <= max_attempts )); do
        echo
        echo "Attempt $attempt/$max_attempts"
        echo

        if start_server "$output"; then
            echo "Server started successfully."
            return 0
        fi

        local log_file
        log_file=$(find_crash_log "$output") || true

        if [[ -z "$log_file" ]]; then
            echo "No crash log found."
            return 1
        fi

        echo "Crash detected. Investigating $log_file"

        local crash_summary
        crash_summary=$(parse_server_failure "$output" "$log_file")

        local candidate=""
        if [[ -f "$log_file" ]]; then
            candidate=$(grep -oE '[A-Za-z0-9_.-]+(\\.[A-Za-z0-9_.-]+)+' "$log_file" | head -n 10 | tr '\n' ' ' || true)
        fi

        local context=""
        if [[ -n "$candidate" ]]; then
            context="$candidate"
        else
            context="client"
        fi

        local mod_file
        mod_file=$(lookup_mod_file "$output" "$context") || true

        if [[ -n "$mod_file" ]]; then
            echo "Removing suspected mod: $(basename "$mod_file")"
            remove_mod "$output" "$mod_file" "$crash_summary"
            removed_any=1
        else
            echo "No matching mod found for context: $context"
            break
        fi

        ((attempt+=1))
    done

    if (( removed_any == 0 )); then
        echo "No mods were disabled."
        return 1
    fi

    echo "Automatic repair loop finished."
    return 1
}
