# syntax=docker
# mesa 'security' image: network analysis and offensive/reverse-engineering
# tooling plus Burp Suite Professional, on top of the 'dev' variant.
# 'mesa build security' builds any missing parent image (dev, then the base)
# first.
FROM localhost/mesa:dev

# Burp Suite Professional: PortSwigger ships a single installer for
# Community and Professional; the edition activates with your license at
# first launch (a Pro license is required to use Pro features).
# The installer is install4j-based, so it installs unattended with -q.
# Bump BURP_VERSION to pick up a newer release.
ARG BURP_VERSION=2026.9.2
USER root
RUN curl -fL "https://portswigger.net/burp/releases/download?product=desktop&version=${BURP_VERSION}&type=Linux" \
        -o /tmp/burp-installer.sh && \
    sh /tmp/burp-installer.sh -q -dir /opt/burpsuite && \
    ln -s /opt/burpsuite/BurpSuiteProfessional /usr/local/bin/burpsuite && \
    rm /tmp/burp-installer.sh

RUN pacman -Syu --noconfirm && pacman -S --noconfirm --needed \
        nmap tcpdump wireshark-cli metasploit sqlmap hydra john \
        radare2 binwalk && \
    pacman -Scc --noconfirm          # clean cache -> small image

USER researcher
WORKDIR /workspace

CMD ["/usr/bin/sleep", "infinity"]
