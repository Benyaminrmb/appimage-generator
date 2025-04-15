# 🚀 AppImage Integrator

<div align="center">

![AppImage Integrator](https://img.shields.io/badge/AppImage-Integrator-blue?style=for-the-badge&logo=linux&logoColor=white)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
![Bash](https://img.shields.io/badge/Bash-4.4+-green.svg?style=for-the-badge&logo=gnu-bash&logoColor=white)

A powerful tool to seamlessly integrate AppImage applications into your Linux desktop environment.

</div>

## ✨ Features

- 🔥 One-click AppImage integration
- 🎯 Automatic desktop entry creation
- 🖼️ Icon extraction and installation
- 🔒 Sandboxing support (Firejail, Flatpak)
- 🧹 Clean uninstallation
- 🎨 Beautiful terminal UI
- ⚡ Fast and efficient

## 🚀 Quick Install

```bash
# Install with one command
curl -fsSL https://raw.githubusercontent.com/Benyaminrmb/appimage-generator/main/install.sh | sudo bash
```

## 📖 Usage

```bash
# Full command
appimage-integrator /path/to/your/app.AppImage

# Shorter command
appimage /path/to/your/app.AppImage

# List installed AppImages
appimage --list

# Remove an AppImage
appimage --remove AppName
```

## 🎮 Command Options

```bash
Options:
  -h, --help              Show help message
  -v, --verbose           Enable verbose output
  -f, --force            Force overwrite existing files
  -n, --name NAME        Set custom application name
  -c, --categories CATS  Set application categories
  -s, --sandbox MODE     Set sandbox mode
  -d, --directory DIR    Set custom directory
  -a, --autostart       Add to autostart
  -l, --list            List installed AppImages
  -r, --remove NAME     Remove an AppImage
```

## 🛡️ Sandbox Modes

- `none`: No sandboxing
- `firejail`: Use Firejail for sandboxing
- `flatpak-spawn`: Run within Flatpak environment
- `default`: Automatic detection

## 📁 Directory Structure

```
~/.local/
├── bin/appimages/         # AppImage files
├── share/
    ├── applications/      # Desktop entries
    └── icons/appimages/  # Extracted icons
```

## 🔧 Manual Installation

```bash
# Clone the repository
git clone https://github.com/Benyaminrmb/appimage-generator.git

# Enter the directory
cd appimage-generator

# Install
sudo ./install.sh
```

## 🤝 Contributing

Contributions are welcome! Feel free to:

1. Fork the repository
2. Create a new branch
3. Make your changes
4. Submit a pull request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👤 Author

**Benyamin Bolhassani**

- GitHub: [@Benyaminrmb](https://github.com/Benyaminrmb)

## ⭐ Show your support

Give a ⭐️ if this project helped you! 