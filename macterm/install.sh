#!/bin/zsh
###############################################
# MacTerm Installer v1.1
# A program by Ruben
# https://scstudios.tech/projects/macterm
###############################################

clear
echo ""
echo "=================================================="
echo "┏━┓┏━┓━━━━━━━━━┏━━━━┓━━━━━━━━━━━
┃┃┗┛┃┃━━━━━━━━━┃┏┓┏┓┃━━━━━━━━━━━
┃┏┓┏┓┃┏━━┓━┏━━┓┗┛┃┃┗┛┏━━┓┏━┓┏┓┏┓
┃┃┃┃┃┃┗━┓┃━┃┏━┛━━┃┃━━┃┏┓┃┃┏┛┃┗┛┃
┃┃┃┃┃┃┃┗┛┗┓┃┗━┓━┏┛┗┓━┃┃━┫┃┃━┃┃┃┃
┗┛┗┛┗┛┗━━━┛┗━━┛━┗━━┛━┗━━┛┗┛━┗┻┻┛
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"
echo "--------------------------------------------------"
echo "--------------MacTerm Installer V1.1--------------"
echo "----------------A project by Ruben----------------"
echo "------https://scstudios.tech/projects/macterm-----"
echo "--------------------------------------------------"
echo ""
# -----------------------------
# macOS check
# -----------------------------
if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "Thanks for showing interest in MacTerm. Unfortunately, "
    echo "MacTerm installer only runs on macOS."
    echo "Detected OS: $(uname -s)"
    echo "However, I am in the process of developing a version of this for other systems that use zsh. 
(the main reason it is only compatible with mac is because it installs homebrew. that and the fact that it's called macterm)"
    echo "see the projects section of my website to find out if I have made another version for other Linux distros"
    echo "at https://scstudios.tech"
    echo "Thanks!"
    echo "Exiting..."
    exit 1
fi

###############################################
# Fancy Spinner + Progress Bar Utilities
###############################################

SPINNER_FRAMES=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")

progress_run() {
  local label="$1"
  shift
  local cmd="$*"

  echo ""
  echo "▶ $label"
  echo ""

  local start=$SECONDS
  local width=40
  local spinner_i=1

  (
    eval "$cmd"
  ) &
  local pid=$!

  while kill -0 $pid 2>/dev/null; do
    # Get spinner frame (zsh arrays are 1-indexed)
    local frame="${SPINNER_FRAMES[$spinner_i]}"
    spinner_i=$(( (spinner_i % ${#SPINNER_FRAMES[@]}) + 1 ))

    # Calculate elapsed time
    local elapsed=$((SECONDS - start))
    
    # Progressive bar animation based on time (slows down as it approaches 100%)
    # This creates a more realistic-looking progress bar
    local progress_val=$((elapsed * 100))
    local percent=$((progress_val < 3000 ? progress_val / 30 : 100 - 10000 / (progress_val + 100)))
    if [ $percent -gt 99 ]; then
      percent=99
    fi
    
    local filled=$((percent * width / 100))
    local empty=$((width - filled))

    # Fancy gradient bar with different characters
    local bar=""
    if [ $filled -gt 0 ]; then
      bar="${bar}$(printf "%${filled}s" | tr ' ' '█')"
    fi
    if [ $empty -gt 0 ]; then
      bar="${bar}$(printf "%${empty}s" | tr ' ' '░')"
    fi

    # Dynamic status message
    local status=""
    if [ $elapsed -lt 5 ]; then
      status="Starting..."
    elif [ $percent -lt 30 ]; then
      status="Working..."
    elif [ $percent -lt 70 ]; then
      status="Processing..."
    else
      status="Finishing..."
    fi

    printf "\r  %s [%s] %3d%% | %s (%ds)" "$frame" "$bar" "$percent" "$status" "$elapsed"
    sleep 0.1
  done

  wait $pid
  local exit_code=$?
  
  # Clear the line and show completion
  printf "\r%s  [%s] %s | Completed in %ds\n" "✓" "$(printf "%${width}s" | tr ' ' '█')" "$label" $((SECONDS - start))
  echo ""
  
  return $exit_code
}


#####################
# INSTALLER FUNCTIONS
#####################

progress_run "Prepending external .zshrc content" \
  "TEMP_FILE=\$(mktemp); \
   curl -fsSL https://raw.githubusercontent.com/code2344/installers.scstudios.tech/refs/heads/main/macterm/.zshrc -o \"\$TEMP_FILE\"; \
   if ! grep -q '#####MACTERM V1.0 .ZSHRC BLOCK#####' ~/.zshrc 2>/dev/null; then \
       cat \"\$TEMP_FILE\" ~/.zshrc 2>/dev/null > ~/.zshrc.new; \
       mv ~/.zshrc.new ~/.zshrc; \
   fi; \
   rm \"\$TEMP_FILE\""


progress_run "Cloning Homebrew" \
  "git clone --depth=1 https://github.com/Homebrew/brew ~/.brew"


progress_run "Updating PATH in .zshrc" \
  "BREW_PATH='export PATH=\"\$HOME/.brew/bin:\$HOME/.brew/sbin:\$PATH\"'; \
   if ! grep -qxF \"\$BREW_PATH\" ~/.zshrc; then \
       echo \"\$BREW_PATH\" >> ~/.zshrc; \
   fi"


progress_run "Sourcing .zshrc" "source ~/.zshrc"


progress_run "Running brew update" "brew update || true"


progress_run 'Installing "tree" and "wget"' "brew install tree wget"


progress_run "Installing OpenCode" \
  "curl -fsSL https://opencode.ai/install | bash"


progress_run "Re-sourcing .zshrc" "source ~/.zshrc"


progress_run "Installing Ollama" \
  "curl -fsSL https://ollama.com/install.sh | sh"


progress_run "Re-sourcing .zshrc" "source ~/.zshrc"


progress_run "Enabling Safari Developer Tools" \
  "defaults write com.apple.Safari IncludeDevelopMenu -bool true; \
   defaults write com.apple.Safari WebKitPreferences.developerExtrasEnabled -bool true; \
   defaults write NSGlobalDomain WebKitDeveloperExtras -bool true"


###############################################

echo ""
echo "==============================================="
echo "           ✔ MacTerm Installer Complete!"
echo "==============================================="
echo "Open a new terminal window for PATH changes."
echo "Thank you so much for installing this. I am a small developer (and I'm only in high school), so any support is helpful. Please share this with whoever you feel like. Thanks!"
echo ""
sleep 8
open -a Safari "https://scstudios.tech/projects/macterm/thankyou"
