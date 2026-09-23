#!/usr/bin/env zsh

set -e

typeset -a failures

apply() {
    local setting=$1
    shift
    if "$@"; then
        return
    fi
    echo "Warning: could not change $setting" >&2
    failures+=("$setting")
}

apply_screensaver() {
    local key=$1 value=$2 actual
    if defaults write com.apple.screensaver "$key" -int "$value"; then
        if actual=$(defaults read com.apple.screensaver "$key") && [[ "$actual" == "$value" ]]; then
            return
        fi
        echo "Warning: com.apple.screensaver $key did not read back as $value (got: ${actual:-unavailable})" >&2
    fi
    echo "Warning: could not change com.apple.screensaver $key" >&2
    failures+=("com.apple.screensaver $key")
}

disable_remote_login() {
    echo yes | sudo systemsetup -setremotelogin off
}

echo "Configuring macOS defaults..."

# Close System Preferences to prevent it from overriding our changes
apply "closing System Preferences" osascript -e 'tell application "System Preferences" to quit'

# Ask for the administrator password upfront
sudo -v

###############################################################################
# Keyboard                                                                     #
###############################################################################

# Fast key repeat rate (2 = fast but not causing repeated characters)
apply "NSGlobalDomain KeyRepeat" defaults write NSGlobalDomain KeyRepeat -int 1

# Short delay before key repeat kicks in (12 = responsive without typos)
apply "NSGlobalDomain InitialKeyRepeat" defaults write NSGlobalDomain InitialKeyRepeat -int 12

# Mouse tracking speed (2.5 = fast but controllable)
apply "NSGlobalDomain com.apple.mouse.scaling" defaults write NSGlobalDomain com.apple.mouse.scaling -float 2.5

# Trackpad tracking speed (2.0 = fast but precise)
apply "NSGlobalDomain com.apple.trackpad.scaling" defaults write NSGlobalDomain com.apple.trackpad.scaling -float 2.0

# Disable press-and-hold for keys in favor of key repeat
apply "NSGlobalDomain ApplePressAndHoldEnabled" defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Enable full keyboard access for all controls (e.g. Tab in modal dialogs)
apply "NSGlobalDomain AppleKeyboardUIMode" defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Disable smart quotes (annoying when typing code)
apply "NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled" defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# Disable smart dashes (annoying when typing code)
apply "NSGlobalDomain NSAutomaticDashSubstitutionEnabled" defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Caps Lock -> Control can't be set via defaults write
echo ""
echo "Manual keyboard setup required:"
echo "  1. Caps Lock -> Control: System Settings > Keyboard > Keyboard Shortcuts > Modifier Keys"
echo ""

###############################################################################
# Dock                                                                         #
###############################################################################

# Auto-hide the Dock
apply "Dock auto-hide" defaults write com.apple.dock autohide -bool true

# Remove the auto-hide delay
apply "Dock auto-hide delay" defaults write com.apple.dock autohide-delay -float 0

# Remove the auto-hide animation
apply "Dock auto-hide animation" defaults write com.apple.dock autohide-time-modifier -float 0

# Set icon size to 36 pixels
apply "Dock icon size" defaults write com.apple.dock tilesize -int 36

# Speed up Mission Control animations
apply "Mission Control animation duration" defaults write com.apple.dock expose-animation-duration -float 0.1

# Group windows by application in Mission Control
apply "Mission Control group by app" defaults write com.apple.dock "expose-group-by-app" -bool true

# Don't bounce icons in the Dock
apply "Dock icon bouncing" defaults write com.apple.dock no-bouncing -bool TRUE

# Don't automatically rearrange Spaces based on most recent use
apply "Mission Control Spaces order" defaults write com.apple.dock mru-spaces -bool false

# Use scale effect for minimizing windows
apply "Dock minimize effect" defaults write com.apple.dock mineffect -string "scale"

###############################################################################
# Safari                                                                       #
###############################################################################

# Safari prefs are sandboxed on modern macOS and can't be set via defaults write.
echo ""
echo "Manual Safari setup required:"
echo "  1. Develop menu: Safari > Settings > Advanced > Show features for web developers"
echo "  2. Disable password autofill: Safari > Settings > Passwords > uncheck AutoFill"
echo "  3. Disable auto-open safe downloads: Safari > Settings > General > uncheck Open safe files"
echo ""

