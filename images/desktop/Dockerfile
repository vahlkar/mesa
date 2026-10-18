# syntax=docker
# mesa 'desktop' image: VS Code for GUI-forwarded editing on top of the base
# image. 'mesa build desktop' builds the base image first if it is missing.
# Run it as: mesa gui <name> code --no-sandbox
FROM localhost/mesa:latest

USER root
RUN pacman -Syu --noconfirm && pacman -S --noconfirm --needed code && \
    pacman -Scc --noconfirm          # clean cache -> small image

USER researcher
WORKDIR /workspace

CMD ["/usr/bin/sleep", "infinity"]
