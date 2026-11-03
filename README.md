# mesa

Manage disposable, GUI-capable Podman work environments with a single command.

`mesa` wraps Podman to build and run isolated Arch Linux containers with a
persistent, host-mounted workspace. Each environment gets its own container
and workspace directory — so you can experiment freely, throw the container
away, and keep your files (or wipe everything with one command).

## What's in the box

- `mesa` — the manager script (build, create, attach, destroy environments)
- `Dockerfile` — the **base** image: a lean Arch Linux with `fish`, `tmux`,
  `vim`, `python` (plus `pipx`, `uv`), `git`, `openssh`, `curl`/`wget`,
  `ripgrep`, `fd`, `jq`, `less`, `file`, `bind` (dig/dns), your dotfiles,
  and the Mistral Vibe coding agent
- `images/` — image variants, stacked: `dev` (build/debug toolchain:
  `base-devel`, `gdb`, micromamba) on the base; `security` (offensive and
  reverse-engineering tools plus Burp Suite Professional) and `ide`
  (VS Code, `jdk-openjdk`, Playwright with Chromium) on `dev`
- Rootless containers with `--userns=keep-id`, so bind-mounted files are owned
  by your host user instead of root
- GUI support: the `--gui` socket set grafts your Wayland/X11 sockets and
  `/dev/dri` (the default set), so graphical apps run inside the container;
  audio, session D-Bus, and the SSH agent are opt-in grafts
- `micromamba` (aliased to `m`) in the `dev` variant, the Mistral Vibe coding
  agent (`vibe`, installed as a uv tool under `~/.local/bin`), dotfiles, and
  `fish` preinstalled in the image

## Requirements

- Python 3 (the `mesa` script)
- Podman (rootless)
- A Wayland or X11 session on the host (for GUI apps)

## Quick start

```sh
# Build the image (required once, and after any Dockerfile change)
./mesa build

# Start a fresh environment (named "default")
./mesa new

# Attach to it
./mesa shell
```

Named environments are fully isolated from each other:

```sh
./mesa new lab          # creates container "mesa-lab"
./mesa shell lab        # attaches to it
./mesa stop lab         # stops the container (data is kept)
./mesa rm lab           # destroys the environment: container and data
```

## Commands

| Command | Usage | Description |
| --- | --- | --- |
| `build` | `mesa build [name] [flags]` | Build an image: the base `Dockerfile` (tagged `localhost/mesa:latest` and `localhost/mesa:base`; `mesa build` and `mesa build base` are equivalent), or `images/<name>/Dockerfile` as `localhost/mesa:<name>`; `--no-cache` rebuilds without the layer cache |
| `new` | `mesa new [name] [flags]` | Create a fresh environment (refuses if it already exists) |
| `shell` | `mesa shell [name] [flags]` | Attach to the environment (starts or recreates the container if needed) |
| `stop` | `mesa stop [name]` | Stop the environment's container (environment and data are kept) |
| `gui` | `mesa gui [name] <cmd...>` | Launch a graphical app inside it |
| `rm` | `mesa rm [name] [-a] [-f]` | Remove the container, keep data (`-a`/`--all`: also destroy all data; `-f`/`--force`: skip confirmation) |
| `logs` | `mesa logs [name]` | Show the container logs |
| `ls` | `mesa ls` | List environments, their status, image, and socket set |
| `config` | `mesa config [key] [value]` | Show settings, or set one (keys: `default`, `image`, `sockets`) |

Running `mesa` with no arguments prints the help.

An environment exists as long as its data workspace exists
(`~/.local/share/mesa/<name>/workspace`). Containers are disposable:

- `mesa shell` attaches and never needs to be told twice — a stopped container
  is started automatically, and a missing container is recreated from the
  environment's image, mounting the existing data. You are only asked for
  confirmation when the environment itself does not exist yet (`y` runs the
  equivalent of `mesa new <name>` and then attaches).
- `mesa stop` leaves the container in a stopped state, so anything installed
  inside the container outside `/workspace` (system packages, conda
  environments, home-directory changes) survives and is back when you attach
  again.
