#!/bin/bash

# Whirligig Warrior Build Script
# Sets buildNumber in pdxinfo based on Git commit count and compiles the project.

PDXINFO="Source/pdxinfo"

if [ ! -f "$PDXINFO" ]; then
    echo "Error: $PDXINFO not found."
    exit 1
fi

# Calculate buildNumber from Git commit count
# If not in a git repo, defaults to 0
if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    NEW_BUILD=$(git rev-list --count HEAD)
else
    NEW_BUILD=0
fi

# Extract current buildNumber from file
CURRENT_BUILD=$(grep "buildNumber=" "$PDXINFO" | cut -d'=' -f2)

# Update pdxinfo for the build
sed -i "s/buildNumber=$CURRENT_BUILD/buildNumber=$NEW_BUILD/" "$PDXINFO"

echo "Build Number (Commit Count): $NEW_BUILD"

# Compile the project
if [ -z "$PLAYDATE_SDK_PATH" ]; then
    export PLAYDATE_SDK_PATH=~/PlaydateSDK
fi

export PATH=$PATH:$PLAYDATE_SDK_PATH/bin

pdc Source WhirligigWarrior.pdx

if [ $? -eq 0 ]; then
    echo "Build successful: WhirligigWarrior.pdx"
else
    echo "Build failed."
    exit 1
fi
