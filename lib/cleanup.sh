#!/usr/bin/env bash

################################################################################
# Cleanup and diagnostics
################################################################################


################################################################################
# Remove temporary files
################################################################################

cleanup_files() {

    local output="$1"


    echo "Cleaning temporary files..."


    rm -f \
        "$output"/*.mrpack \
        "$output"/*installer*.jar \
        "$output"/installer.log \
        2>/dev/null || true


}


################################################################################
# Remove empty directories
################################################################################

cleanup_empty_dirs() {

    local output="$1"


    find "$output" \
        -type d \
        -empty \
        -delete

}


################################################################################
# Validate server structure
################################################################################

validate_server() {

    local output="$1"


    echo
    echo "Checking server..."
    echo


    local failed=0


    for file in \
        "mods" \
        "run.sh" \
        "user_jvm_args.txt" \
        "eula.txt"
    do

        if [[ ! -e "$output/$file" ]]; then

            echo "Missing: $file"
            failed=1

        else

            echo "OK: $file"

        fi

    done

    if [[ -d "$output/config" ]]; then
        echo "OK: config"
    else
        echo "Optional: config directory missing"
    fi


    if (( failed )); then
        error "Server validation failed."
    fi


}


################################################################################
# Detect suspicious client mods
################################################################################

scan_logs_for_client_mods() {

    local output="$1"


    local log="$output/logs/latest.log"


    [[ -f "$log" ]] || return


    echo
    echo "Possible client-only mods:"
    echo


    grep \
        -i \
        -E \
        "client-only|dedicated server|dist.*client|not valid for server" \
        "$log" \
        || true

}


################################################################################
# Complete cleanup
################################################################################

cleanup_server() {

    local output="$1"


    cleanup_files \
        "$output"


    cleanup_empty_dirs \
        "$output"


    validate_server \
        "$output"

}