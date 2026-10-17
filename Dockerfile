# syntax=docker
FROM docker.io/library/archlinux:latest

# Reproducible mirror + fast locale (keeps image lean and stable)
RUN printf 'Server = https://mirror.init7.net/archlinux/$repo/os/$arch\n' \
        > /etc/pacman.d/mirrorlist && \
    sed -i 's/^#ParallelDownloads.*/ParallelDownloads = 8/' /etc/pacman.conf && \
    sed -i 's/^DownloadUser/#DownloadUser # disabled: breaks rootless builds/' /etc/pacman.conf && \
    echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen && locale-gen && \
    echo 'LANG=en_US.UTF-8' > /etc/locale.conf

# --- Toolset layer: edit here, then `mesa build` ---
RUN pacman -Syu --noconfirm && pacman -S --noconfirm --needed \
        base-devel git openssh curl wget nmap tcpdump wireshark-cli \
        metasploit sqlmap hydra john python python-pipx ripgrep fd tmux gdb \
        radare2 binwalk file vim fish jq bind jdk-openjdk && \
    pacman -Scc --noconfirm          # clean cache -> small image

# Non-root user matching your host UID (avoids root-owned files in the bind mount)
ARG HOST_UID=1000
RUN useradd -m -u "${HOST_UID}" -G wheel researcher && chown -R researcher /home/researcher
RUN mkdir -p /workspace && chown -R researcher /workspace
USER researcher
ENV HOME=/home/researcher
ENV PATH="/home/researcher/.local/bin:${PATH}"
WORKDIR /workspace
RUN git clone -b generic --recurse-submodules -j8 "https://github.com/vahlkar/dotfiles" "$HOME/.dotfiles" && sed -i '/link:/,/create:/ s/\(create: true\)/\1\n        force: true/' "$HOME/.dotfiles/install.conf.yaml"
RUN "$HOME/.dotfiles/install" || echo "Ignoring errors."
RUN curl -Ls "https://micro.mamba.pm/api/micromamba/$(uname)-$(uname -m)/latest" | tar -xvj -C "$HOME" bin/micromamba && ln -s "$HOME/bin/micromamba" "$HOME/bin/m"

# Mistral Vibe coding agent, installed as the researcher user via uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
RUN uv tool install mistral-vibe
USER root
RUN pacman -Syu --noconfirm code
USER researcher

# Default: drop into an interactive shell
CMD ["/usr/bin/sleep", "infinity"]
