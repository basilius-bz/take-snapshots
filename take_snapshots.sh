#!/bin/bash

###############################################################################
# Script: take_snapshots.sh
# Version: 0.1
# Author: Basilius
# Description: A script to take snapshots from video files at random times,
#              with options for color space handling, and output
#              directories. The script uses ffmpeg and ffprobe.
# Guidance:    The script was developed based upon the info provided on
#              https://rendezvois.github.io/video/screenshots/programs-choices/
#              as well as other various online resources.
#           
#
###############################################################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Version information
SCRIPT_VERSION="0.1"

# Default values
NUM_SCREENSHOTS=3
FORCE_FORMAT=""
REMOVE_PIXFMT=false
OUTPUT_DIR=$(pwd)
PREFIX="snapshot"
DEBUG=false

# Display help menu
function display_help() {
  echo -e "${CYAN}Usage: $0 [OPTIONS] <video_file>${NC}"
  echo
  echo -e "${CYAN}Options:${NC}"
  echo -e "  ${YELLOW}-h, --help${NC}            Show this help message and exit"
  echo -e "  ${YELLOW}-v, --version${NC}         Show script version"
  echo -e "  ${YELLOW}-n, --num-screenshots${NC} Number of screenshots to take (default: 3)"
  echo -e "  ${YELLOW}-f, --force-format${NC}    Force specific color format (bt709, bt601, bt2020)"
  echo -e "  ${YELLOW}-r, --remove-pixfmt${NC}   Remove -pix_fmt rgb24 to allow 16bit PNG (allow)"
  echo -e "  ${YELLOW}-d, --directory${NC}       Directory to save snapshots (Default: Current directory)"
  echo -e "  ${YELLOW}-p, --prefix${NC}          Prefix for snapshot filenames"
  echo -e "  ${YELLOW}--debug${NC}               Enable debug mode to show detailed command outputs"
  echo
  echo -e "${CYAN}Example:${NC}"
  echo -e "  $0 -n 5 -f bt709 -r -d /path/to/save -p myprefix --debug video.mkv"
  exit 0
}

# Display version information
function display_version() {
  echo -e "${GREEN}take_snapshots.sh version $SCRIPT_VERSION${NC}"
  exit 0
}

# Check if ffmpeg is installed
function check_ffmpeg_installed() {
  if ! command -v ffmpeg &> /dev/null; then
    echo -e "${RED}ffmpeg could not be found. Please install ffmpeg to use this script.${NC}"
    exit 1
  fi
}

# Check for video color space using ffprobe
function check_color_space() {
  echo -e "${CYAN}Determining color space...${NC}"
  local probe_command="ffprobe -v error -select_streams v:0 -show_entries stream=color_space,color_primaries,color_transfer -of default=nw=1 \"$1\""
  
  if [ "$DEBUG" = true ]; then
    COLOR_INFO=$(eval $probe_command)
  else
    COLOR_INFO=$(eval $probe_command 2>/dev/null)
  fi

  if [ -z "$COLOR_INFO" ]; then
    echo -e "${RED}Error determining color space. Make sure the video file is valid.${NC}"
    exit 1
  fi

  if echo "$COLOR_INFO" | grep -q "bt709"; then
    echo -e "${GREEN}The video uses BT.709 color space.${NC}"
    COLOR_SPACE="bt709"
  elif echo "$COLOR_INFO" | grep -q "smpte170m"; then
    echo -e "${GREEN}The video uses BT.601 color space.${NC}"
    COLOR_SPACE="bt601"
  elif echo "$COLOR_INFO" | grep -q "bt2020"; then
    echo -e "${GREEN}The video uses BT.2020 color space.${NC}"
    COLOR_SPACE="bt2020"
  else
    echo -e "${YELLOW}The color space of the video is not explicitly BT.709, BT.601, or BT.2020.${NC}"
    COLOR_SPACE="unknown"
  fi
}

# Convert seconds to HH:MM:SS.mmm format
function convert_time_format() {
  local time=$1
  printf '%02d:%02d:%02d.000' $((time/3600)) $((time%3600/60)) $((time%60))
}

