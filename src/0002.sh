#!/usr/bin/env bash

# Since bash 5.0, checkwinsize is enabled by default which does
# update the COLUMNS variable every time a non-builtin command
# completes, even for non-interactive shells.
# Disable that since we are aiming for repeatability.
test -n "$BASH_VERSION" && shopt -u checkwinsize 2>/dev/null



export LC_ALL=C


# If no debug override has been done yet
if [[ -z "${PS4:-}" ]] || [[ "$PS4" == "+ " ]]; then
	PS4=' (${BASH_SOURCE##*/}:$LINENO ${FUNCNAME[0]:-main})  '
fi


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

# @check
# Ensure .gitmodules file exists
if [ ! -f .gitmodules ]; then
    # @stderr No gitmodules found
    echo "⛔️ Error: .gitmodules file not found."
    exit 1
fi

# Clear or create the output file
> "$output_file"

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
        if [ -z "$hash" ]; then
            # @stderr submodule hash invalid
            echo "⛔️ Error: Failed to retrieve hash for submodule $name at path $path."
            exit 1
        fi
        
        # Write the subtree command to the output file
        echo "git subtree add --prefix=$path $url $hash" >> "$output_file"
    fi
done < .gitmodules

# Assertion: Ensure that the output file only has lines that start with "git subtree"
if grep -qv "^git subtree" "$output_file"; then
    echo "⛔️ Error: Output file contains invalid lines."
    exit 1
fi

echo "Commands written to $output_file"
sleep 1

exit 0