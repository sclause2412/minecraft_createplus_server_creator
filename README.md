# Create+ Server Builder

A small Bash-based builder for creating a dedicated NeoForge server from a Create+ Modrinth pack.

This project is completely (=100%) built by AI (Github Copilot, ChatGPT), so please forgive if their is some strange behavior.

## Overview

This project downloads a Create+ modpack, installs NeoForge, downloads the required mods, prepares the server files, and generates startup scripts that use the detected Java runtime.

## Features

- Downloads the requested Modrinth modpack version
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
- Java (correct version for server will be detected)

## Usage

Run the builder:

```bash
./createplus-server.sh --version <version>
```

Example:

```bash
./createplus-server.sh --version latest
```

The generated server is placed in the `server/` directory.

## Project Structure

- `createplus-server.sh` - main entry point
- `lib/` - helper scripts for downloads, Java detection, NeoForge setup, server preparation, and filters
- `server/` - generated server output
- `cache/` - reusable download cache

## License

This project is licensed under the GNU General Public License v3.0 (GPL-3.0).

See the [LICENSE](LICENSE) file for details.
