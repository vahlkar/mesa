# syntax=docker
FROM docker.io/library/archlinux:latest

# Reproducible mirror + fast locale (keeps image lean and stable)
RUN printf 'Server = https://mirror.init7.net/archlinux/$repo/os/$arch\n' \
        > /etc/pacman.d/mirrorlist && \
    sed -i 's/^#ParallelDownloads.*/ParallelDownloads = 8/' /etc/pacman.conf && \
    sed -i 's/^DownloadUser/#DownloadUser # disabled: breaks rootless builds/' /etc/pacman.conf && \
    echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen && locale-gen && \
    echo 'LANG=en_US.UTF-8' > /etc/locale.conf

# --- Base toolset: shell, editor, and Python. Edit here, then `mesa build`.
# Heavier tooling lives in the variants under images/ (dev, security, ide).
RUN pacman -Syu --noconfirm && pacman -S --noconfirm --needed \
        less file git openssh curl wget ripgrep fd tmux vim fish jq bind \
        xclip wl-clipboard \
        python python-pipx uv && \
    pacman -Scc --noconfirm          # clean cache -> small image

# Non-root user matching your host UID (avoids root-owned files in the bind mount)
ARG HOST_UID=1000
RUN useradd -m -u "${HOST_UID}" -G wheel -s /usr/bin/fish researcher && chown -R researcher /home/researcher
RUN mkdir -p /workspace && chown -R researcher /workspace
USER researcher
ENV HOME=/home/researcher
ENV PATH="/home/researcher/.local/bin:${PATH}"
WORKDIR /workspace
# Dotfiles: clone main and install the 'generic' host profile. The profile
# is passed explicitly because ./install defaults to the machine's
# hostname, which is random in a container. The sed adds force: true so
# dotbot overwrites the real files left by /etc/skel (~/.bashrc, ~/.profile).
RUN git clone -b main --recurse-submodules -j8 "https://github.com/vahlkar/dotfiles" "$HOME/.dotfiles" && sed -i '/link:/,/create:/ s/\(create: true\)/\1\n        force: true/' "$HOME/.dotfiles/install.conf.yaml"
RUN "$HOME/.dotfiles/install" generic || echo "Ignoring errors."

# Mistral Vibe coding agent, installed as the researcher user via uv (from extra)
RUN uv tool install mistral-vibe

# Default: drop into an interactive shell
CMD ["/usr/bin/sleep", "infinity"]