- `mesa rm <name>` removes the container and keeps all data — the next
  `mesa shell <name>` recreates a pristine container from the environment's
  image and mounts the existing data. State inside the container itself is
  lost, including home-directory changes; image-baked home content (dotfiles,
  micromamba) comes back with the fresh container. It asks for confirmation
  unless `-f`/`--force` is given.
- `mesa rm -a <name>` (`--all`) is the only command that removes the
  environment. It asks for confirmation and then deletes the container and all
  data under `~/.local/share/mesa/<name>/`; `-f`/`--force` skips the prompt.
- `mesa ls` lists every environment with its status: `running`, `stopped`,
  or `data only` (no container at the moment), plus the image and socket set
  it was created with.

If no name is given, the configured default is used (`mesa config default <name>`,
stored under `~/.config/mesa/config`); it falls back to `default` when unset.

### Running GUI apps

```sh
./mesa gui default code --no-sandbox
```

This execs into the container with your host's `DISPLAY`/`WAYLAND_DISPLAY`
forwarded, so the app appears on your desktop.

### Host session sockets

Every container gets a private, writable runtime dir (a tmpfs mounted at
`/run/user/<uid>` inside the container, owned by the container user), so tools
like `tmux` work out of the box. Host session sockets are **not** shared by default — each one is
only bind-mounted ("grafted") into the container when you ask for it, on
`mesa new` and `mesa shell`:

| Flag | Grafted into the container | What it enables |
| --- | --- | --- |
| `--gui` | Wayland socket, `/tmp/.X11-unix`, `/dev/dri` (GPU) | Graphical apps, hardware-accelerated rendering |
| `--audio` | `pipewire-0`, `pulse/native` | Host audio |
| `--bus` | session D-Bus (`bus`) | Portals, notifications — and everything else on your session bus |
| `--ssh-agent` | `ssh` | Host SSH agent (your host keys become usable from inside) |

Each flag has a `--no-...` negation for switching a set on recreate, e.g.
`--no-gui --audio`. New environments use the configured default set
(`mesa config sockets <list>`, initially `gui`; `none` for none), and —
like the image — every environment remembers its socket set in its `env`
metadata, so recreated containers keep it. `mesa shell` applies new flags
only when it has to create a container; an existing container keeps what it
was created with (the command prints a hint). `mesa gui` refuses with a
clear error if the environment was created without `--gui`.

Security notes:

- The default `gui` set exposes your screens (screen capture) and GPU to
  the container — inherent to running GUI apps.
- `--bus` is the broadest grant: the session bus fronts most of your user
  session, including the Secret Service, the user systemd instance, and
  every other session app. Prefer running without it when you can.
- `--ssh-agent` reverses mesa's earlier "never forward the host agent"
  stance: it is opt-in only, and anything inside the container can then
  sign with your host SSH keys.
- The keyring and user systemd instance are never exposed.

Caveat: bind-mounted sockets are pinned to the socket that existed when
the container was created. If the host daemon restarts and recreates its
socket (Wayland compositor, PipeWire, D-Bus), the container keeps the
stale one and connections fail. Fix it by recreating the container — the
data survives:

```sh
./mesa rm <name> && ./mesa shell <name>
```

## Data layout

Environment data lives under `~/.local/share/mesa/` (respects `XDG_DATA_HOME`):

```
~/.local/share/mesa/<name>/workspace   # mounted at /workspace in the container
~/.local/share/mesa/<name>/vibe        # mounted at /home/researcher/.vibe in the container
~/.local/share/mesa/<name>/fish        # mounted at /home/researcher/.local/share/fish in the container
~/.local/share/mesa/<name>/env         # environment metadata (its image, socket set)
```

Settings live in `~/.config/mesa/config` (respects `XDG_CONFIG_HOME`).

