#!/usr/bin/env bash

################################################################################
# Java version handling
################################################################################

REQUIRED_JAVA_MAJOR=21


################################################################################
# Find Java 21
################################################################################

find_java() {

    local candidates=()


    #
    # Arch Linux
    #

    if command -v archlinux-java >/dev/null 2>&1; then

        candidates+=(
            "/usr/lib/jvm/java-21-openjdk/bin/java"
        )

    fi


    #
    # Generic Linux locations
    #

    candidates+=(
        "/usr/lib/jvm/java-21-openjdk/bin/java"
        "/usr/lib/jvm/java-21-openjdk-amd64/bin/java"
        "/usr/lib/jvm/jdk-21/bin/java"
    )


    for candidate in "${candidates[@]}"
    do

        if [[ -x "$candidate" ]]
        then
            echo "$candidate"
            return 0
        fi

    done


    return 1

}


################################################################################
# Extract major version
################################################################################

java_major_version() {

    local java_bin="$1"


    "$java_bin" -version 2>&1 |
    awk -F '"' '
        /version/ {
            split($2,a,".");
            if (a[1]=="1")
                print a[2];
            else
                print a[1];
        }
    '

}


################################################################################
# Validate Java
################################################################################

check_java() {

    local java_bin


    java_bin=$(find_java) || {

        error "
Java 21 was not found.

Install it with:

sudo pacman -S jdk21-openjdk

"

    }


    local version

    version=$(java_major_version "$java_bin")


    if [[ "$version" != "$REQUIRED_JAVA_MAJOR" ]]
    then

        error "
Wrong Java version.

Found:
$java_bin
Java $version

Required:
Java $REQUIRED_JAVA_MAJOR

"

    fi


    export SERVER_JAVA="$java_bin"


    echo
    echo "Using Java:"
    echo "$SERVER_JAVA"
    echo

}