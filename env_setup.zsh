#!/bin/zsh

# Helper functions

# Global variables
GLOBALS_verbose_mode=false
GLOBALS_interrupted=false
BLACK_ARCH_SETUP=false

# Function to display verbose messages
vecho() {
  if [[ "$GLOBALS_verbose_mode" == true ]]; then
    echo "$@"
  fi
}

# Parse command line options for verbose mode
while getopts "vb" opt; do
  case "$opt" in
    v)
      echo "verbose flag found"
      GLOBALS_verbose_mode=true
      ;;
    b)
      echo "blackarch flag found"
      BLACK_ARCH_SETUP=true
      ;;
    \?)
      echo "Usage: $(basename $0) [-v] [-b]"
      exit 1
      ;;
  esac
done

# Loading Animation Function using the emoji_monkey array
loading_animation() {
  local -a emoji_monkey=('🙉' '🙈' '🙊' '🙈')
  local -i index=0
  local -i sleep_duration=1  # Adjust speed of animation here

    # Hide cursor
    tput civis
    

    # Keep running until externally stopped
    while true; do
      # Print the current frame of animation
      printf "\rLoading ${emoji_monkey[index]}"

        # Update index for next frame
        (( index = (index + 1) % ${#emoji_monkey[@]} ))

        # Wait before the next frame
        sleep $sleep_duration
      done
    }

# Function to clean up on exit or interrupt
cleanup() {
  # Stop the loading animation
  if [[ -n "${loading_pid+x}" ]]; then
    kill "${loading_pid}" &>/dev/null
    wait "${loading_pid}" 2>/dev/null
  fi

    # Show cursor
    tput cnorm

    # Clear the line
    printf "\r%s\r" "$(printf ' %.0s' {1..8})"

    # Exit the script only if there was an interruption
    if [[ "$GLOBALS_interrupted" == true ]]; then
      exit 0
    fi
  }

# Function to set the interrupted flag
on_interrupt() {
  GLOBALS_interrupted=true
  cleanup
}

# Set trap for cleanup on SIGINT (Ctrl+C) and on_interrupt
set_interrupt_trap() {
  trap on_interrupt SIGINT
}

# Main script

# Detect OS and update/install necessary packages
OS=$(uname -s)
if [[ "$OS" == "Linux" ]]; then
  if [[ -e /etc/os-release ]]; then
    source /etc/os-release
    if [[ "$ID" == "ubuntu" || "$ID" == "debian" || "$ID" == "kali" || "$ID" == "linuxmint" ]]; then
      vecho "Detected Linux distribution: $ID"
      sudo apt-get update
    elif [[ "$ID" == "arch" || "$ID" == "manjaro" || "$ID" == "blackarch" ]]; then
      vecho "Detected Arch-based distribution: $ID"
      required_packages=("base-devel" "procps-ng" "curl" "file" "git" "mlocate" "bluez" "bluez-utils" "blueman" "pavucontrol" "btop" "xorg-xhost" "gparted" "openbsd-netcat" "kdeconnect")
      missing_packages=()

      for package in "${required_packages[@]}"; do
        if ! pacman -Qi "$package" &> /dev/null; then
          missing_packages+=("$package")
        fi
      done

      if [[ ${#missing_packages[@]} -eq 0 ]]; then
        vecho "All required packages are installed."
      else
        vecho "Missing packages: ${missing_packages[@]}"
        vecho "Installing required packages..."
        sudo pacman -Syu --needed --noconfirm ${missing_packages[@]}
        sudo updatedb
        vecho "Required packages installed."
        sudo systemctl enable bluetooth
        sudo systemctl start bluetooth

      fi

      if ! which yay &> /dev/null; then
        cd ~
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si
        cd ~ && rm -rf yay
        vecho "Yay installed."
      fi
    else
      echo "Unsupported Linux distribution: $ID"
      exit 1
    fi
  else
    echo "Unable to detect Linux distribution."
    exit 1
  fi
elif [[ "$OS" == "Darwin" ]]; then
  vecho "Detected MacOS"
else
  echo "Unsupported OS"
  exit 1
fi

install_coding_environment() {
  if [[ "$OS" == "Linux" ]]; then
    if [[ -e /etc/os-release ]]; then
      source /etc/os-release
      if [[ "$ID" == "ubuntu" || "$ID" == "debian" || "$ID" == "kali"|| "$ID" == "linuxmint" ]]; then
        vecho "Detected Linux distribution: $ID"
        required_packages=("build-essential" "procps" "curl" "file" "git")
        missing_packages=()

        for package in "${required_packages[@]}"; do
          if ! dpkg -l | grep -q "^ii  $package "; then
            missing_packages+=("$package")
          fi
        done

        if [[ ${#missing_packages[@]} -eq 0 ]]; then
          vecho "All required packages are installed."
        else
          vecho "Missing packages: ${missing_packages[@]}"
          vecho "Installing required packages..."
          sudo apt-get install -y ${missing_packages[@]}
          vecho "Required packages installed."
        fi
      elif [[ "$ID" == "arch" || "$ID" == "manjaro" || "$ID" == "blackarch" ]]; then
        vecho "Detected Arch-based distribution: $ID"
        required_packages=("base-devel" "procps-ng" "curl" "file" "git")
        missing_packages=()

        for package in "${required_packages[@]}"; do
          if ! pacman -Qi "$package" &> /dev/null; then
            missing_packages+=("$package")
          fi
        done

        if [[ ${#missing_packages[@]} -eq 0 ]]; then
          vecho "All required packages are installed."
        else
          vecho "Missing packages: ${missing_packages[@]}"
          vecho "Installing required packages..."
          sudo pacman -Syu --needed --noconfirm ${missing_packages[@]}
          vecho "Required packages installed."
        fi
      else
        vecho "Unsupported Linux distribution: $ID"
      fi
    else
      vecho "Unable to detect Linux distribution."
    fi
  elif [[ "$OS" == "Darwin" ]]; then
    vecho "Detected MacOS"
  fi

  install_homebrew_packages() {

    # Set trap for cleanup on SIGINT (Ctrl+C) and on_interrupt
    set_interrupt_trap
    # Start the loading animation in the background
    loading_animation &
    loading_pid=$!

    local required_packages=("neovim" "jandedobbeleer/oh-my-posh/oh-my-posh" "ripgrep" "node" "git" "make" "python" "npm")
    local missing_packages=()
    for package in "${required_packages[@]}"; do
      if ! $(brew list --full-name | grep -q "$package"); then
        missing_packages+=("$package")
      fi
    done

    # Call cleanup right after the package checking and installation are complete
    cleanup

    if [[ ${#missing_packages[@]} -eq 0 ]]; then
      vecho "All required brew packages are installed."
    else
      vecho "Missing brew packages: ${missing_packages[@]}"
      vecho "Installing required brew packages..."
      brew install ${missing_packages[@]}
      vecho "Required brew packages installed."
    fi
  }

  # Function to install Cargo/Rust
  install_rust() {
    if command -v cargo &> /dev/null; then
      vecho "Cargo/Rust is already installed."
    else
      vecho "Installing Cargo/Rust..."
      curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
      vecho "Cargo/Rust installed."
    fi
  }

  # Function to install zsh plugins
  install_zsh_plugins() {
    if [[ -e ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions ]]; then
      vecho "zsh-autosuggestions is already installed."
    else
      git clone https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    fi

    if [[ -e ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting ]]; then
      vecho "zsh-syntax-highlighting is already installed."
    else
      git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    fi

    if [[ -e ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting ]]; then
      vecho "fast-syntax-highlighting is already installed."
    else
      git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting
    fi
  }

  install_homebrew_packages
  install_rust
  install_zsh_plugins

  # Check for LunarVim installation
  if command -v lvim &> /dev/null; then
    vecho "LunarVim is already installed."
  else
	  LV_BRANCH='release-1.4/neovim-0.9' bash <(curl -s https://raw.githubusercontent.com/LunarVim/LunarVim/release-1.4/neovim-0.9/utils/installer/install.sh)
  fi

  # Append multiline string to ~/.zshrc if not already present
  multiline_string='eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
  eval "$(oh-my-posh init zsh --config $(brew --prefix oh-my-posh)/themes/1_shell.omp.json)"
fi
alias c="clear"
alias vim="lvim"
alias ll="ls -l"
alias clip="wl-copy"
open() {
    nohup dolphin "$@" > /dev/null 2>&1 &
    disown 
}

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/bin:$PATH"
neofetch

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
'



  if [[ $(cat $HOME/.zshrc | grep -Fx "$multiline_string") ]]; then
    vecho "The multiline string is already present in the $HOME/.zshrc file."
  else
    echo "$multiline_string" >> $HOME/.zshrc
    vecho "The multiline string has been added to the $HOME/.zshrc file."
  fi

  # Check for nvm installation
  if [[ "$(command -v nvm)" ]]; then
    vecho "nvm is already installed."
  else
    vecho "Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
    vecho "nvm installed."
  fi

  source $HOME/.zshrc
  if ! fc-list | grep -i "JetBrainsMono" &> /dev/null; then
    echo "select JetBrainsMono"
    oh-my-posh font install
  else
    echo "JetBrainsMono is already installed."
  fi

  if [[ -e $HOME/.config/nvim ]]; then
    vecho "neovim config already exists"
  else
    git clone https://github.com/chowe99/nvim-conf ~/.config/nvim
  fi

  if [[ -e $HOME/.config/lvim ]]; then
    vecho "LunarVim config already exists"
  else
    git clone https://github.com/chowe99/lvim-conf ~/.config/lvim
  fi

  echo "replace plugins in .zshrc with plugins=(git zsh-autosuggestions zsh-syntax-highlighting fast-syntax-highlighting)"
  echo ":TransparentEnable in LunarVim and NeoVim\nSuccess!"
}


install_steam() {
  yay -S steam
}

install_signal() {
  yay -S signal-desktop --noconfirm
}

install_searx() {
  # Function to generate random hex string of length 16
  generate_random_hex() {
    LC_CTYPE=C tr -dc 'a-f0-9' < /dev/urandom | head -c 16
  }

  # Install necessary packages
  sudo -H pacman -S --noconfirm \
    python python-pip python-lxml python-babel \
    uwsgi uwsgi-plugin-python \
    git base-devel libxml2

  # Create searxng user
  sudo -H useradd --shell /bin/bash --system \
    --home-dir "/usr/local/searxng" \
    --comment 'Privacy-respecting metasearch engine' \
    searxng
  sudo -H mkdir "/usr/local/searxng"
  sudo -H chown -R "searxng:searxng" "/usr/local/searxng"

# Install SearXNG & dependencies as searxng user
sudo -H -u searxng -i <<'EOF'
    git clone "https://github.com/searxng/searxng" "/usr/local/searxng/searxng-src"
    python3 -m venv "/usr/local/searxng/searx-pyenv"
    echo ". /usr/local/searxng/searx-pyenv/bin/activate" >> "/usr/local/searxng/.profile"
    exit
EOF

# Update pip and install initial dependencies
sudo -H -u searxng -i <<'EOF'
    . /usr/local/searxng/searx-pyenv/bin/activate
    pip install -U pip setuptools wheel pyyaml
    cd "/usr/local/searxng/searxng-src"
    pip install -e .
    exit
EOF

# Copy settings.yml template and generate secret_key
  sudo -H mkdir -p "/etc/searxng"
  sudo -H cp "/usr/local/searxng/searxng-src/utils/templates/etc/searxng/settings.yml" "/etc/searxng/settings.yml"
  sudo sed -i "s/ultrasecretkey/$(generate_random_hex)/" "/etc/searxng/settings.yml"
  sudo sed -i '/server:/a \  port: 8888' /etc/searxng/settings.yml


cat << EOF | sudo tee /etc/systemd/system/searxng.service > /dev/null
[Unit]
Description=SearxNG Metasearch Engine
After=network.target

[Service]
Type=simple
User=searxng
Group=searxng
WorkingDirectory=/usr/local/searxng/searxng-src
Environment="SEARXNG_SETTINGS_PATH=/etc/searxng/settings.yml"
ExecStart=/usr/local/searxng/searx-pyenv/bin/python searx/webapp.py
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
  sudo systemctl daemon-reload
  sudo systemctl enable searxng
  sudo systemctl start searxng
}

install_obsidian() {
  sudo wget -P /opt/Obsidian https://github.com/obsidianmd/obsidian-releases/releases/download/v1.6.5/Obsidian-1.6.5.AppImage
  ssh-keygen -t rsa -b 4096 -C "chowej99@gmail.com"
  cat $HOME/.ssh/id_rsa.pub
  git clone git@github.com:chowe99/vault.git $HOME/Documents/vault

  sudo mkdir -p $HOME/.local/share/applications/
  cat << EOF | sudo tee $HOME/.local/share/applications/obsidian.desktop
[Desktop Entry]
Version=1.0
Name=Obsidian
Comment=A powerful note-taking app
Exec=/opt/Obsidian/Obsidian-1.6.5.AppImage
Icon=/opt/Obsidian/obsidian.png  
Terminal=false
Type=Application
Categories=Utility;Office;

MimeType=x-scheme-handler/obsidian;
EOF
}


install_torguard() {
  if command -v torguard &> /dev/null; then
    echo "Torguard already installed."
    return 0
  fi
  cd $HOME
  wget https://updates.torguard.biz/Software/Linux/torguard-latest-amd64-arch.tar.gz 
  tar -xzf torguard-latest-amd64-arch.tar.gz
  cd torguard-v4.8.29-build.286.1+g70e4e51-amd64-arch
  makepkg -si --noconfirm
  cd $HOME && rm -rf tor*
  sudo nohup torguard > /dev/null &
  disown 
  echo "Please connect to the VPN then resume process (fg)..."
  kill -STOP $$
}


install_librewolf(){
  if command -v librewolf &> /dev/null; then
    echo "Librewolf already installed."
    return 0
  fi
  if [[ "$ID" == "arch" || "$ID" == "blackarch" || "$ID" == "manjaro" ]]; then
    yay -S librewolf-bin 
  elif [[ "$ID" == "ubuntu" || "$ID" == "debian" || "$ID" == "kali" ]]; then
    sudo apt update && sudo apt install -y wget gnupg lsb-release apt-transport-https ca-certificates

    distro=$(if echo " una bookworm vanessa focal jammy bullseye vera uma " | grep -q " $(lsb_release -sc) "; then lsb_release -sc; else echo focal; fi)

    wget -O- https://deb.librewolf.net/keyring.gpg | sudo gpg --dearmor -o /usr/share/keyrings/librewolf.gpg

    sudo tee /etc/apt/sources.list.d/librewolf.sources << EOF > /dev/null
Types: deb
URIs: https://deb.librewolf.net
Suites: $distro
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/librewolf.gpg
EOF
    sudo apt update
    sudo apt install librewolf -y
  fi
}


install_alfa_driver(){
  if locate rtl8821au &> /dev/null; then
    echo "rtl8821au drivers already installed."
    return 0
  fi
  if [[ "$ID" == "debian" || "$ID" == "kali" ]]; then
    sudo apt install -y linux-headers-$(uname -r) bc dkms libelf-dev rfkill iw
  elif [[ "$ID" == "ubuntu" ]]; then
    sudo apt install -y build-essential dkms iw
  elif [[ "$ID" == "arch" || "$ID" == "manjaro" || "$ID" == "blackarch" ]]; then

# Get the kernel release version
kernel_version=$(uname -r)

# Define regular expressions for kernel types
zen_regex="zen"
hardened_regex="hardened"
lts_regex="lts"

# Initialize variable to hold kernel type
kernel_type=""

# Check which kernel type matches
if echo "$kernel_version" | grep -qiE "$zen_regex"; then
  kernel_type="-zen"
elif echo "$kernel_version" | grep -qiE "$hardened_regex"; then
  kernel_type="-hardened"
elif echo "$kernel_version" | grep -qiE "$lts_regex"; then
  kernel_type="-lts"
fi

# Replace linux-hardened-headers with the detected kernel type
command_line="sudo pacman -S --noconfirm linux${kernel_type}-headers dkms git bc iw"

# Execute the command
echo "Executing: $command_line"
eval "$command_line"

  else
    echo "Incompatible distro for alfa driver."
    return 0
  fi

  mkdir -p $HOME/alfa && cd alfa
  git clone https://github.com/morrownr/8821au-20210708.git
  cd $HOME/alfa/8821au-20210708
  sudo sh install-driver.sh
  cd $HOME && rm -rf $HOME/alfa
  echo "now reboot to enable alfa drivers"
}

# install_dwm() {
#   if command -v dwm &> /dev/null && command -v dmenu &> /dev/null; then
#     echo "dwm and dmenu already installed."
#     return 0
#   fi
#   cd ~
#   git clone https://git.suckless.org/dwm
#   git clone https://git.suckless.org/dmenu
#   mkdir suckless && mv dwm dmenu suckless/
#   cd suckless/dwm
#   sudo make clean install
#   cd ../dmenu
#   sudo make clean install
#   cd ~ && rm -rf suckless
#   echo "exec dwm" > ~/.xinitrc
# }

install_qemu-kvm_arch() {
    # List of packages to check for installation
    packages=(archlinux-keyring qemu virt-manager virt-viewer dnsmasq vde2 bridge-utils openbsd-netcat ebtables iptables libguestfs)

    # Variable to track if qemu-kvm or its dependencies are installed
    is_qemu_kvm_installed=false

    # Check if each package in the list is installed
    for package in "${packages[@]}"; do
        if ! sudo pacman -Qi "$package" &>/dev/null; then
            is_qemu_kvm_installed=false
            break
        else
            is_qemu_kvm_installed=true
        fi
    done

    # If qemu-kvm or its dependencies are installed, prompt for reinstall
    if "$is_qemu_kvm_installed"; then
      read -rp "qemu-kvm or its required packages are already installed. Do you want to reinstall? (y/n): " reinstall_choice
      if [[ "$reinstall_choice" =~ ^[Yy]$ ]]; then
        sudo pacman -S --needed "${packages[@]}"
        echo "Reinstallation completed."
      else
        echo "Skipping reinstallation."
      fi
      exit 0
    fi

    sudo pacman -Syy --noconfirm
    sudo pacman -S --noconfirm archlinux-keyring
    sudo pacman -S --noconfirm qemu virt-manager virt-viewer dnsmasq vde2 bridge-utils openbsd-netcat
    sudo pacman -S --noconfirm ebtables iptables
    sudo pacman -S --noconfirm libguestfs
    sudo systemctl enable libvirtd.service
    sudo systemctl start libvirtd.service
    sudo usermod -a -G libvirt $(whoami)
    sudo systemctl restart libvirtd.service
    echo "qemu-kvm installed."
}

# Set up Black Arch environment if specified
install_blackarch(){
  if [[ "$ID" == "arch" ]]; then
    vecho "Setting up Black Arch environment..."

    if ! pacman -Q | grep -q "blackarch"; then
      vecho "Adding Black Arch repository..."
      curl -O https://blackarch.org/strap.sh
      echo 26849980b35a42e6e192c6d9ed8c46f0d6d06047 strap.sh | sha1sum -c
      chmod +x strap.sh
      sudo ./strap.sh
      echo "uncomment [multilib]\nInclude = /etc/pacman.d/mirrorlist\nIn /etc/pacman.conf then resume script with fg..."
      kill -STOP $$
      sudo pacman -Syu --noconfirm
      cat << EOF
# To list all of the available tools, run
$ sudo pacman -Sgg | grep blackarch | cut -d' ' -f2 | sort -u

# To install a category of tools, run
$ sudo pacman -S blackarch-<category>

# To see the blackarch categories, run
$ sudo pacman -Sg | grep blackarch

# To search for a specific package, run
$ pacman -Ss <package_name>

# Note - it maybe be necessary to overwrite certain packages when installing blackarch tools. If
# you experience "failed to commit transaction" errors, use the --needed and --overwrite switches
# For example:
$ sudo pacman -Syyu --needed --overwrite='*' <wanted-package> 
EOF
      vecho "Black Arch repository added."
   else
     vecho "Black Arch repository already exists."
   fi

    required_packages=("aircrack-ng" "wireshark-cli" "wireshark-qt" "wifite" "ffuf" "wpscan" "blackarch-artwork" "openbsd-netcat" "btop")
    missing_packages=()

    for package in "${required_packages[@]}"; do
      if ! pacman -Q | grep -q "$package"; then
        missing_packages+=("$package")
      fi
    done

    if [[ ${#missing_packages[@]} -eq 0 ]]; then
      vecho "All required Black Arch packages are installed."
    else
      vecho "Missing Black Arch packages: ${missing_packages[@]}"
      vecho "Installing required Black Arch packages..."
      sudo pacman -Syu --needed --noconfirm ${missing_packages[@]}
      vecho "Required Black Arch packages installed."
    fi
    sudo cp /etc/os-release /etc/os-release.bak
    cat << EOF | sudo tee /etc/os-release > /dev/null
NAME="BlackArch Linux"
PRETTY_NAME="BlackArch Linux"
ID=blackarch
ID_LIKE=arch
BUILD_ID=rolling
ANSI_COLOR="0:36"
HOME_URL="https://blackarch.org/"
DOCUMENTATION_URL="https://blackarch.org/guide.html"
SUPPORT_URL="https://blackarch.org/contact.html"
BUG_REPORT_URL="https://github.com/BlackArch/blackarch/issues"
LOGO=blackarch
EOF
    # install a notification daemon
    sudo pacman -S --noconfirm dunst
    mkdir -p $HOME/.config/dunst/
    cat << EOF | sudo tee ~/.config/dunst/dunstrc > /dev/null
[global]
font = Monospace 10
markup = full

[urgency_low]
background = "#333333"
foreground = "#FFFFFF"

[urgency_normal]
background = "#285577"
foreground = "#FFFFFF"

[urgency_critical]
background = "#900000"
foreground = "#FFFFFF"
EOF

  else
    echo "Blackarch can only be installed on a base arch distro."
  fi
}




# install waybar
install_blackarch_theme() {
  mkdir -p $HOME/.config/waybar/
  cat << EOF | sudo tee $HOME/.config/waybar/style.css > /dev/null
* {
    border: none;
    border-radius: 0;
    font-family: "Ubuntu Nerd Font";
    font-size: 13px;
    min-height: 0;
    color: red;
}

window#waybar {
    background: #2c2c2c;
    color: red;
}

#window {
    font-weight: bold;
    font-family: "Ubuntu";
}
#workspaces {
    padding: 0 5px;
}

#workspaces button {
    padding: 0 5px;
    background: transparent;
    color: white;
    border-top: 2px solid transparent;
}

#workspaces button.focused {
    color: #c9545d;
    border-top: 2px solid #c9545d;
}

#mode {
    background: #64727D;
    border-bottom: 3px solid white;
}

#clock, #battery, #cpu, #memory, #network, #pulseaudio, #custom-spotify, #tray, #mode {
    padding: 0 3px;
    margin: 0 5px;
}

#clock {
    font-weight: bold;
}

#battery {
}

#battery icon {
    color: red;
}

#battery.charging {
}

@keyframes blink {
    to {
        background-color: #ffffff;
        color: black;
    }
}

#battery.warning:not(.charging) {
    color: white;
    animation-name: blink;
    animation-duration: 0.5s;
    animation-timing-function: linear;
    animation-iteration-count: infinite;
    animation-direction: alternate;
}

#cpu {
}

#memory {
}

#network {
}

#network.disconnected {
    background: #f53c3c;
}

#pulseaudio {
}

#pulseaudio.muted {
}

#custom-spotify {
    color: rgb(102, 220, 105);
}

#tray {
}
EOF

  # install waybar config
  cat << EOF | sudo tee $HOME/.config/waybar/config.jsonc > /dev/null
{
    "layer": "top", // Waybar at top layer
    "position": "top", // Waybar at the bottom of your screen
    "height": 24, // Waybar height
    // "width": 1366, // Waybar width
    // Choose the order of the modules
    "modules-left": ["hyprland/workspaces", "hyprland/mode", "custom/media"],

    "modules-center": ["hyprland/window"],
    "modules-right": ["pulseaudio", "network", "cpu", "memory", "battery", "tray", "clock"],
    "hyprland/workspaces": {
        "disable-scroll": true,
        "all-outputs": false,
        "format": "{icon}",
        "format-icons": {
            "1:web": "",
            "2:code": "",
            "3:term": "",
            "4:work": "",
            "5:music": "",
            "6:docs": "",
            "urgent": "",
            "focused": "",
            "default": ""
        }
    },
    "hyprland/mode": {
        "format": "<span style=\"italic\">{}</span>"
    },
    "tray": {
        // "icon-size": 21,
        "spacing": 10
    },
    "clock": {
        "format-alt": "{:%Y-%m-%d}"
    },
    "cpu": {
        "format": "{usage}% "
    },
    "memory": {
        "format": "{}% "
    },
    "battery": {
        "bat": "$(upower -e | grep -o 'BAT[0-9]*')",
        "states": {
            // "good": 95,
            "warning": 30,
            "critical": 15
        },
        "format": "{capacity}% {icon}",
        // "format-good": "", // An empty format will hide the module
        // "format-full": "",
        "format-icons": ["", "", "", "", ""]
    },
    "network": {
        // "interface": "wlp2s0", // (Optional) To force the use of this interface
        "format-wifi": "{essid} ({signalStrength}%) ",
        "format-ethernet": "{ifname}: {ipaddr}/{cidr} ",
        "format-disconnected": "Disconnected ⚠"
    },
    "pulseaudio": {
        //"scroll-step": 1,
        "format": "{volume}% {icon}",
        "format-bluetooth": "{volume}% {icon}",
        "format-muted": "",
        "format-icons": {
            "headphones": "",
            "handsfree": "",
            "headset": "",
            "phone": "",
            "portable": "",
            "car": "",
            "default": ["", ""]
        },
        "on-click": "pavucontrol"
    },
    "custom/spotify": {
        "format": " {}",
        "max-length": 40,
        "interval": 30, // Remove this if your script is endless and write in loop
        "exec": "$HOME/.config/waybar/mediaplayer.sh 2> /dev/null", // Script in resources folder
        "exec-if": "pgrep spotify"
    }
}
EOF

  cat << EOF | sudo tee $HOME/.config/waybar/mediaplayer.sh > /dev/null