This data is the environment. It survives stopped, destroyed, or recreated
containers, and only `mesa rm -a <name>` deletes it. The container's home
directory is not mounted: it lives in the container layer, so image-baked
content (dotfiles, micromamba) is always present, and only `/workspace` data
survives container removal — with two exceptions, bind-mounted from
alongside the workspace so they too survive recreation: the Vibe agent's
home (`~/.vibe` — config, session history, API key) and the fish shell
history (`~/.local/share/fish`). The list of persistent mounts lives in the
`PERSISTENT_MOUNTS` table in the `mesa` script; only add directories that
hold runtime-created state alone — a mount over a directory containing
image-baked content (dotfiles symlinks, tool installs) shadows it and
breaks the image.

## Images

The base image is built from the `Dockerfile` in the repository root and
tagged both `localhost/mesa:latest` and `localhost/mesa:base` — it is
deliberately minimal: shell, editor, terminal, Python, and your dotfiles.
Build it with either name (they are equivalent):

```sh
./mesa build          # or: ./mesa build base
```

Variants live one per directory under `images/`. Each variant's
`Dockerfile` builds on another mesa image via `FROM` — `dev` on the base,
`security` and `ide` on `dev` — so the toolsets stack:

| Variant | Builds on | Adds |
| --- | --- | --- |
| `dev` | base | `base-devel`, `gdb`, micromamba (`m`) |
| `security` | `dev` | `nmap`, `tcpdump`, `wireshark-cli`, `metasploit`, `sqlmap`, `hydra`, `john`, `radare2`, `binwalk`, Burp Suite Professional |
| `ide` | `dev` | VS Code (`code`), `jdk-openjdk`, Playwright with Chromium |

Notes on the variants' extra tooling:

- **Burp Suite Professional** (`security`): PortSwigger ships a single
  installer for Community and Professional; the image installs it
  unattended as the normal user into `~/.local/share/burpsuite`, with a
  `burpsuite` symlink in `~/.local/bin` (on PATH), using the version
  pinned in the `BURP_VERSION` build arg — bump it when a newer release
  comes out. The edition activates with your license at first launch, so
  a Pro license is required for Pro features. The install4j installer
  initializes its font manager even unattended, hence the `freetype2`
  and `fontconfig` packages alongside the tools; `ttf-dejavu` provides
  the actual fonts — without any font installed, Burp dies at startup
  with "Fontconfig head is null".
- **Playwright** (`ide`): installed with its Chromium and headless-shell
  browsers under `~/.cache/ms-playwright` (container layer). Launch VS
  Code as `mesa gui <name> code --no-sandbox`.

`mesa build base` (or bare `mesa build`) builds the base image, tagging it
both `localhost/mesa:latest` and `localhost/mesa:base`; `mesa build <name>`
builds `images/<name>/Dockerfile` and tags it `localhost/mesa:<name>`; any
missing parent image in the chain is built first, automatically:

```sh
./mesa build security     # builds base, then dev, then security if needed
```

Add your own variant by creating `images/<name>/Dockerfile` — start it
with `FROM localhost/mesa:<image>` (the base, `dev`, or another variant),
install packages, and end with `USER researcher` and a `sleep infinity`
CMD. Rebuild a variant after changing any image below it in the chain;
pass `--no-cache` to any `mesa build` to ignore the layer cache (an
already-built parent image is still reused).

### Choosing an image

- `mesa new <name> -i <image>` creates an environment from a specific image
  (`--image` also works). The value is a tag under `localhost/mesa` (e.g.
  `light`) or a full image reference (e.g. `docker.io/library/archlinux`).
- `mesa config image <image>` sets the default image used when no `-i` flag
  is given (initially `localhost/mesa:latest`; `base` names the same image).
- Every environment remembers its image in `~/.local/share/mesa/<name>/env`.
  Deleting and recreating the container — or the whole environment's
  container via `mesa rm <name>` followed by `mesa shell <name>` — uses the
  same image again, even if the configured default changed in between.
  `-i` on `mesa shell` only takes effect when a container has to be created;
  an existing container keeps the image it was created from (remove it first
  to switch).
- `mesa ls` shows the image of each environment.

Environments created before this file existed have no recorded image; they
use the configured default and record it on their next container creation.

## License

[MIT](LICENSE) — Copyright (c) 2026 Volodia Laniel
