#!/usr/bin/env bash
# OCI CLI Preflight Check for KASM
# This is a wrapper that calls the centralized preflight check script
# Located in the /oci folder for DRY principle compliance

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OCI_DIR="$(cd "$SCRIPT_DIR/../oci" && pwd)"

# Colors for output
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}🔍 KASM OCI CLI Preflight Check (using centralized OCI scripts)${NC}"
echo "================================================================"
echo ""

# Check if centralized script exists
if [ ! -f "$OCI_DIR/preflight-check.sh" ]; then
    echo -e "${RED}❌ Error: Centralized preflight script not found at $OCI_DIR/preflight-check.sh${NC}"
    exit 1
fi

# Pass all arguments to the centralized preflight check script
bash "$OCI_DIR/preflight-check.sh" "$@"

# The centralized script will handle all checks and exit codes

detect_os() {
  # Return: windows|linux|macos|unknown ; WSL counted as linux
  if grep -qi microsoft /proc/version 2>/dev/null; then
    echo "linux"
    return
  fi
  case "${OSTYPE:-}" in
    linux*)  echo "linux" ;;
    darwin*) echo "macos" ;;
    msys*|cygwin*|win32*) echo "windows" ;;
    *) echo "unknown" ;;
  esac
}

OS="${PREFERRED_PLATFORM:-$(detect_os)}"
ARCH="$(uname -m 2>/dev/null || echo unknown)"

echo -e "${YELLOW}📋 System:${NC} OS=${OS} Arch=${ARCH}\n"

have() { command -v "$1" >/dev/null 2>&1; }

oci_version() { oci --version 2>/dev/null || true; }

ensure_path_active_msg() {
  if [[ "$OS" = "linux" || "$OS" = "macos" ]]; then
    echo -e "${YELLOW}⚠️  If 'oci' not found, restart your terminal or run:${NC}"
    echo -e "${WHITE}   source ~/.bashrc   ${GRAY}(bash)${NC}"
    echo -e "${WHITE}   source ~/.zshrc    ${GRAY}(zsh)${NC}"
  else
    echo -e "${YELLOW}⚠️  Open a new PowerShell/terminal window so PATH updates apply.${NC}"
  fi
}

check_config() {
  echo -e "${YELLOW}🔍 Checking OCI configuration...${NC}"
  local cfg
  if [[ "$OS" = "windows" ]]; then
    # Git Bash sets HOME; prefer HOME for .oci on Windows too
    cfg="${HOME}/.oci/config"
  else
    cfg="${HOME}/.oci/config"
  fi
  if [[ -f "$cfg" ]]; then
    echo -e "${GREEN}✅ Found config: $cfg${NC}"
    # Quick smoke test: AD list (no tenancy env required if DEFAULT is set up)
    if oci iam availability-domain list >/dev/null 2>&1; then
      echo -e "${GREEN}✅ CLI appears authenticated (DEFAULT profile).${NC}"
      return 0
    fi
    echo -e "${YELLOW}⚠️  CLI installed but auth may be incomplete. Run: ${WHITE}oci setup config${NC}"
    return 1
  else
    echo -e "${YELLOW}⚠️  No config at ${WHITE}$cfg${NC}\n   Run: ${WHITE}oci setup config${NC}"
    return 1
  fi
}

# 1) Already installed?
echo -e "${YELLOW}🔎 Looking for OCI CLI...${NC}"
if have oci; then
  echo -e "${GREEN}✅ OCI CLI present:${NC} $(oci_version)\n"
  check_config || true
  exit 0
fi

echo -e "${RED}❌ OCI CLI not found${NC}\n"

install_linux_macos() {
  echo -e "${YELLOW}📥 Installing OCI CLI (Linux/macOS)...${NC}"
  local downloader=""
  if have curl; then downloader="curl -fsSL"; elif have wget; then downloader="wget -qO-"; else
    echo -e "${RED}Neither curl nor wget is available. Please install one or use manual steps:${NC} ${WHITE}$HELP_DOC${NC}"
    exit 1
  fi
  # Official installer
  bash -lc "$downloader https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh | bash -s -- --accept-all-defaults"
  echo -e "${GREEN}✅ Installed.${NC}\n"
  ensure_path_active_msg
}