# Get the duration of the video file
function get_video_duration() {
  local duration
  duration=$(ffprobe -v error -select_streams v:0 -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$1")
  echo ${duration%.*}
}

# Generate sufficiently spaced random times
function generate_random_times() {
  local duration=$1
  local start_time=$((duration / 20))   # 5% of the total duration
  local end_time=$((duration * 35 / 100))  # 35% of the total duration
  local interval=$(( (end_time - start_time) / (NUM_SCREENSHOTS + 1) )) # Ensuring sufficient space between times

  local times=()
  local last_time=$start_time

  for ((i=0; i<NUM_SCREENSHOTS; i++)); do
    local random_time=$((last_time + interval + RANDOM % (interval - 1)))
    times+=($random_time)
    last_time=$random_time
  done

  echo "${times[@]}"
}

# Function to take a snapshot at a specified time
function take_snapshot() {
  local time=$1
  local formatted_time=$(convert_time_format "$time")

  local ffmpeg_cmd="ffmpeg -loglevel error -ss $formatted_time -i \"$VIDEO_FILE\" -vf \"scale='max(sar,1)*iw':'max(1/sar,1)*ih':in_h_chr_pos=0:in_v_chr_pos=128:in_color_matrix=$COLOR_SPACE:flags=full_chroma_int+full_chroma_inp+accurate_rnd+spline\""

  if [ "$REMOVE_PIXFMT" = false ]; then
    ffmpeg_cmd+=" -pix_fmt rgb24"
  fi

  ffmpeg_cmd+=" -vframes 1 \"$OUTPUT_DIR/${PREFIX}_${time}.png\""

  if [ "$DEBUG" = true ]; then
    echo -e "${CYAN}Executing command:${NC} $ffmpeg_cmd"
  fi
  eval $ffmpeg_cmd

  if [ $? -ne 0 ]; then
    echo -e "${RED}Error taking snapshot at $time seconds${NC}"
  else
    echo -e "${GREEN}Snapshot taken at $time seconds${NC}"
  fi
}

# Display starting message
echo -e "${BLUE}Starting take_snapshots.sh...${NC}"
echo -e "${BLUE}This script takes snapshots from video files at random times within a specified range.${NC}"

# Parse command-line arguments
while getopts ":hv:n:f:rd:p:-:" opt; do
  case ${opt} in
    h ) display_help ;;
    v ) display_version ;;
    n ) NUM_SCREENSHOTS=$OPTARG ;;
    f ) FORCE_FORMAT=$OPTARG ;;
    r ) REMOVE_PIXFMT=true ;;
    d ) OUTPUT_DIR=$OPTARG ;;
    p ) PREFIX=$OPTARG ;;
    - )
      case "${OPTARG}" in
        help) display_help ;;
        version) display_version ;;
        num-screenshots) NUM_SCREENSHOTS="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 )) ;;
        force-format) FORCE_FORMAT="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 )) ;;
        remove-pixfmt) REMOVE_PIXFMT=true ;;
        directory) OUTPUT_DIR="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 )) ;;
        prefix) PREFIX="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 )) ;;
        debug) DEBUG=true ;;
        *) echo -e "${RED}Unknown option --${OPTARG}${NC}" >&2; display_help ;;
      esac ;;
    \? ) echo -e "${RED}Invalid option: -$OPTARG${NC}" >&2; display_help ;;
    : ) echo -e "${RED}Invalid option: -$OPTARG requires an argument${NC}" >&2; display_help ;;
  esac
done
shift $((OPTIND -1))

VIDEO_FILE="$1"

# Check if video file is provided
if [ -z "$VIDEO_FILE" ]; then
  echo -e "${RED}Error: No video file provided.${NC}"
  display_help
fi

# Check if ffmpeg is installed
check_ffmpeg_installed

# Get video duration
DURATION=$(get_video_duration "$VIDEO_FILE")
if [ -z "$DURATION" ]; then
  echo -e "${RED}Error: Could not determine video duration.${NC}"
  exit 1
fi

# Check the color space of the video
if [ -n "$FORCE_FORMAT" ]; then
  COLOR_SPACE="$FORCE_FORMAT"
  echo -e "${YELLOW}Forcing color space to $FORCE_FORMAT.${NC}"
else
  check_color_space "$VIDEO_FILE"
fi

# Generate random times within the duration range
TIMES=$(generate_random_times "$DURATION")
read -r -a TIMES_ARRAY <<< "$TIMES"

# Take snapshots at the generated random times
for TIME in "${TIMES_ARRAY[@]}"; do
  take_snapshot "$TIME"
  sleep 1
done

echo -e "${CYAN}Snapshots taken at ${TIMES_ARRAY[*]} seconds in the directory $OUTPUT_DIR.${NC}"