#!/bin/sh
player_status=\$(playerctl status 2> /dev/null)
if [ "\$player_status" = "Playing" ]; then
    echo "\$(playerctl metadata artist) - \$(playerctl metadata title)"
elif [ "\$player_status" = "Paused" ]; then
    echo " \$(playerctl metadata artist) - \$(playerctl metadata title)"
fi
EOF

  chmod +x $HOME/.config/waybar/mediaplayer.sh

  # Install hyprpaper 
  sudo pacman -S --noconfirm hyprpaper
  cat << EOF | sudo tee $HOME/.config/hypr/hyprpaper.conf > /dev/null
preload = /usr/share/blackarch/artwork/wallpaper/wallpaper-fog.jpg

#if more than one preload is desired then continue to preload other backgrounds
# preload = /path/to/next_image.png
# .. more preloads

#set the default wallpaper(s) seen on initial workspace(s) --depending on the number of monitors used
wallpaper = $(xrandr --query | grep " connected" | awk 'NR==1{print $1}' | sed -r 's/ connected//'),/usr/share/blackarch/artwork/wallpaper/wallpaper-fog.jpg

#if more than one monitor in use, can load a 2nd image
wallpaper = $(xrandr --query | grep " connected" | awk 'NR==2{print $1}' | sed -r 's/ connected//'),/usr/share/blackarch/artwork/wallpaper/wallpaper-fog.jpg
# .. more monitors

