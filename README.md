# Modrinth Modpack Server Builder

A small Bash-based builder for creating a dedicated NeoForge server from a Modrinth modpack source.

This project is completely (=100%) built by AI (GitHub Copilot, ChatGPT), so please forgive if there is some strange behavior.

## Overview

This project accepts a Modrinth modpack URL, a project slug, or a local `.mrpack` file and builds a dedicated NeoForge server from it. It downloads the modpack, checks that the pack uses NeoForge, installs NeoForge, downloads the required mods, prepares the server files, and generates startup scripts that use the detected Java runtime.

## Features

- Accepts a Modrinth modpack URL, slug, or local `.mrpack` file
- Downloads the requested Modrinth modpack version
- Verifies that the modpack uses NeoForge
- Installs NeoForge for the target Minecraft version
- Downloads mods into the server tree
- Copies supported overrides
- Generates startup scripts for the final server
- Uses a cache directory to reuse downloaded files where possible

## Requirements

- Bash
- curl
- jq
- unzip
- Java 21

## Usage

Run the builder with one of the supported input formats:

```bash
./create-modrinth-server.sh https://modrinth.com/modpack/example-mod
./create-modrinth-server.sh example-mod
./create-modrinth-server.sh ./example-mod.mrpack
```

Optional version selection:

```bash
./create-modrinth-server.sh example-mod --version latest
```

The generated server is placed in the `server/` directory.

## Project Structure

- `create-modrinth-server.sh` - main entry point
- `lib/` - helper scripts for downloads, Java detection, NeoForge setup, server preparation, and filters
- `server/` - generated server output
- `cache/` - reusable download cache

## License

This project is licensed under the GNU General Public License v3.0 (GPL-3.0).

See the [LICENSE](LICENSE) file for details.
