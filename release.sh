#!/bin/zsh
# Ultimate Release Automator for arch-update-check

# Directories
PROJECT_DIR="$HOME/arch-projects/arch-update-check"
AUR_DIR="$HOME/arch-projects/arch-update-check-aur"
SCRIPT_NAME="arch-update-check.sh"

# Colors for feedback
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}==>${NC} Starting Release Process..."

# 1. Pre-flight Check: ShellCheck
if command -v shellcheck > /dev/null; then
    echo -e "${GREEN}==>${NC} Running ShellCheck..."
    if ! shellcheck -s bash "$PROJECT_DIR/$SCRIPT_NAME"; then
        echo -e "${RED}ERROR:${NC} ShellCheck found issues. Fix them before releasing."
        exit 1
    fi
else
    echo -e "${RED}WARN:${NC} ShellCheck not installed. Skipping code linting."
fi

# 2. Pre-flight Check: Git Status
cd "$PROJECT_DIR" || exit
if [[ -n $(git status -s) ]]; then
    echo -e "${RED}ERROR:${NC} You have uncommitted changes in the project folder."
    exit 1
fi

# 3. Version Input
current_ver=$(grep "VERSION=" "$SCRIPT_NAME" | cut -d'"' -f2)
echo -e "${GREEN}==>${NC} Current version is: ${GREEN}$current_ver${NC}"
echo -n "Enter new version (e.g., 1.3.4): "
read -r VERSION

if [[ -z "$VERSION" ]]; then
    echo "Aborting: No version entered."
    exit 1
fi

# 4. Update Internal Version & Commit Project
echo -e "${GREEN}==>${NC} Updating internal version to $VERSION..."
sed -i "s/^VERSION=.*/VERSION=\"$VERSION\"/" "$PROJECT_DIR/$SCRIPT_NAME"

git add "$SCRIPT_NAME"
git commit -m "Release v$VERSION"
git push origin main
git tag -a "v$VERSION" -m "Version $VERSION"
git push origin "v$VERSION"

# 5. Sync to AUR Folder
echo -e "${GREEN}==>${NC} Syncing to AUR repository..."
cp "$PROJECT_DIR/$SCRIPT_NAME" "$AUR_DIR/"
cd "$AUR_DIR" || exit

# Update PKGBUILD version
sed -i "s/^pkgver=.*/pkgver=$VERSION/" PKGBUILD

# Generate Checksums & Metadata
echo -e "${GREEN}==>${NC} Updating checksums and .SRCINFO..."
updpkgsums
makepkg --printsrcinfo > .SRCINFO

# 6. Final AUR Cleanup & Push
# This ensures we don't accidentally track tarballs again
rm -f *.tar.gz
rm -rf pkg/ src/

git add PKGBUILD .SRCINFO "$SCRIPT_NAME"
# Using -A to ensure any accidental deletions are also staged
git commit -m "Update to $VERSION"
git push aur master

echo -e "${GREEN}==>${NC} Successfully deployed v$VERSION to GitHub and AUR!"