#enable splash text rendering over the wallpaper
splash = true

#fully disable ipc
# ipc = off
EOF

    # install blackarch colourscheme
    mkdir -p $HOME/.dotfiles/waybar/
    cat << EOF | tee $HOME/.dotfiles/waybar/blackarch_theme.json > /dev/null
{
  "colors": {
    "color0": "#333333",   
    "color1": "#FF0000",   
    "color2": "#FF4300",   
    "color3": "#555555",   
    "color4": "#cd11e8",   
    "color5": "#cd11e8",   
    "color6": "#ff0000",   
    "color7": "#1f1f1f",   
    "color8": "#666666",   
    "color9": "#ff0000",   
    "color10": "#444444",  
    "color11": "#ffffff",  
    "color12": "#111111",  
    "color13": "#444444",  
    "color14": "#ff0000",  
    "color15": "#ff0000"   
  },
  "special": {
    "foreground": "#eeeeee",  
    "background": "#000000",  
    "cursor": "#ffffff"       
  }
}
EOF

    cat << EOF | sudo tee $(brew --prefix oh-my-posh)/themes/1_shell.omp.json > /dev/null
{
  "\$schema": "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json",
  "blocks": [
    {
      "alignment": "left",
      "newline": true,
      "segments": [
        {
          "foreground": "#FF0000",
          "leading_diamond": "<#FF0000> \ue200 </>",
          "properties": {
            "display_host": true
          },
          "style": "diamond",
          "template": "{{ .UserName }} <#ffffff>on</>",
          "type": "session"
        },
        {
          "foreground": "#FF0000",
          "properties": {
            "time_format": "Monday <#>at</> 3:04 PM"
          },
          "style": "diamond",
          "template": " {{ .CurrentDate | date .Format }} ",
          "type": "time"
        },
        {
          "foreground": "#cd11e8",
          "properties": {
            "branch_icon": "\ue725 ",
            "fetch_stash_count": true,
            "fetch_status": true,
            "fetch_upstream_icon": true,
            "fetch_worktree_count": true
          },
          "style": "diamond",
          "template": " {{ .UpstreamIcon }}{{ .HEAD }}{{if .BranchStatus }} {{ .BranchStatus }}{{ end }}{{ if .Working.Changed }} \uf044 {{ .Working.String }}{{ end }}{{ if and (.Working.Changed) (.Staging.Changed) }} |{{ end }}{{ if .Staging.Changed }} \uf046 {{ .Staging.String }}{{ end }}{{ if gt .StashCount 0 }} \ueb4b {{ .StashCount }}{{ end }} ",
          "type": "git"
        }
      ],
      "type": "prompt"
    },
    {
      "alignment": "right",
      "segments": [
        {
          "foreground": "#FF0000",
          "style": "plain",
          "type": "text"
        },
        {
          "foreground": "#FF0000",
          "properties": {
            "style": "dallas",
            "threshold": 0
          },
          "style": "diamond",
          "template": " {{ .FormattedMs }}s <#ffffff>\ue601</>",
          "type": "executiontime"
        },
        {
          "properties": {
            "root_icon": "\uf292 "
          },
          "style": "diamond",
          "template": " \uf0e7 ",
          "type": "root"
        },
        {
          "foreground": "#FF0000",
          "style": "diamond",
          "template": " <#ffffff>MEM:</> {{ round .PhysicalPercentUsed .Precision }}% ({{ (div ( (sub .PhysicalTotalMemory .PhysicalFreeMemory)|float64) 1073741824.0) }}/{{ (div .PhysicalTotalMemory 1073741824.0) }}GB)",
          "type": "sysinfo"
        }
      ],
      "type": "prompt"
    },
    {
      "alignment": "left",
      "newline": true,
      "segments": [
        {
          "foreground": "#ff0000",
          "leading_diamond": "<#FF0000> \ue285 </><#ff0000>{</>",
          "properties": {
            "folder_icon": "\uf07b",
            "folder_separator_icon": " \uebcb ",
            "home_icon": "home",
            "style": "agnoster_full"
          },
          "style": "diamond",
          "template": " \ue5ff {{ .Path }} ",
          "trailing_diamond": "<#ff0000>}</>",
          "type": "path"
        },
        {
          "foreground": "#00FF00",
          "foreground_templates": ["{{ if gt .Code 0 }}#ef5350{{ end }}"],
          "properties": {
            "always_enabled": true
          },
          "style": "plain",
          "template": " \ue286 ",
          "type": "status"
        }
      ],
      "type": "prompt"
    }
  ],
  "console_title_template": "{{ .Folder }}",
  "transient_prompt": {
    "background": "#000000",
    "foreground": "#eeeeee",
    "template": "\ue285 "
  },
  "version": 2
}
EOF

    brew install pipx
    pipx install pywal
    wal --theme $HOME/.dotfiles/waybar/blackarch_theme.json
    echo "Black Arch theme installed successfully."
}

