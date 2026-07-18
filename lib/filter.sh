#!/usr/bin/env bash

################################################################################
# Mod server compatibility filter
################################################################################


FILTER_CACHE="$PWD/.modrinth-filter-cache"


################################################################################
# Cache vorbereiten
################################################################################

init_filter_cache() {

    mkdir -p "$FILTER_CACHE"

}


################################################################################
# Modrinth Projekt-ID aus Datei extrahieren
################################################################################

get_project_id_from_file() {

    local path="$1"

    # Modrinth-Dateinamen enthalten die ID nicht immer.
    # Wir nutzen deshalb die URL aus dem Index.

    echo "$path"

}


################################################################################
# Modrinth Metadaten laden
################################################################################

get_project_metadata() {

    local project_id="$1"

    local cache="$FILTER_CACHE/$project_id.json"

    http_get \
        "$API/project/$project_id" \
        > "$cache" || true

    cat "$cache"

}


################################################################################
# Prüfen ob Mod serverfähig ist
################################################################################

is_server_supported() {

    local server_side="$1"

    case "$server_side" in
        unsupported)
            return 1
            ;;
        required)
            return 0
            ;;
        optional)
            return 0
            ;;
        *)
            return 1
            ;;
    esac

}


################################################################################
# Liste der herunterzuladenden Dateien filtern
################################################################################

filter_download_table() {

    local index="$1"


    init_filter_cache


    while IFS=$'\t' read -r path sha1 sha512 url server
    do

        #
        # Nur Mods filtern
        #

        if [[ "$path" != mods/*.jar ]]; then

            echo -e "$path\t$sha1\t$sha512\t$url"
            continue

        fi

        if is_server_supported "$server"; then

            echo -e "$path\t$sha1\t$sha512\t$url"

        else

            echo "Skipping client-only mod: $path" >&2

        fi


    done < <(download_table "$index")

}