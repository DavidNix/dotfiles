# Sources
# https://github.com/mathiasbynens/dotfiles/blob/master/.macos#L143
# https://github.com/manilarome/the-glorious-dotfiles

SHELL := /bin/zsh

default: help

.PHONY: help
help: ## Print this help message
	@echo "Available make commands:"; grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: install-scripts
install-scripts: ## Install custom scripts to /usr/local/bin
	@echo "Installing scripts to /usr/local/bin..."
	@chmod +x $$PWD/bin/*
	@sudo cp -f $$PWD/bin/* /usr/local/bin/
	@echo "Scripts installed successfully"

.PHONY: relink
relink: install-scripts ## Create new symbolic links for dotfiles in this dir to your home dir.
	@echo "Generating links.."
	@# Link all the dotfiles
	find $$PWD -name ".[^.]*" -type f -print0 | xargs -0tJ % ln -sf %  ~
	mkdir -p ~/.vim
	ln -sf $$PWD/.vim/* ~/.vim
	mkdir -p ~/.config
	ln -sf $$PWD/.config/*/ ~/.config
	ln -sf $$PWD/.config/* ~/.config
	@#Claude Code
	mkdir -p ~/.claude/commands
	ln -sf $$PWD/.claude/settings.json ~/.claude/settings.json
	ln -sf $$PWD/.claude/commands/* ~/.claude/commands
	ln -sf $$PWD/.claude/plugins/* ~/.claude/plugins
	ln -sf $$PWD/.claude/skills/* ~/.claude/skills
	@# Add mcp servers here because symlinking ~/.claude.json is a bad idea. Huge and changes often.
	-claude mcp add --scope user --transport http context7 https://mcp.context7.com/mcp

.PHONY: defaults
defaults: ## Defaults is idempotent. Requires reboot. Not compatible with all macOS versions.
	@$$PWD/script/macos-defaults.sh

.PHONY: setup
setup: relink ~/.ssh xcode homebrew git cli-apps zsh superhuman krew npm ## NOT idempotent. Install necessary tools and programs on a brand new Mac.
	source ~/.zshrc
	@echo "✅ Complete!"

~/.ssh:
	mkdir -p ~/.ssh

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
	arch -arm64 brew bundle
	@echo "Cleaning up brew"
	brew cleanup
	mise install
	curl -fsSL https://claude.ai/install.sh | bash
	curl -LsSf https://astral.sh/uv/install.sh | sh

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

.PHONY: superhuman
superhuman:
	@echo "Download Superhuman at https://mail.superhuman.com"
	@echo "Send yourself a test email to get Superhuman to register with macOS notification settings."