install_hyprland_config() {
  # install waybar
  sudo pacman -S --noconfirm waybar
  mkdir -p $HOME/.config/waybar

  # make terminal transparent and add JetBrainsMono font
  mkdir -p $HOME/.config/kitty/
  cat << EOF | sudo tee $HOME/.config/kitty/kitty.conf > /dev/null
background_opacity 0.8
force_background_opacity true
# font
font_family       JetBrainsMono NF SemiBold # Replace with your font name (e.g., "Monaco", "Consolas", etc.)
bold_font         JetBrainsMono NF Bold
italic_font       JetBrainsMono NF Italic 
bold_italic_font  JetBrainsMono NF Bold Italic
EOF

  # install an authentication agent
  sudo pacman -S --noconfirm polkit-kde-agent

  # add qt packages
  sudo pacman -S --noconfirm qt5-wayland qt6-wayland qt5ct qt6ct
  echo "set qt theme by calling qt5ct and qt6ct"
  echo "export QT_QPA_PLATFORMTHEME=qt6ct  # Replace qt5ct with qt6ct if configuring for Qt6" >> $HOME/.zshrc

  cat << EOF | tee $HOME/.config/hypr/hyprland.conf > /dev/null
# This is an example Hyprland config file.
# Refer to the wiki for more information.
# https://wiki.hyprland.org/Configuring/Configuring-Hyprland/

# Please note not all available settings / options are set here.
# For a full list, see the wiki

# You can split this configuration into multiple files
# Create your files separately and then link them to this file like this:
# source = ~/.config/hypr/myColors.conf


###################
### MY PROGRAMS ###
###################

# See https://wiki.hyprland.org/Configuring/Keywords/

# Set programs that you use
\$terminal = kitty
\$fileManager = dolphin
\$menu = wofi --show drun


#################
### AUTOSTART ###
#################

# Autostart necessary processes (like notifications daemons, status bars, etc.)
# Or execute your favorite apps at launch like this:

exec-once = \$terminal & waybar & hyprpaper & /usr/lib/polkit-kde-authentication-agent-1
# exec-once = nm-applet &
#exec-once=[workspace 2 silent] librewolf

#############################
### ENVIRONMENT VARIABLES ###
#############################

# See https://wiki.hyprland.org/Configuring/Environment-variables/

env = XCURSOR_SIZE,24
env = HYPRCURSOR_SIZE,24


#####################
### LOOK AND FEEL ###
#####################

# Refer to https://wiki.hyprland.org/Configuring/Variables/

# https://wiki.hyprland.org/Configuring/Variables/#general
general { 
    gaps_in = 1
    gaps_out = 8 

    border_size = 2

    # https://wiki.hyprland.org/Configuring/Variables/#variable-types for info about colors
    col.active_border = rgba(ff0000ff) rgba(ff005144) 90deg
    col.inactive_border = rgba(595959aa)

    # Set to true enable resizing windows by clicking and dragging on borders and gaps
    resize_on_border = true

    # Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
    allow_tearing = false

    layout = dwindle 
}


# https://wiki.hyprland.org/Configuring/Variables/#decoration
decoration {
    rounding = 5

    # Change transparency of focused and unfocused windows
    active_opacity = 1.0
    inactive_opacity = 0.8

    drop_shadow = false
    shadow_range = 10
    shadow_render_power = 10
    col.shadow = rgba(ff0000ee)

    # https://wiki.hyprland.org/Configuring/Variables/#blur
    blur {
        enabled = true
        size = 3
        passes = 1
        
        vibrancy = 0.1696
    }
}

# https://wiki.hyprland.org/Configuring/Variables/#animations
animations {
    enabled = true

    # Default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more

    bezier = myBezier, 0.05, 0.9, 0.1, 1.05

    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border, 1, 10, default
    animation = borderangle, 1, 8, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}

# See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
dwindle {
    pseudotile = true # Master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
    preserve_split = true # You probably want this
}

# See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
#master {
#    new_status = master
#}

# https://wiki.hyprland.org/Configuring/Variables/#misc
misc { 
    force_default_wallpaper = -1 # Set to 0 or 1 to disable the anime mascot wallpapers
    disable_hyprland_logo = true # If true disables the random hyprland logo / anime girl background. :(
}


#############
### INPUT ###
#############

# https://wiki.hyprland.org/Configuring/Variables/#input
input {
    kb_layout = us
    kb_variant =
    kb_model =
    kb_options =
    kb_rules =

    follow_mouse = 1

    sensitivity = 0 # -1.0 - 1.0, 0 means no modification.

    touchpad {
        natural_scroll = false
    }
}

# https://wiki.hyprland.org/Configuring/Variables/#gestures
gestures {
    workspace_swipe = true
}

# Example per-device config
# See https://wiki.hyprland.org/Configuring/Keywords/#per-device-input-configs for more
device {
    name = epic-mouse-v1
    sensitivity = -0.5
}


####################
### KEYBINDINGSS ###
####################

# See https://wiki.hyprland.org/Configuring/Keywords/
\$mainMod = SUPER # Sets "Windows" key as main modifier

# Example binds, see https://wiki.hyprland.org/Configuring/Binds/ for more
bind = \$mainMod, T, exec, \$terminal
bind = \$mainMod, Q, killactive,
bind = \$mainMod, M, exit,
bind = \$mainMod, E, exec, \$fileManager
bind = \$mainMod, V, togglefloating,
bind = \$mainMod, SPACE, exec, if ! pgrep wofi; then \$menu; fi
bind = \$mainMod, P, pseudo, # dwindle
bind = \$mainMod, Z, togglesplit, # dwindle

# Move focus with mainMod + arrow keys
bind = \$mainMod, left, movefocus, l
bind = \$mainMod, right, movefocus, r
bind = \$mainMod, up, movefocus, u
bind = \$mainMod, down, movefocus, d
bind = \$mainMod SHIFT, H, movefocus, l
bind = \$mainMod SHIFT, L, movefocus, r
bind = \$mainMod SHIFT, K, movefocus, u
bind = \$mainMod SHIFT, J, movefocus, d

# Switch workspaces with mainMod + [0-9]
bind = \$mainMod, 1, workspace, 1
bind = \$mainMod, 2, workspace, 2
bind = \$mainMod, 3, workspace, 3
bind = \$mainMod, 4, workspace, 4
bind = \$mainMod, 5, workspace, 5
bind = \$mainMod, 6, workspace, 6
bind = \$mainMod, 7, workspace, 7
bind = \$mainMod, 8, workspace, 8
bind = \$mainMod, 9, workspace, 9
bind = \$mainMod, 0, workspace, 10

# Move active window to a workspace with mainMod + SHIFT + [0-9]
bind = \$mainMod SHIFT, 1, movetoworkspace, 1
bind = \$mainMod SHIFT, 2, movetoworkspace, 2
bind = \$mainMod SHIFT, 3, movetoworkspace, 3
bind = \$mainMod SHIFT, 4, movetoworkspace, 4
bind = \$mainMod SHIFT, 5, movetoworkspace, 5
bind = \$mainMod SHIFT, 6, movetoworkspace, 6
bind = \$mainMod SHIFT, 7, movetoworkspace, 7
bind = \$mainMod SHIFT, 8, movetoworkspace, 8
bind = \$mainMod SHIFT, 9, movetoworkspace, 9
bind = \$mainMod SHIFT, 0, movetoworkspace, 10

# Move active window
bind = \$mainMod CTRL, right, movewindow, r
bind = \$mainMod CTRL, left, movewindow, l
bind = \$mainMod CTRL, up, movewindow, u
bind = \$mainMod CTRL, down, movewindow, d

# Example special workspace (scratchpad)
bind = \$mainMod, S, togglespecialworkspace, magic
bind = \$mainMod SHIFT, S, movetoworkspace, special:magic

# MacOS navigate windows
bind = CTRL ALT, right, workspace, e+1
bind = CTRL ALT, left, workspace, e-1

# Scroll through existing workspaces with mainMod + scroll
bind = \$mainMod, mouse_down, workspace, e+1
bind = \$mainMod, mouse_up, workspace, e-1

# Move/resize windows with mainMod + LMB/RMB and dragging
bindm = \$mainMod, mouse:272, movewindow
bindm = \$mainMod, mouse:273, resizewindow

# wayland restart bind
bind = \$mainMod SHIFT, B, exec, killall waybar && waybar

# hyprshot
bind = CTRL ALT, S, exec, hyprshot -m region --clipboard-only


##############################
### WINDOWS AND WORKSPACES ###
##############################
# workspace = 2,on-created-empty: kitty

# See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
# See https://wiki.hyprland.org/Configuring/Workspace-Rules/ for workspace rules

# Example windowrule v1
# windowrule = float, ^(kitty)$

# Example windowrule v2
# windowrulev2 = float,class:^(kitty)$,title:^(kitty)$

windowrulev2 = suppressevent maximize, class:.* # You'll probably like this.
env = LIBVA_DRIVER_NAME,nvidia
env = XDG_SESSION_TYPE,wayland
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia

cursor {
	no_hardware_cursors = true
}

################
### MONITORS ###
################

# See https://wiki.hyprland.org/Configuring/Monitors/
monitor=$(xrandr --query | grep " connected" | awk 'NR==2{print $1}' | sed -r 's/ connected//'),highres@highrr,auto,1.25
monitor=$(xrandr --query | grep " connected" | awk 'NR==1{print $1}' | sed -r 's/ connected//'),highres@highrr,auto,auto
EOF

  yay -S hyprshot --noconfirm
}

