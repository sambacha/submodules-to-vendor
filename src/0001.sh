#!/usr/bin/env bash

set -eo pipefail

# Since bash 5.0, checkwinsize is enabled by default which does
# update the COLUMNS variable every time a non-builtin command
# completes, even for non-interactive shells.
# Disable that since we are aiming for repeatability.
test -n "$BASH_VERSION" && shopt -u checkwinsize 2>/dev/null

export LC_ALL=C

# Limits recursive function
# @see BASH(1)
[[ -z "$FUNCNEST" ]] && export FUNCNEST=100

# simplifies both the tag name used when making a release
# and the computed version number take the date/time from the current
# commit, and then append the hash.  That way the version number always
# corresponds to a commit.
VERSION_ID=${VERSION_ID:-$(git show -s "--format=%cd-%h" "--date=format:%Y%m%d-%H%M%S")}

# @stdout Output filename
output_file="subtree_commands_$VERSION_ID.txt"

# Temporary file for submodule status
temp_file="temp_status_$(date +%s).txt"

# Check if .gitmodules exists
if [[ ! -f .gitmodules ]]; then
  echo "⛔️ Error: .gitmodules file not found."
  exit 1
fi

# Create or empty the output file
# use `:` to intentionally check that it's readable
: >"$output_file"

# Extract the submodule information
while IFS= read -r line; do
  if [[ "$line" == *'url = '* ]]; then
    # Extract the URL
    url=$(echo "$line" | cut -d'=' -f 2 | xargs)
  elif [[ "$line" == *'path = '* ]]; then
    # Extract the path
    path=$(echo "$line" | cut -d'=' -f 2 | xargs)

    # Get the hash for the submodule
    git submodule status --cached "$path" >"$temp_file"
    hash=$(cat "$temp_file" | awk '{print $1}' | sed 's/-//')

    # Append the git subtree command to the output file
    echo "git subtree add --prefix=$path $url $hash" >>"$output_file"
  fi
done <.gitmodules

# Clean up temp file
rm "$temp_file"

# Check the output file for any lines that don't start with 'git subtree'
if grep -qv '^git subtree' "$output_file"; then
  # Remove those lines
  sed -i '/^git subtree/!d' "$output_file"
  echo "ℹ️ Notice: Lines not starting with 'git subtree' found and removed."
fi

echo "✅ Commands written to $output_file."
exit 0
