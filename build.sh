#!/bin/bash

# Whirligig Warrior Build Script
# Increments buildNumber in pdxinfo and compiles the project.

PDXINFO="Source/pdxinfo"

if [ ! -f "$PDXINFO" ]; then
    echo "Error: $PDXINFO not found."
    exit 1
fi

# Extract and increment buildNumber
CURRENT_BUILD=$(grep "buildNumber=" "$PDXINFO" | cut -d'=' -f2)
NEW_BUILD=$((CURRENT_BUILD + 1))

# Update pdxinfo
sed -i "s/buildNumber=$CURRENT_BUILD/buildNumber=$NEW_BUILD/" "$PDXINFO"

echo "Incremented buildNumber to $NEW_BUILD"

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