install_windows_msi() {
  echo -e "${YELLOW}📥 Installing OCI CLI (Windows MSI, silent)...${NC}"
  if ! command -v powershell.exe >/dev/null 2>&1; then
    echo -e "${RED}PowerShell not available from this shell. Use manual steps:${NC} ${WHITE}$HELP_DOC${NC}"
    return 1
  fi
  # Query the latest MSI from GitHub releases via PowerShell
  powershell.exe -NoProfile -Command "
    \$ProgressPreference='SilentlyContinue';
    try {
      \$releases = Invoke-RestMethod https://api.github.com/repos/oracle/oci-cli/releases/latest;
      \$msi = (\$releases.assets | Where-Object { \$_.name -like '*Windows*Installer.msi' } | Select-Object -First 1).browser_download_url;
      if (-not \$msi) { throw 'MSI not found in latest release'; }
      \$tmp = Join-Path \$env:TEMP 'oci-cli-latest.msi';
      Invoke-WebRequest -Uri \$msi -OutFile \$tmp;
      Start-Process msiexec.exe -ArgumentList @('/i', \$tmp, '/qn') -Wait;
      Write-Host 'OK';
    } catch { Write-Error \$_; exit 1 }
  " >/dev/null
  echo -e "${GREEN}✅ Installed (MSI).${NC}\n"
  ensure_path_active_msg
}

install_windows_powershell_script() {
  echo -e "${YELLOW}📥 Installing OCI CLI via PowerShell script (fallback)...${NC}"
  powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;
    iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.ps1'))
  " || return 1
  echo -e "${GREEN}✅ Installed (PowerShell script).${NC}\n"
  ensure_path_active_msg
}

manual_instructions() {
  echo -e "${YELLOW}📖 Manual install:${NC} see ${WHITE}$HELP_DOC${NC}"
}

# 2) Not installed → decide path
if [[ "$NONINTERACTIVE" = "true" || "$AUTO" = "true" ]]; then
  # Auto path: Windows → MSI; Linux/macOS → installer script
  case "$OS" in
    windows)
      install_windows_msi || install_windows_powershell_script || { manual_instructions; exit 1; }
      ;;
    linux|macos)
      install_linux_macos || { manual_instructions; exit 1; }
      ;;
    *)
      manual_instructions; exit 1;;
  esac
else
  echo -e "${YELLOW}📦 OCI CLI install options:${NC}"
  if [[ "$OS" = "windows" ]]; then
    echo -e "${WHITE}  1) Windows MSI (recommended)${NC}"
    echo -e "${WHITE}  2) PowerShell script (fallback)${NC}"
    echo -e "${WHITE}  3) Manual (open local help)${NC}"
    echo -e "${WHITE}  4) Skip${NC}\n"
    read -rp "Choose (1-4): " choice
    case "${choice:-}" in
      1) install_windows_msi || { echo -e "${RED}MSI failed.${NC}"; install_windows_powershell_script || { manual_instructions; exit 1; }; } ;;
      2) install_windows_powershell_script || { manual_instructions; exit 1; } ;;
      3) manual_instructions; exit 1 ;;
      4) echo -e "${YELLOW}Skipping install. OCI CLI required later.${NC}"; exit 1 ;;
      *) echo -e "${RED}Invalid choice.${NC}"; exit 1 ;;
    esac
  else
    echo -e "${WHITE}  1) Auto install (recommended)${NC}"
    echo -e "${WHITE}  2) Manual (open local help)${NC}"
    echo -e "${WHITE}  3) Skip${NC}\n"
    read -rp "Choose (1-3): " choice
    case "${choice:-}" in
      1) install_linux_macos || { manual_instructions; exit 1; } ;;
      2) manual_instructions; exit 1 ;;
      3) echo -e "${YELLOW}Skipping install. OCI CLI required later.${NC}"; exit 1 ;;
      *) echo -e "${RED}Invalid choice.${NC}"; exit 1 ;;
    esac
  fi
fi

# 3) Recheck and guide to config
if have oci; then
  echo -e "${GREEN}✅ OCI CLI now available:${NC} $(oci_version)\n"
  check_config || true
  exit 0
else
  echo -e "${RED}❌ OCI CLI still not found on PATH.${NC}"
  ensure_path_active_msg
  exit 1
fi
