
# take_snapshots.sh

A script to take snapshots from video files at random times, with options for color space handling, custom times, and output directories. The script uses `ffmpeg` and `ffprobe`.

![ShellCheck](https://github.com/basilius-bz/take-snapshots/actions/workflows/shellcheck.yml/badge.svg) ![Version](https://img.shields.io/badge/version-0.2-blue.svg)


The "randomness" of the times is between the 5%-35% of total run time.

I knocked this together very quickly, and it definitely is not best practices. Probably (definitely) very buggy, but it generally works.

This script was developed based on the information provided on [Rendezvous Video Screenshots](https://rendezvois.github.io/video/screenshots/programs-choices/) and various other online resources.

Contributions are welcome! Please open an issue or submit a pull request for any improvements or bug fixes.

- Basilius - BZ

## Features

- Randomly takes snapshots from video files
- Allows specifying the number of snapshots
- Supports forcing specific color formats (BT.709, BT.601, BT.2020)
- Option to remove pixel format for 16bit PNG support
- Customizable output directory and filename prefix
- Debug mode for detailed command outputs
- Silent mode to suppress output and only print filenames (useful to pipe into other scripts)
- Detailed console messaging for each action taken
- Resolution checks to ensure snapshot resolution matches video resolution

## Requirements

- `ffmpeg` and `ffprobe` must be installed on your system.

## Installation

1. Ensure `ffmpeg` and `ffprobe` are installed. You can install them using your package manager. For example, on deb systems:

   ```bash
   sudo apt update
   sudo apt install ffmpeg
   ```

2. Download the script using curl:

   ```bash
   curl -o take_snapshots.sh https://raw.githubusercontent.com/basilius-bz/take-snapshots/main/take_snapshots.sh
   chmod +x take_snapshots.sh
   ```

## Usage

```bash
./take_snapshots.sh [OPTIONS] <video_file>
```

### Options

- `-h, --help`              Show the help message and exit
- `-v, --version`           Show the script version
- `-n, --num-screenshots`   Number of screenshots to take (default: 3)
- `-f, --force-format`      Force specific color format (bt709, bt601, bt2020)
- `-r, --remove-pixfmt`     Remove `-pix_fmt rgb24` to allow 16bit PNG
- `-d, --directory`         Directory to save snapshots (Default: Current directory)
- `-p, --prefix`            Prefix for snapshot filenames (default: snapshots)
- `-s, --silent`            Suppress output and only print filenames at the end
- `--debug`                 Enable debug mode to show detailed command outputs

### Example

```bash
./take_snapshots.sh -n 5 -f bt709 -r -d /path/to/save -p myprefix --silent --debug video.mkv
```

This command will take 5 snapshots from `video.mkv`, force the color format to BT.709, remove the pixel format option, save the snapshots to `/path/to/save` with filenames prefixed with `myprefix`, enable silent mode to suppress output and only print filenames, and enable debug mode.

### Release Notes

#### Version 0.2
- Added `--silent` mode to suppress output and only print filenames.
- Enhanced detailed console messaging to indicate the progress and actions being taken.
- Implemented resolution checks to ensure snapshot resolution matches the video resolution.
- Improved error handling and added `set -e` to exit immediately if a command exits with a non-zero status.
- Added long-form options for all command-line arguments.
- Improved help menu to reflect long-form options.
- Added shellcheck 

#### Version 0.1
- Initial release of the script.
- Features included taking random snapshots, specifying number of snapshots, forcing color formats, removing pixel format for 16bit PNG, customizable output directory and filename prefix, and debug mode for detailed command outputs.
