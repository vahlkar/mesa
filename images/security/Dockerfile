# syntax=docker
# mesa 'security' image: network analysis and offensive/reverse-engineering
# tooling plus Burp Suite Professional, on top of the 'dev' variant.
# 'mesa build security' builds any missing parent image (dev, then the base)
# first.
FROM localhost/mesa:dev

# System-wide tooling (needs root). freetype2 and fontconfig are installed
# here because Burp's install4j installer initializes its font manager even
# in unattended mode; without libfreetype.so.6 the installer dies.
USER root
RUN pacman -Syu --noconfirm && pacman -S --noconfirm --needed \
        nmap tcpdump wireshark-cli metasploit sqlmap hydra john \
        radare2 binwalk freetype2 fontconfig mitmproxy proxychains-ng && \
    pacman -Scc --noconfirm          # clean cache -> small image

# Burp Suite Professional: PortSwigger ships a single installer for
# Community and Professional; the edition activates with your license at
# first launch (a Pro license is required to use Pro features).
# The installer is install4j-based, so it installs unattended with -q.
# It needs no root: it runs as the normal user, into $HOME, with the
# executable symlinked into ~/.local/bin (on PATH from the base image).
# Bump BURP_VERSION to pick up a newer release.
ARG BURP_VERSION=2026.9.2
USER researcher
RUN curl -fL "https://portswigger.net/burp/releases/download?product=desktop&version=${BURP_VERSION}&type=Linux" \
        -o /tmp/burp-installer.sh && \
    sh /tmp/burp-installer.sh -q -dir "$HOME/.local/share/burpsuite" && \
    mkdir -p "$HOME/.local/bin" && \
    ln -s "$HOME/.local/share/burpsuite/BurpSuiteProfessional" "$HOME/.local/bin/burpsuite" && \
    rm /tmp/burp-installer.sh

WORKDIR /workspace

CMD ["/usr/bin/sleep", "infinity"]