hyprland_laptop_config () {
  # setup lid-handler script
  sudo pacman -S --noconfirm acpid
  sudo mkdir -p /etc/acpi
  cat << EOF | sudo tee /etc/acpi/lid-handler.sh > /dev/null
#!bin/bash

# Check if the lid is closed
lid_state=\$(cat /proc/acpi/button/lid/LID0/state | awk '{print $2}')

if [ "\$lid_state" = "closed" ]; then
    # Disable the laptop monitor
    sed -i '\$d' \$HOME/.config/hypr/hyprland.conf
    echo 'monitor=eDP-1,disable' >> \$HOME/.config/hypr/hyprland.conf

  elif [ "\$lid_state" = "open" ]; then
    # Enable the laptop monitor
    sed -i '\$d' \$HOME/.config/hypr/hyprland.conf
    echo 'monitor=eDP-1,1920x1200@60,0x0,1.33' >> \$HOME/.config/hypr/hyprland.conf
fi

# Reload Hyperctl (replace with the actual command you need to run)
hyprctl reload
EOF

  sudo chmod +x /etc/acpi/lid-handler.sh
  cat << EOF | sudo tee /etc/acpi/events/lid > /dev/null
event=button/lid.*
action=/etc/acpi/lid-handler.sh
EOF

}

