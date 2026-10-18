# syntax=docker
# mesa 'security' image: network analysis and offensive/reverse-engineering
# tooling on top of the base image. 'mesa build security' builds the base
# image first if it is missing.
FROM localhost/mesa:latest

USER root
RUN pacman -Syu --noconfirm && pacman -S --noconfirm --needed \
        nmap tcpdump wireshark-cli metasploit sqlmap hydra john \
        radare2 binwalk && \
    pacman -Scc --noconfirm          # clean cache -> small image

USER researcher
WORKDIR /workspace

CMD ["/usr/bin/sleep", "infinity"]
