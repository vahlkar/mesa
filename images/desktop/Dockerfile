# syntax=docker
# mesa 'desktop' image: VS Code for GUI-forwarded editing on top of the 'dev'
# variant. 'mesa build desktop' builds any missing parent image (dev, then
# the base) first.
# Run it as: mesa gui <name> code --no-sandbox
FROM localhost/mesa:dev

USER root
RUN pacman -Syu --noconfirm && pacman -S --noconfirm --needed code && \
    pacman -Scc --noconfirm          # clean cache -> small image

USER researcher
WORKDIR /workspace

CMD ["/usr/bin/sleep", "infinity"]