install_ollama_webui() {
  if [[ "$OS" != "Linux" ]]; then
    echo "Only available on Linux."
    exit 0
  fi

  if [[ -e /etc/os-release ]]; then
    source /etc/os-release
  else
    echo "Cannot detect Linux distribution."
    exit 1
  fi

  if [[ "$ID" == "ubuntu" || "$ID" == "debian" || "$ID" == "kali" || "$ID" == "linuxmint" ]]; then
    echo "Detected Linux distribution: $ID"
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl
  elif [[ "$ID" == "arch" || "$ID" == "manjaro" || "$ID" == "blackarch" ]]; then
    echo "Detected Linux distribution: $ID"
    sudo pacman -Syu --noconfirm
    sudo pacman -S --noconfirm ca-certificates curl
  else
    echo "Unsupported Linux distribution: $ID"
    exit 1
  fi
  
  if [[ $(ollama) ]]; then
    curl -fsSL https://ollama.com/install.sh | sh
    ollama pull llama3
  else
    read -rp "Ollama is already installed. Do you want to reinstall? (y/n): " reinstall_choice
    if [[ "$reinstall_choice" =~ ^[Yy]$ ]]; then
      curl -fsSL https://ollama.com/install.sh | sh
      ollama pull llama3
    elif [[ "$reinstall_choice" =~ ^[Nn]$ ]]; then
      echo "skipping reinstallation"
    else

    fi 
  fi


  # Install Docker
  if [[ "$ID" == "ubuntu" || "$ID" == "debian" || "$ID" == "kali" || "$ID" == "linuxmint" ]]; then
    # Add Docker's official GPG key and repository for apt-get
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc > /dev/null
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  elif [[ "$ID" == "arch" || "$ID" == "manjaro" || "$ID" == "blackarch" ]]; then
    # Install Docker for pacman
    sudo pacman -S --noconfirm docker
    sudo systemctl start docker
    sudo systemctl enable docker
  fi

  # Run open-webui container
  sudo docker run -d --network=host -v open-webui:/app/backend/data -e OLLAMA_BASE_URL=http://127.0.0.1:11434 --name open-webui --restart always ghcr.io/open-webui/open-webui:main

  cat << EOF | sudo tee /etc/systemd/system/docker-webui.service > /dev/null
[Unit]
Description=Start Docker container for open-webui at startup
After=docker.service
Wants=docker.service

[Service]
Type=simple
ExecStart=/usr/bin/docker start open-webui
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

  cat << EOF | sudo tee /etc/systemd/system/webui.service > /dev/null 
[Unit]
Description=Run webui.sh script at startup
After=docker-webui.service
Wants=docker-webui.service

[Service]
Type=simple
User=$(whoami)
WorkingDirectory=$HOME/.stable-diffusion-webui
Environment=PYENV_ROOT=$HOME/.pyenv
ExecStart=/bin/zsh -lc 'source $HOME/.zshrc; pyenv global 3.10.6; ./webui.sh --listen --api'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl enable webui.service
  sudo systemctl enable docker-webui.service

  # Install Stable Diffusion dependencies

  if [[ "$ID" == "ubuntu" || "$ID" == "debian" || "$ID" == "kali" || "$ID" == "linuxmint" ]]; then
    sudo apt-get install -y make build-essential libssl-dev zlib1g-dev \
      libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev \
      libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev git
  elif [[ "$ID" == "arch" || "$ID" == "manjaro" || "$ID" == "blackarch" ]]; then
    sudo pacman -S --noconfirm base-devel openssl zlib bzip2 readline sqlite wget curl llvm ncurses \
      xz tk libffi lzma git
  fi

  brew install pyenv
  cat << EOF | tee $HOME/.zshrc > /dev/null
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
EOF
  source $HOME/.zshrc

  pyenv install 3.10.6
  pyenv global 3.10.6
  wget -q -P $HOME/.stable-diffusion-webui/ https://raw.githubusercontent.com/AUTOMATIC1111/stable-diffusion-webui/master/webui.sh
  chmod +x $HOME/.stable-diffusion-webui/webui.sh
  echo "once it is ready ctrl+c to exit and resume script"
  sh $HOME/.stable-diffusion-webui/webui.sh --listen --api &
  # Wait for the user to press Ctrl+C 
  echo "WebUI is running. Please press Ctrl+C once it is ready to exit and resume the script."
  wait $WEBUI_PID

}



