#!/bin/bash

# Check if script is run with sudo
if [ "$EUID" -eq 0 ]; then
    echo "Please run this script without sudo."
    exit 1
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Zsh
install_zsh() {
    if command_exists zsh; then
        echo "Zsh is already installed."
    else
        OS=$(uname -s)
        if [[ "$OS" == "Linux" ]]; then
            if [[ -e /etc/os-release ]]; then
                source /etc/os-release
                if [[ "$ID" == "ubuntu" || "$ID" == "debian" || "$ID" == "kali" ]]; then
                    echo "Installing Zsh on Debian-based system..."
                    sudo apt update
                    sudo apt install -y zsh
                elif [[ "$ID" == "arch" || "$ID" == "manjaro" ]]; then
                    echo "Installing Zsh on Arch-based system..."
                    sudo pacman -Syu --noconfirm zsh
                else
                    echo "Unsupported Linux distribution: $ID"
                    exit 1
                fi
            else
                echo "Unable to detect Linux distribution."
                exit 1
            fi
        elif [[ "$OS" == "Darwin" ]]; then
            echo "Installing Zsh on macOS..."
            brew install zsh
        else
            echo "Unsupported OS: $OS"
            exit 1
        fi
    fi
}


# Install Oh My Zsh
install_oh_my_zsh() {
    if [[ -e ~/.oh-my-zsh ]]; then
        echo "Oh-my-zsh is already installed."
    else
        echo "Installing Oh-my-zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi
}

# Set Zsh as the default shell
set_zsh_as_default() {
    if chsh -s "$(command -v zsh)"; then
        echo "Zsh has been set as the default shell."
    else
        echo "Failed to set Zsh as the default shell. You might need to add Zsh to the list of allowed shells."
        echo "Try adding $(command -v zsh) to /etc/shells and then rerun this script."
        exit 1
    fi
}

# Switch to Zsh
switch_to_zsh() {
    echo "Switching to Zsh..."
    exec zsh
}

# Install brew
if command_exists brew; then
  echo "Homebrew is already installed."
else
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ "$OS" != "Darwin" ]]; then
    (echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> ~/.zshrc
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi
  echo "Homebrew installed."
fi

# Install gum
if command_exists gum; then
  echo "gum is already installed"
else
  brew install gum
fi

# Main script
install_zsh
install_oh_my_zsh
set_zsh_as_default
switch_to_zsh

