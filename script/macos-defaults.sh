#!/usr/bin/env zsh

set -e

echo "Configuring macOS defaults..."

# Close System Preferences to prevent it from overriding our changes
osascript -e 'tell application "System Preferences" to quit'

# Ask for the administrator password upfront
sudo -v

###############################################################################
# Keyboard                                                                     #
###############################################################################

# Fast key repeat rate (2 = fast but not causing repeated characters)
defaults write NSGlobalDomain KeyRepeat -int 1

# Short delay before key repeat kicks in (12 = responsive without typos)
defaults write NSGlobalDomain InitialKeyRepeat -int 12

# Mouse tracking speed (2.5 = fast but controllable)
defaults write NSGlobalDomain com.apple.mouse.scaling -float 2.5

# Trackpad tracking speed (2.0 = fast but precise)
defaults write NSGlobalDomain com.apple.trackpad.scaling -float 2.0

# Disable press-and-hold for keys in favor of key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Enable full keyboard access for all controls (e.g. Tab in modal dialogs)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Disable smart quotes (annoying when typing code)
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# Disable smart dashes (annoying when typing code)
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Caps Lock -> Control can't be set via defaults write
echo ""
echo "Manual keyboard setup required:"
echo "  1. Caps Lock -> Control: System Settings > Keyboard > Keyboard Shortcuts > Modifier Keys"
echo ""

###############################################################################
# Dock                                                                         #
###############################################################################

# Auto-hide the Dock
defaults write com.apple.dock autohide -bool true

# Remove the auto-hide delay
defaults write com.apple.dock autohide-delay -float 0

# Remove the auto-hide animation
defaults write com.apple.dock autohide-time-modifier -float 0

# Set icon size to 36 pixels
defaults write com.apple.dock tilesize -int 36

# Speed up Mission Control animations
defaults write com.apple.dock expose-animation-duration -float 0.1

# Group windows by application in Mission Control
defaults write com.apple.dock "expose-group-by-app" -bool true

# Don't bounce icons in the Dock
defaults write com.apple.dock no-bouncing -bool TRUE

# Don't automatically rearrange Spaces based on most recent use
defaults write com.apple.dock mru-spaces -bool false

# Use scale effect for minimizing windows
defaults write com.apple.dock mineffect -string "scale"

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
defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

###############################################################################
# Photos                                                                       #
###############################################################################

# Prevent Photos from opening automatically when devices are plugged in
defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true

###############################################################################
# Messages                                                                     #
###############################################################################

# Disable smart quotes in Messages (annoying for messages that contain code)
defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "automaticQuoteSubstitutionEnabled" -bool false

###############################################################################
# Finder                                                                       #
###############################################################################

# Show all file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

###############################################################################
# Google Chrome                                                                #
###############################################################################

# Use the system-native print preview dialog
defaults write com.google.Chrome DisablePrintPreview -bool true

# Expand the print dialog by default
defaults write com.google.Chrome PMPrintingExpandedStateForPrint2 -bool true

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
sudo pmset -a lidwake 1

# Restart automatically on power loss
sudo pmset -a autorestart 1

# On battery: display sleep after 5 minutes, machine sleep after 10
sudo pmset -b displaysleep 5
sudo pmset -b sleep 10

# On AC: display sleep after 15 minutes
sudo pmset -c displaysleep 15

# Set standby delay to 24 hours (default is 1 hour)
sudo pmset -a standbydelay 86400

# Restart automatically if the computer freezes (must come after pmset to avoid warnings)
sudo systemsetup -setrestartfreeze on

###############################################################################
# Security & Privacy                                                           #
###############################################################################

# Enable the firewall
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on

# Enable stealth mode (don't respond to ICMP pings)
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on

# Restart the firewall to pick up changes
sudo pkill -HUP socketfilterfw

# Require password immediately after sleep or screen saver begins
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Disable remote login (SSH) — does not affect Tailscale SSH
echo "yes" | sudo systemsetup -setremotelogin off

# AirDrop: contacts only
defaults write com.apple.sharingd DiscoverableMode -string "Contacts Only"

# Auto-check for software updates
defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true

# Auto-download updates in the background
defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1

# Install critical security updates automatically
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 1

# Disable Siri
defaults write com.apple.assistant.support "Assistant Enabled" -bool false

# Disable Siri analytics
defaults write com.apple.assistant.support 'Siri Data Store Opt-In Status' -int 2

# Disable automatic login
sudo defaults delete /Library/Preferences/com.apple.loginwindow autoLoginUser 2>/dev/null || true

###############################################################################
# Restart affected services                                                    #
###############################################################################

killall Finder 2>/dev/null || true
killall Dock 2>/dev/null || true

echo "Done!"
echo "Note: Some changes require logout/restart to take effect."
