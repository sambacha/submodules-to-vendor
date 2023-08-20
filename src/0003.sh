#!/usr/bin/env bash

set -e

# Check if .gitmodules exists
if [[ ! -f ".gitmodules" ]]; then
  echo "⛔️ Error: .gitmodules file not found in the current directory."
  exit 1
fi

# Output file
output_file="subtree_commands_$(date +%s).txt"

# Clear/initialize the output file
: >"$output_file"

# Parse the .gitmodules file
while IFS= read -r line; do
  if [[ "$line" == '[submodule'* ]]; then
    unset name
    unset path
    unset url
  elif [[ "$line" == *'path = '* ]]; then
    path=$(echo "$line" | cut -d'=' -f 2 | xargs)
  elif [[ "$line" == *'url = '* ]]; then
    url=$(echo "$line" | cut -d'=' -f 2 | xargs)

    # If both path and url are set, get the hash using git submodule status
    if [[ -n "$path" && -n "$url" ]]; then
      #hash=$(git submodule status --cached "$path" | cut -d' ' -f2)
      #hash=$(git submodule status --cached | cut -c 2-41)
      hash=$(git submodule status --cached | cut -d' ' -f1 | cut -c 2-41)
      # Assert if the hash is empty or not found
      if [[ -z "$hash" ]]; then
        echo "⛔️ Error: Could not find hash for submodule at path $path."
        exit 1
      fi
      # Write the git subtree add command to the output file
      echo "git subtree add --prefix=$path $url $hash" >>"$output_file"
    fi
  fi
done <.gitmodules
sed -i -r 's/.{10}//'
echo "Commands written to $output_file"

exit 0