OPTIONS=(
    "Torguard"
    "Coding environment"
    "Steam"
    "Signal"
    "SearX"
    "Obsidian"
    "Librewolf"
    "Alfa driver"
    # "dwm"
    "Black Arch"
    "Black Arch Theme"
    "Hyprland Config"
    "qemu-kvm Arch Linux"
    "Ollama and Stable Diffusion Webui"
)


echo "Choose which software to install:"
# Splitting $CHOICES into an array using newline as the delimiter
IFS=$'\n' CHOICES=($(gum choose --no-limit "${OPTIONS[@]}"))

for CHOICE in "${CHOICES[@]}"; do
    echo "CHOICE: $CHOICE"
    if [ "$CHOICE" = "Torguard" ]; then
        vecho "torguard selected"
        install_torguard
    elif [ "$CHOICE" = "Coding environment" ]; then
        vecho "found coding env"
        install_coding_environment
    elif [ "$CHOICE" = "Steam" ]; then
        vecho "found steam"
        install_steam
    elif [ "$CHOICE" = "Signal" ]; then
        vecho "found Signal"
        install_signal
    elif [ "$CHOICE" = "SearX" ]; then
        vecho "found SearX"
        install_searx
    elif [ "$CHOICE" = "Obsidian" ]; then
        vecho "found Obsidian"
        install_obsidian
    elif [ "$CHOICE" = "Librewolf" ]; then
        vecho "librewolf selected"
        install_librewolf
    elif [ "$CHOICE" = "Alfa driver" ]; then
        vecho "alfa driver selected"
        install_alfa_driver
    elif [ "$CHOICE" = "Black Arch" ]; then
        vecho "blackarch selected"
        install_blackarch
    elif [ "$CHOICE" = "Black Arch Theme" ]; then
        vecho "blackarch theme selected"
        install_blackarch_theme
    elif [ "$CHOICE" = "Hyprland Config" ]; then
        vecho "Hyprland config selected"
        install_hyprland_config
        if [ -d "/sys/class/power_supply/$(upower -e | grep -o 'BAT[0-9]*')" ]; then
          vecho "You have a laptop."
          hyprland_laptop_config
        else
          vecho "No laptop detected. Skipping lid-related setup."
        fi
    elif [ "$CHOICE" = "qemu-kvm Arch Linux" ]; then
        vecho "qemu Arch selected"
        install_qemu-kvm_arch
    elif [ "$CHOICE" = "Ollama and Stable Diffusion Webui" ]; then
        vecho "Ollama webui selected"
        install_ollama_webui
    else
        echo "Unknown choice: $CHOICE"
    fi
done


echo "Setup finished successfully."
