#!/usr/bin/env bash

# Script to set wallpaper and generate color palette using wal

WALLPAPER_PATH="$1"

# Check if a wallpaper path was provided
if [ -z "$WALLPAPER_PATH" ]; then
  echo "Usage: $0 <path_to_wallpaper>"
  exit 1
fi

# Check if the wallpaper file exists
if [ ! -f "$WALLPAPER_PATH" ]; then
  echo "Error: Wallpaper file not found at $WALLPAPER_PATH"
  exit 1
fi

# Check if the wallpaper is in the wallpapers directory
if [[ "$WALLPAPER_PATH" != "$HOME/dotfiles/wallpapers"* ]]; then
  echo "Warning: Wallpaper file is not in the expected wallpapers directory ($HOME/dotfiles/wallpapers)."
  # Decide if you want to exit or continue. For now, let's continue but warn.
fi

echo "Setting wallpaper and generating color palette for $WALLPAPER_PATH..."

# Run wal to set the wallpaper and generate the color palette
# The -R flag reloads the current theme after generating
wal -i "$WALLPAPER_PATH" -R

echo "Color palette generated and applied."
echo "Configuration files are in ~/.cache/wal/"

# You might need to add commands here to reload specific applications
# For example:
# hyprctl reload # Reload Hyprland
# killall waybar && waybar & # Restart Waybar
# For Rofi and Lvim, they usually read the config when launched or sourced.

exit 0

