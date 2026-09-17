#!/bin/sh
# Wrapper script for Proton Pass CLI (pass-cli)
# kud3n013/archrepo

# On Linux, Proton Pass CLI defaults to the kernel keyring (cleared on reboot),
# causing forced logouts after every system restart.
# If a D-Bus Secret Service (GNOME Keyring, KWallet, KeePassXC, etc.) is available
# and PROTON_PASS_LINUX_KEYRING is not explicitly overridden, default to 'dbus'
# for persistent credentials across reboots.
if [ -z "${PROTON_PASS_LINUX_KEYRING}" ]; then
    if busctl --user status org.freedesktop.secrets >/dev/null 2>&1; then
        export PROTON_PASS_LINUX_KEYRING="dbus"
    fi
fi

# Load optional user configuration
if [ -f "${XDG_CONFIG_HOME:-$HOME/.config}/proton-pass-cli.conf" ]; then
    . "${XDG_CONFIG_HOME:-$HOME/.config}/proton-pass-cli.conf"
elif [ -f /etc/proton-pass-cli.conf ]; then
    . /etc/proton-pass-cli.conf
fi

exec "${PASS_CLI_BIN:-/usr/lib/proton-pass-cli/pass-cli}" "$@"
