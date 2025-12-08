#!/bin/zsh

echo "=== Cloning Homebrew ==="
git clone --depth=1 https://github.com/Homebrew/brew ~/.brew

echo "=== Updating .zshrc PATH ==="
BREW_PATH='export PATH="$HOME/.brew/bin:$HOME/.brew/sbin:$PATH"'
if ! grep -qxF "$BREW_PATH" ~/.zshrc; then
    echo "$BREW_PATH" >> ~/.zshrc
fi

echo "=== Sourcing ~/.zshrc ==="
source ~/.zshrc

echo "=== Running brew update ==="
brew update || true

echo "=== Installing packages via brew ==="
brew install tree wget

echo "=== Installing opencode ==="
curl -fsSL https://opencode.ai/install | bash

echo "=== Sourcing ~/.zshrc ==="
source ~/.zshrc

echo "=== Installing Ollama ==="
curl -fsSL https://ollama.com/install.sh | sh

echo "=== Sourcing ~/.zshrc ==="
source ~/.zshrc

echo "=== Enabling Safari Developer Tools ==="
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitPreferences.developerExtrasEnabled -bool true
defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

echo "=== Finished! ==="
echo "Open a new terminal window for PATH changes to apply."
