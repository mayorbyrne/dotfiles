#!/bin/bash
# Azure DevOps setup: az devops defaults, credentials, and config.sh for ~/scripts.
# Run this script with: bash setup_azure.sh
# Rerunning is safe. Current values are offered as defaults.

set -e

ask() {
    local answer
    if [ -n "$2" ]; then
        read -r -p "$1 [$2]: " answer
    else
        read -r -p "$1: " answer
    fi
    printf '%s' "${answer:-$2}"
}

az_devops_default() {
    az devops configure --list 2>/dev/null | tr -d '\r' | sed -n "s/^$1 *= *//p" | head -n 1
}

write_config() {
    local template="$1" target="$2" repo_line="$3" reviewers_line="$4"
    local tmp line seen_repo="" seen_reviewers="" dropped_header=""
    tmp="$(mktemp)"
    while IFS= read -r line || [ -n "$line" ]; do
        if [ -n "$dropped_header" ] && [ -z "${line%$'\r'}" ]; then
            dropped_header=""
            continue
        fi
        dropped_header=""
        case "$line" in
            "# Copy this file to config.sh"*) dropped_header=1 ;;
            REPO_BASE=*) printf '%s\n' "$repo_line"; seen_repo=1 ;;
            REVIEWERS=*) printf '%s\n' "$reviewers_line"; seen_reviewers=1 ;;
            *) printf '%s\n' "$line" ;;
        esac
    done < "$template" > "$tmp"
    [ -n "$seen_repo" ] || printf '%s\n' "$repo_line" >> "$tmp"
    [ -n "$seen_reviewers" ] || printf '%s\n' "$reviewers_line" >> "$tmp"
    mv "$tmp" "$target"
}

echo "===================================="
echo "Azure DevOps Setup"
echo "===================================="
echo ""

if command -v az &> /dev/null; then
    ORGANIZATION="$(ask "Organization URL or name" "$(az_devops_default organization)")"
    PROJECT="$(ask "Default project" "$(az_devops_default project)")"

    case "$ORGANIZATION" in
        ""|http://*|https://*) ;;
        *) ORGANIZATION="https://dev.azure.com/$ORGANIZATION" ;;
    esac
    ORGANIZATION="${ORGANIZATION%/}"

    DEFAULTS=()
    [ -n "$ORGANIZATION" ] && DEFAULTS+=("organization=$ORGANIZATION")
    [ -n "$PROJECT" ] && DEFAULTS+=("project=$PROJECT")
    if [ ${#DEFAULTS[@]} -gt 0 ]; then
        az devops configure --defaults "${DEFAULTS[@]}"
        echo "  Set az devops defaults: ${DEFAULTS[*]}"
    else
        echo "  No organization or project given. Skipping az devops defaults."
    fi
else
    echo "az not found. Skipping az devops defaults."
fi
echo ""

# Matches mac/lib/load_config.sh in the scripts repo: Git Bash reads windows/, everything else mac/.
SCRIPTS_DIR="$HOME/scripts"
case "$OSTYPE" in
    msys*|cygwin*) CONFIG_DIR="$SCRIPTS_DIR/windows" ;;
    *) CONFIG_DIR="$SCRIPTS_DIR/mac" ;;
esac
CONFIG_PATH="$CONFIG_DIR/config.sh"
TEMPLATE_PATH="$CONFIG_PATH"
[ -f "$TEMPLATE_PATH" ] || TEMPLATE_PATH="$CONFIG_DIR/config.example.sh"

if [ -f "$TEMPLATE_PATH" ]; then
    CURRENT_REPO_BASE="$(. "$TEMPLATE_PATH" > /dev/null 2>&1; printf '%s' "$REPO_BASE")"
    # The example file's reviewers are placeholders, not defaults worth offering.
    CURRENT_REVIEWERS=""
    if [ "$TEMPLATE_PATH" = "$CONFIG_PATH" ]; then
        CURRENT_REVIEWERS="$(. "$TEMPLATE_PATH" > /dev/null 2>&1; IFS=,; printf '%s' "${REVIEWERS[*]}")"
    fi

    REPO_BASE_INPUT="$(ask "Directory holding your cloned repos" "$CURRENT_REPO_BASE")"
    REPO_BASE_INPUT="${REPO_BASE_INPUT/#\~/$HOME}"
    REPO_BASE_INPUT="${REPO_BASE_INPUT%/}"
    # The Python scripts parse config.sh themselves and cannot resolve /c/... paths.
    if [ -n "$REPO_BASE_INPUT" ] && command -v cygpath &> /dev/null; then
        REPO_BASE_INPUT="$(cygpath -m "$REPO_BASE_INPUT")"
    fi
    REVIEWERS_INPUT="$(ask "Required PR reviewers (comma-separated emails)" "$CURRENT_REVIEWERS")"

    if [ -n "$REPO_BASE_INPUT" ] && [ ! -d "$REPO_BASE_INPUT" ]; then
        echo "  Warning: $REPO_BASE_INPUT does not exist yet"
    fi

    REVIEWER_ITEMS=""
    IFS=',' read -r -a REVIEWER_LIST <<< "$REVIEWERS_INPUT"
    for reviewer in "${REVIEWER_LIST[@]}"; do
        reviewer="${reviewer//[[:space:]]/}"
        [ -n "$reviewer" ] && REVIEWER_ITEMS="$REVIEWER_ITEMS \"$reviewer\""
    done

    write_config "$TEMPLATE_PATH" "$CONFIG_PATH" "REPO_BASE=\"$REPO_BASE_INPUT\"" "REVIEWERS=(${REVIEWER_ITEMS# })"
    echo "  Wrote $CONFIG_PATH"
else
    echo "$CONFIG_DIR not found. Skipping config.sh (clone the scripts repo to $SCRIPTS_DIR first)."
fi
echo ""

PAT_NAME="AZURE_DEVOPS_EXT_PAT"
HAS_PAT=""
case "$(uname -s)" in
    Darwin*)
        security find-generic-password -s "$PAT_NAME" -w > /dev/null 2>&1 && HAS_PAT=1
        read -r -p "Store a personal access token in the login keychain? (y/N): " STORE_PAT
        case "$STORE_PAT" in
            [yY]*)
                # A trailing -w makes security prompt, keeping the token out of argv and history.
                security add-generic-password -a "$USER" -s "$PAT_NAME" -U -w
                HAS_PAT=1
                ;;
        esac
        ;;
    MINGW*|MSYS*|CYGWIN*)
        [ -n "${!PAT_NAME}" ] && HAS_PAT=1
        echo "To store a personal access token on Windows, run shared/install/setup_azure.ps1"
        ;;
    *)
        [ -n "${!PAT_NAME}" ] && HAS_PAT=1
        echo "To use a personal access token, export $PAT_NAME from a file outside this repo."
        ;;
esac

if [ -z "$HAS_PAT" ] && command -v az &> /dev/null && ! az account show --output none > /dev/null 2>&1; then
    read -r -p "No token and not signed in. Run 'az login' now? (Y/n): " RUN_LOGIN
    case "$RUN_LOGIN" in
        [nN]*) ;;
        *) az login --allow-no-subscriptions --output none ;;
    esac
fi

echo ""
echo "===================================="
echo "Azure DevOps Setup Complete!"
echo "===================================="
echo ""
