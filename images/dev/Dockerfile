# syntax=docker
# mesa 'dev' image: build/debug toolchain and micromamba on top of the base
# image. 'mesa build dev' builds any missing parent image (the base) first.
FROM localhost/mesa:latest

USER root
RUN pacman -Syu --noconfirm && pacman -S --noconfirm --needed \
        base-devel gdb && \
    pacman -Scc --noconfirm          # clean cache -> small image

# micromamba (aliased to m), installed as the researcher user
USER researcher
WORKDIR /workspace
RUN curl -Ls "https://micro.mamba.pm/api/micromamba/$(uname)-$(uname -m)/latest" | tar -xvj -C "$HOME" bin/micromamba && ln -s "$HOME/bin/micromamba" "$HOME/bin/m"

CMD ["/usr/bin/sleep", "infinity"]
