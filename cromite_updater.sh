#!/bin/bash
# This script is used to update Cromite automatically from the github repository

# Check for a new Release on Gihtub
check_for_update() {
    # Get the latest release version from GitHub
    latest_version=$(curl -s https://api.github.com/repos/uazo/cromite/releases/latest | jq -r .tag_name)

    # Get the current version from the local file
    current_version=$(cat /opt/cromite/cromite_version.txt)

    # Compare versions
    if [ "$latest_version" != "$current_version" ]; then
        echo "Update available: $latest_version from $current_version"
        return 0
    else
        echo "No update available."
        return 1
    fi
}

# Download the latest release
download_update() {
    # Get the latest release download URL for the Linux Archive
    download_url=$(curl -s https://api.github.com/repos/uazo/cromite/releases/latest | jq -r .assets[5].browser_download_url)
    if [ -z "$download_url" ]; then
        echo "Error: Download-URL is not available."
        exit 1
    fi
    # Download the latest release
    curl -L -o ~/Downloads/chrome-lin64.tar.gz "$download_url"
    if [ $? -ne 0 ]; then
        echo "Error: Download failed."
        exit 1
    fi
}

# Extract the downloaded file
extract_update() {
    # Check if the Cromite directory exists
    if [ ! -d /opt/cromite ]; then
        echo "Cromite directory does not exist. Creating it..."
        sudo mkdir -p /opt/cromite
    fi
    tar -xzf ~/Downloads/chrome-lin64.tar.gz -C ~/Downloads/
    sudo mv ~/Downloads/chrome-lin/* /opt/cromite/
    sudo rm -rf ~/Downloads/chrome-lin64.tar.gz
    sudo rm -rf ~/Downloads/chrome-lin
    # Update the version file
    if [ ! "$latest_version" ]; then
        latest_version=$(curl -s https://api.github.com/repos/uazo/cromite/releases/latest | jq -r .tag_name)
    fi
    echo "$latest_version" | sudo tee /opt/cromite/cromite_version.txt > /dev/null
}

# Create a .Desktop File for Cromite
create_desktop_file() {
    # Remove any existing .desktop file
    if [ -f ~/.local/share/applications/cromite.desktop ]; then
        rm ~/.local/share/applications/cromite.desktop
    fi
    sudo cat <<EOF > ~/.local/share/applications/cromite.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=Cromite
Comment= Privacy focused Chromium Version
Exec=/opt/cromite/chrome
Icon=/opt/cromite/product_logo_48.png
Terminal=false
Categories=Utility, Browser;
EOF
    chmod +x ~/.local/share/applications/cromite.desktop
}

# Main script execution
main() {
    if [ ! -d /opt/cromite ]; then
        echo "Cromite is not installed. Installing Cromite first..."
        # Create the Cromite directory
        download_update
        # Extract the downloaded file
        extract_update
        # Create a .desktop file
        create_desktop_file
    fi
    # Update Process
    echo "Checking for updates..."
    if check_for_update; then
        # Download the update
        download_update

        # Extract the update
        extract_update

        # Create a .desktop file
        create_desktop_file

        echo "Cromite has been updated to version $latest_version."
    else
        echo "Cromite is already up to date."
    fi
}

# Run the main function
main
# End of script
