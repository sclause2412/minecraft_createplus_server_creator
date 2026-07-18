#!/usr/bin/env bash

################################################################################
# NeoForge installation
################################################################################


################################################################################
# Extract NeoForge version
################################################################################

get_neoforge_version() {

    local index="$1"

    jq -r '
        .dependencies.neoforge
    ' "$index"

}


################################################################################
# Extract Minecraft version
################################################################################

get_minecraft_version() {

    local index="$1"

    jq -r '
        .dependencies.minecraft
    ' "$index"

}


################################################################################
# Download NeoForge installer
################################################################################

download_neoforge_installer() {

    local minecraft="$1"
    local neoforge="$2"
    local target="$3"


    local url

    url="https://maven.neoforged.net/releases/net/neoforged/neoforge/${neoforge}/neoforge-${neoforge}-installer.jar"


    echo
    echo "Downloading NeoForge installer"
    echo
    echo "$url"
    echo


    download_file \
        "$url" \
        "$target"

}


################################################################################
# Install server
################################################################################

install_neoforge() {

    local index="$1"
    local output="$2"


    local minecraft
    local neoforge


    minecraft=$(get_minecraft_version "$index")
    neoforge=$(get_neoforge_version "$index")


    [[ "$minecraft" != "null" ]] || \
        error "Minecraft version missing."


    [[ "$neoforge" != "null" ]] || \
        error "NeoForge version missing."


    echo
    echo "Minecraft : $minecraft"
    echo "NeoForge  : $neoforge"
    echo


    mkdir -p "$output"

    local cache_dir="$CACHE_DIR/neoforge/${minecraft}-${neoforge}"
    local stage_dir="$cache_dir.staging"

    if [[ -f "$cache_dir/run.sh" ]] && [[ -d "$cache_dir/libraries" ]]; then
        echo
        echo "Using cached NeoForge server installation: $cache_dir"
        echo
        cp -a "$cache_dir/." "$output/"
        echo
        echo "NeoForge installation complete."
        echo
        return 0
    fi

    rm -rf "$stage_dir"
    mkdir -p "$stage_dir"

    local installer

    installer="$stage_dir/neoforge-installer.jar"


    download_neoforge_installer \
        "$minecraft" \
        "$neoforge" \
        "$installer"


    echo
    echo "Installing NeoForge server..."
    echo


    (
        cd "$stage_dir"

        java \
            -jar "$installer" \
            --installServer
    )

    rm -f "$installer"

    mkdir -p "$cache_dir"
    cp -a "$stage_dir/." "$cache_dir/"
    cp -a "$cache_dir/." "$output/"
    rm -rf "$stage_dir"


    echo
    echo "NeoForge installation complete."
    echo

}


################################################################################
# Check installation
################################################################################

check_neoforge_installation() {

    local output="$1"


    [[ -f "$output/user_jvm_args.txt" ]] || \
        warn "user_jvm_args.txt missing"


    [[ -f "$output/run.sh" ]] || \
        warn "NeoForge run.sh missing"


}