# Add Web Inspector context menu item to all web views (this one is global, not sandboxed)
apply "WebKitDeveloperExtras" defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

###############################################################################
# Photos                                                                       #
###############################################################################

# Prevent Photos from opening automatically when devices are plugged in
apply "Image Capture auto-open" defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true

###############################################################################
# Messages                                                                     #
###############################################################################

# Disable smart quotes in Messages (annoying for messages that contain code)
apply "Messages smart quotes" defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "automaticQuoteSubstitutionEnabled" -bool false

###############################################################################
# Finder                                                                       #
###############################################################################

# Show all file extensions
apply "Show all file extensions" defaults write NSGlobalDomain AppleShowAllExtensions -bool true

###############################################################################
# Google Chrome                                                                #
###############################################################################

# Use the system-native print preview dialog
apply "Chrome native print dialog" defaults write com.google.Chrome DisablePrintPreview -bool true

# Expand the print dialog by default
apply "Chrome expanded print dialog" defaults write com.google.Chrome PMPrintingExpandedStateForPrint2 -bool true

###############################################################################
# Accessibility                                                                #
###############################################################################

# Accessibility prefs are sandboxed on modern macOS and can't be set via defaults write.
echo "Manual accessibility setup required:"
echo "  1. Ctrl+scroll zoom: System Settings > Accessibility > Zoom > Use scroll gesture with modifier keys"
echo ""

###############################################################################
# Energy                                                                       #
###############################################################################

# Wake when opening the lid
apply "Wake on lid open" sudo pmset -a lidwake 1

# Restart automatically on power loss
apply "Restart after power loss" sudo pmset -a autorestart 1

# On battery: display sleep after 5 minutes, machine sleep after 10
apply "Battery display sleep" sudo pmset -b displaysleep 5
apply "Battery system sleep" sudo pmset -b sleep 10

# On AC: display sleep after 15 minutes
apply "AC display sleep" sudo pmset -c displaysleep 15

# Set standby delay to 24 hours (default is 1 hour)
apply "Standby delay" sudo pmset -a standbydelay 86400

# Restart automatically if the computer freezes (must come after pmset to avoid warnings)
apply "Restart after freeze" sudo systemsetup -setrestartfreeze on

###############################################################################
# Security & Privacy                                                           #
###############################################################################

# Enable the firewall
apply "Firewall" sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on

# Enable stealth mode (don't respond to ICMP pings)
apply "Firewall stealth mode" sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on

# Restart the firewall to pick up changes
apply "Firewall reload" sudo pkill -HUP socketfilterfw

# Require password immediately after sleep or screen saver begins
apply_screensaver askForPassword 1
apply_screensaver askForPasswordDelay 0

# Disable remote login (SSH) — does not affect Tailscale SSH
apply "Disable remote login" disable_remote_login

# AirDrop: contacts only
apply "AirDrop contacts only" defaults write com.apple.sharingd DiscoverableMode -string "Contacts Only"

# Auto-check for software updates
apply "Automatic update checks" defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true

# Auto-download updates in the background
apply "Automatic update downloads" defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1

# Install critical security updates automatically
apply "Critical security updates" defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 1

# Disable Siri
apply "Disable Siri" defaults write com.apple.assistant.support "Assistant Enabled" -bool false

# Disable Siri analytics
apply "Disable Siri analytics" defaults write com.apple.assistant.support 'Siri Data Store Opt-In Status' -int 2

# Disable automatic login
if sudo defaults read /Library/Preferences/com.apple.loginwindow autoLoginUser >/dev/null 2>&1; then
    apply "Disable automatic login" sudo defaults delete /Library/Preferences/com.apple.loginwindow autoLoginUser
fi

###############################################################################
# Restart affected services                                                    #
###############################################################################

killall Finder 2>/dev/null || true
killall Dock 2>/dev/null || true

echo "Done!"
if (( ${#failures} )); then
    echo "${#failures} setting(s) could not be changed:"
    printf '  - %s\n' "${failures[@]}"
fi
echo "Note: Some changes require logout/restart to take effect."
