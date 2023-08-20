#!/usr/bin/env bash

# simplifies both the tag name used when making a release
# and the computed version number take the date/time from the current
# commit, and then append the hash.  That way the version number always
# corresponds to a commit.
VERSION_ID=${VERSION_ID:-$(git show -s "--format=%cd-%h" "--date=format:%Y%m%d-%H%M%S")}

# @stdout Output filename
output_file="subtree_commands_$VERSION_ID.txt"

# Ensure .gitmodules file exists
if [[ ! -f .gitmodules ]]; then
  echo "⛔️ Error: .gitmodules file not found."
  exit 1
fi

# Clear or create the output file
: >"$output_file"

# Parse the .gitmodules file and generate subtree commands
while IFS= read -r line; do
  if [[ "$line" == '[submodule'* ]]; then
    name=$(echo "$line" | cut -d'"' -f 2)
  elif [[ "$line" == *'path = '* ]]; then
    path=$(echo "$line" | cut -d'=' -f 2 | xargs)
  elif [[ "$line" == *'url = '* ]]; then
    url=$(echo "$line" | cut -d'=' -f 2 | xargs)

    # Get the commit hash for the submodule
    hash=$(git submodule status --cached "$path" | awk '{print $1}')

    # If hash is empty, raise an error
    if [[ -z "$hash" ]]; then
      echo "⛔️ Error: Failed to retrieve hash for submodule $name at path $path."
      exit 1
    fi

    # Write the subtree command to the output file
    echo "git subtree add --prefix=$path $url $hash" >>"$output_file"
  fi
done <.gitmodules

# Assertion: Ensure that the output file only has lines that start with "git subtree"
if grep -qv "^git subtree" "$output_file"; then
  echo "⛔️ Error: Output file contains invalid lines."
  exit 1
fi
sleep 1

echo "Commands written to $output_file"
exit 0
