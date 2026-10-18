# syntax=docker
# mesa 'security' image: network analysis and offensive/reverse-engineering
# tooling on top of the 'dev' variant. 'mesa build security' builds any
# missing parent image (dev, then the base) first.
FROM localhost/mesa:dev

USER root
RUN pacman -Syu --noconfirm && pacman -S --noconfirm --needed \
        nmap tcpdump wireshark-cli metasploit sqlmap hydra john \
        radare2 binwalk && \
    pacman -Scc --noconfirm          # clean cache -> small image

USER researcher
WORKDIR /workspace

CMD ["/usr/bin/sleep", "infinity"]
