# Sources
# https://github.com/mathiasbynens/dotfiles/blob/master/.macos#L143
# https://github.com/manilarome/the-glorious-dotfiles

SHELL := /bin/zsh

default: help

.PHONY: help
help: ## Print this help message
	@echo "Available make commands:"; grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: relink
relink: ## Create new symbolic links for dotfiles in this dir to your home dir.
	@echo "Generating links.."
	find $$PWD -name ".[^.]*" -type f -print0 | xargs -0tJ % ln -sf %  ~
	@mkdir -p ~/.vim
	@ln -sf $$PWD/.vim/* ~/.vim
	@mkdir -p ~/.config
	@ln -sf $$PWD/.config/*/ ~/.config
	@ln -sf $$PWD/.config/* ~/.config

.PHONY: defaults
defaults: ## Defaults is idempotent. Requires reboot. Not compatible with all macOS versions.
	# Close any open System Preferences panes, to prevent them from overriding
	# settings we’re about to change
	osascript -e 'tell application "System Preferences" to quit'

	# Ask for the administrator password upfront
	sudo -v

	#"Disabling system-wide resume"
	defaults write NSGlobalDomain NSQuitAlwaysKeepsWindows -bool false

	#"Disabling automatic termination of inactive apps"
	defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true

	#"Allow text selection in Quick Look"
	defaults write com.apple.finder QLEnableTextSelection -bool TRUE

	#"Expanding the save panel by default"
	defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
	defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
	defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

	#"Automatically quit printer app once the print jobs complete"
	defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

	#"Saving to disk (not to iCloud) by default"
	defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

	#"Check for software updates daily, not just once per week"
	# defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1

	#"Disable smart quotes and smart dashes as they are annoying when typing code"
	defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
	defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

	#"Enabling full keyboard access for all controls (e.g. enable Tab in modal dialogs)"
	defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

	#"Enabling subpixel font rendering on non-Apple LCDs"
	# defaults write NSGlobalDomain AppleFontSmoothing -int 2

	#"Showing icons for hard drives, servers, and removable media on the desktop"
	defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true

	#"Showing all filename extensions in Finder by default"
	defaults write NSGlobalDomain AppleShowAllExtensions -bool true

	#"Disabling the warning when changing a file extension"
	defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

	#"Use column view in all Finder windows by default"
	defaults write com.apple.finder FXPreferredViewStyle Clmv

	#"Avoiding the creation of .DS_Store files on network volumes"
	defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

	#"Enabling snap-to-grid for icons on the desktop and in other icon views"
	/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist
	#/usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist
	/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist

	#"Setting the icon size of Dock items to 36 pixels for optimal size/screen-realestate"
	defaults write com.apple.dock tilesize -int 36

	#"Speeding up Mission Control animations and grouping windows by application"
	defaults write com.apple.dock expose-animation-duration -float 0.1
	defaults write com.apple.dock "expose-group-by-app" -bool true

	#"Setting Dock to auto-hide and removing the auto-hiding delay"
	defaults write com.apple.dock autohide -bool true
	defaults write com.apple.dock autohide-delay -float 0
	defaults write com.apple.dock autohide-time-modifier -float 0

	#"Setting email addresses to copy as 'foo@example.com' instead of 'Foo Bar <foo@example.com>' in Mail.app"
	defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false

	#"Enabling UTF-8 ONLY in Terminal.app and setting the Pro theme by default"
	defaults write com.apple.terminal StringEncodings -array 4
	defaults write com.apple.Terminal "Default Window Settings" -string "Pro"
	defaults write com.apple.Terminal "Startup Window Settings" -string "Pro"

	#"Preventing Time Machine from prompting to use new hard drives as backup volume"
	defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

	#"Disable annoying backswipe in Chrome"
	defaults write com.google.Chrome AppleEnableSwipeNavigateWithScrolls -bool false

	#"Setting screenshots location to ~/Desktop"
	defaults write com.apple.screencapture location -string "$HOME/Desktop"

	#"Setting screenshot format to PNG"
	defaults write com.apple.screencapture type -string "png"

	#"Hiding Safari's bookmarks bar by default"
	defaults write com.apple.Safari ShowFavoritesBar -bool false

	#"Hiding Safari's sidebar in Top Sites"
	defaults write com.apple.Safari ShowSidebarInTopSites -bool false

	#"Disabling Safari's thumbnail cache for History and Top Sites"
	defaults write com.apple.Safari DebugSnapshotsUpdatePolicy -int 2

	#"Enabling Safari's debug menu"
	defaults write com.apple.Safari IncludeInternalDebugMenu -bool true

	#"Making Safari's search banners default to Contains instead of Starts With"
	defaults write com.apple.Safari FindOnPageMatchesWordStartsOnly -bool false

	#"Removing useless icons from Safari's bookmarks bar"
	defaults write com.apple.Safari ProxiesInBookmarksBar "()"

	#"Allow hitting the Backspace key to go to the previous page in history"
	defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2BackspaceKeyNavigationEnabled -bool true

	#"Enabling the Develop menu and the Web Inspector in Safari"
	defaults write com.apple.Safari IncludeDevelopMenu -bool true
	defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
	defaults write com.apple.Safari "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" -bool true

	#"Adding a context menu item for showing the Web Inspector in web views"
	defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

	#"Use `~/Downloads/Incomplete` to store incomplete downloads"
	defaults write org.m0k.transmission UseIncompleteDownloadFolder -bool true
	defaults write org.m0k.transmission IncompleteDownloadFolder -string "${HOME}/Downloads/Incomplete"

	#"Don't prompt for confirmation before downloading"
	defaults write org.m0k.transmission DownloadAsk -bool false

	#"Trash original torrent files"
	defaults write org.m0k.transmission DeleteOriginalTorrent -bool true

	#"Hide the donate message"
	defaults write org.m0k.transmission WarningDonate -bool false

	#"Hide the legal disclaimer"
	defaults write org.m0k.transmission WarningLegal -bool false

	#"Disable 'natural' (Lion-style) scrolling"
	# defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

	# Don’t automatically rearrange Spaces based on most recent use
	defaults write com.apple.dock mru-spaces -bool false

	# Reveal IP address, hostname, OS version, etc. when clicking the clock
	# in the login window
	sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName

	# Increase sound quality for Bluetooth headphones/headsets
	defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40

	# Enable full keyboard access for all controls
	# (e.g. enable Tab in modal dialogs)
	defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

	# Disable press-and-hold for keys in favor of key repeat
	defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

	# Set a blazingly fast keyboard repeat rate
	defaults write NSGlobalDomain KeyRepeat -int 1

	# Require password immediately after sleep or screen saver begins
	defaults write com.apple.screensaver askForPassword -int 1
	defaults write com.apple.screensaver askForPasswordDelay -int 0

	# Don’t display the annoying prompt when quitting iTerm
	defaults write com.googlecode.iterm2 PromptOnQuit -bool false

	# Set Help Viewer windows to non-floating mode
	defaults write com.apple.helpviewer DevMode -bool true

	# Reveal IP address, hostname, OS version, etc. when clicking the clock
	# in the login window
	sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName

	# Use scroll gesture with the Ctrl (^) modifier key to zoom
	defaults write com.apple.universalaccess closeViewScrollWheelToggle -bool true
	defaults write com.apple.universalaccess HIDScrollZoomModifierMask -int 262144
	# Follow the keyboard focus while zoomed in
	defaults write com.apple.universalaccess closeViewZoomFollowsFocus -bool true

	# Disables bouncing icon
	defaults write com.apple.dock no-bouncing -bool TRUE

	###############################################################################
	# Energy saving                                                               #
	###############################################################################

	# Enable lid wakeup
	sudo pmset -a lidwake 1

	# Restart automatically on power loss
	sudo pmset -a autorestart 1

	# Restart automatically if the computer freezes
	sudo systemsetup -setrestartfreeze on

	# Sleep the display after 15 minutes
	sudo pmset -a displaysleep 15

	# Disable machine sleep while charging
	# sudo pmset -c sleep 0

	# Set machine sleep to 5 minutes on battery
	sudo pmset -b sleep 5

	# Set standby delay to 24 hours (default is 1 hour)
	sudo pmset -a standbydelay 86400

	# Never go into computer sleep mode
	# sudo systemsetup -setcomputersleep Off > /dev/null

	# Hibernation mode
	# 0: Disable hibernation (speeds up entering sleep mode)
	# 3: Copy RAM to disk so the system state can still be restored in case of a
	#    power failure.
	# sudo pmset -a hibernatemode 0

	# Remove the sleep image file to save disk space
	# sudo rm /private/var/vm/sleepimage
	# Create a zero-byte file instead…
	# sudo touch /private/var/vm/sleepimage
	# …and make sure it can’t be rewritten
	# sudo chflags uchg /private/var/vm/sleepimage

	###############################################################################
	# Photos                                                                      #
	###############################################################################

	# Prevent Photos from opening automatically when devices are plugged in
	defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true

	###############################################################################
	# Messages                                                                    #
	###############################################################################

	# Disable automatic emoji substitution (i.e. use plain text smileys)
	# defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "automaticEmojiSubstitutionEnablediMessage" -bool false

	# Disable smart quotes as it’s annoying for messages that contain code
	defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "automaticQuoteSubstitutionEnabled" -bool false

	# Disable continuous spell checking
	# defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "continuousSpellCheckingEnabled" -bool

	###############################################################################
	# Mac App Store                                                               #
	###############################################################################

	# Enable the WebKit Developer Tools in the Mac App Store
	defaults write com.apple.appstore WebKitDeveloperExtras -bool true

	# Enable Debug Menu in the Mac App Store
	defaults write com.apple.appstore ShowDebugMenu -bool true

	###############################################################################
	# Google Chrome & Google Chrome Canary                                        #
	###############################################################################

	# Allow installing user scripts via GitHub Gist or Userscripts.org
	# defaults write com.google.Chrome ExtensionInstallSources -array "https://gist.githubusercontent.com/" "http://userscripts.org/*"
	# defaults write com.google.Chrome.canary ExtensionInstallSources -array "https://gist.githubusercontent.com/" "http://userscripts.org/*"

	# Disable the all too sensitive backswipe on trackpads
	# defaults write com.google.Chrome AppleEnableSwipeNavigateWithScrolls -bool false
	# defaults write com.google.Chrome.canary AppleEnableSwipeNavigateWithScrolls -bool false

	# Disable the all too sensitive backswipe on Magic Mouse
	# defaults write com.google.Chrome AppleEnableMouseSwipeNavigateWithScrolls -bool false
	# defaults write com.google.Chrome.canary AppleEnableMouseSwipeNavigateWithScrolls -bool false

	# Use the system-native print preview dialog
	defaults write com.google.Chrome DisablePrintPreview -bool true
	defaults write com.google.Chrome.canary DisablePrintPreview -bool true

	# Expand the print dialog by default
	defaults write com.google.Chrome PMPrintingExpandedStateForPrint2 -bool true
	defaults write com.google.Chrome.canary PMPrintingExpandedStateForPrint2 -bool true

	###############################################################################
	# Activity Monitor                                                            #
	###############################################################################

	# Show the main window when launching Activity Monitor
	defaults write com.apple.ActivityMonitor OpenMainWindow -bool true

	# Visualize CPU usage in the Activity Monitor Dock icon
	defaults write com.apple.ActivityMonitor IconType -int 5

	# Show all processes in Activity Monitor
	defaults write com.apple.ActivityMonitor ShowCategory -int 0

	# Sort Activity Monitor results by CPU usage
	defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
	defaults write com.apple.ActivityMonitor SortDirection -int 0

	killall Finder
	killall Dock

	@echo "✅ Complete!"
	@echo "Note that some of these changes require a logout/restart to take effect."
	@echo "Turn on alt key in Terminal. Terminal > Preferences > Settings > Keyboard"

.PHONY: setup
setup: relink ~/.ssh xcode homebrew git cli-apps rust zsh superhuman terminal krew ## NOT idempotent. Install necessary tools and programs on a brand new Mac.
	source ~/.zshrc
	@echo "✅ Complete!"

~/.ssh:
	mkdir -p ~/.ssh

terminal:
	echo "Terminal Preferences: Shell -> Use Settings as Default"
	echo "Additional themes at https://github.com/lysyi3m/macos-terminal-themes"
	open Kibble.terminal

.PHONY: xcode
xcode:
	@echo "Installing Xcode command line tools and such"
	xcode-select --install

.PHONY: homebrew
homebrew:
	@echo "Installing homebrew..."
	@$(SHELL) -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
	@brew update

.PHONY: git
git:
	@echo "Installing Git..."
	git config --global user.name "David Nix"
	git config --global user.email hello@davidnix.io
	git config --global push.default current
	git config --global fetch.prune true
	# https://help.github.com/en/github/using-git/caching-your-github-password-in-git
	git config --global credential.helper osxkeychain
	@echo "Installing brew git utilities..."

.PHONY: cli-apps
cli-apps: ## Installs command line tools
	@echo "Installing command line tools"
	@arch -arm64 brew bundle
	@echo "Cleaning up brew"
	@brew cleanup
	@ln -s /opt/homebrew/bin/mcfly /usr/local/bin/mcfly

KREW = kubectl krew
.PHONY: krew
krew: ## Installs kubectl krew plugins
	$(KREW) upgrade
	$(KREW) install ctx
	$(KREW) install ns
	$(KREW) install stern


~/.oh-my-zsh:
	@echo "Installing ohmyzsh"
	@$(SHELL) -c "$$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

.PHONY: zsh
zsh:  ~/.oh-my-zsh
	 @$(SHELL) -c "source ~/.zshrc && zplug install"

.PHONY: rust
rust: $(CARGO) ~/.cargo/bin/ytop

CARGO:=~/.cargo/bin
$(CARGO):
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

$(CARGO)/%:
	cargo install "$(notdir $@)"

.PHONY: superhuman
superhuman:
	@echo "Download Superhuman at https://mail.superhuman.com"
	@echo "Send yourself a test email to get Superhuman to register with macOS notification settings."

