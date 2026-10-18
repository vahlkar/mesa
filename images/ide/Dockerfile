# syntax=docker
# mesa 'ide' image: VS Code, the JVM, and Playwright for in-browser testing,
# on top of the 'dev' variant. 'mesa build ide' builds any missing parent
# image (dev, then the base) first.
FROM localhost/mesa:dev

USER root
RUN pacman -Syu --noconfirm && pacman -S --noconfirm --needed \
        jdk-openjdk code nss gtk3 alsa-lib mesa && \
    pacman -Scc --noconfirm          # clean cache -> small image

# Playwright with its Chromium browser, for in-browser testing.
# Browsers land in ~/.cache/ms-playwright (container layer, not /workspace).
USER researcher
WORKDIR /workspace
RUN pipx install playwright && \
    pipx run playwright install chromium && \
    pipx run playwright install chromium-headless-shell

# Run code as: mesa gui <name> code --no-sandbox
CMD ["/usr/bin/sleep", "infinity"]
