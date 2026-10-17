# mesa

Manage disposable, GUI-capable Podman work environments with a single command.

`mesa` wraps Podman to build and run isolated Arch Linux containers with a
persistent, host-mounted workspace. Each environment gets its own container
and workspace directory — so you can experiment freely, throw the container
away, and keep your files (or wipe everything with one command).

## What's in the box

- `mesa` — the manager script (build, create, attach, destroy environments)
- `Dockerfile` — an Arch Linux image with a development and network-analysis
  toolset: `base-devel`, `git`, `python`, `gdb`, `radare2`, `nmap`, `tcpdump`,
  `wireshark-cli`, `metasploit`, `sqlmap`, `hydra`, `john`, `code`, and more
- Rootless containers with `--userns=keep-id`, so bind-mounted files are owned
  by your host user instead of root
- GUI support: forwards your Wayland/X11 sockets and `/dev/dri`, so graphical
  apps run inside the container
- `micromamba` (aliased to `m`), dotfiles, and `fish` preinstalled in the image

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
| `build` | `mesa build [name]` | Build the image (after Dockerfile changes) |
| `new` | `mesa new [name]` | Create a fresh environment (refuses if it already exists) |
| `shell` | `mesa shell [name]` | Attach to the environment (starts or recreates the container if needed) |
| `stop` | `mesa stop [name]` | Stop the environment's container (environment and data are kept) |
| `gui` | `mesa gui [name] <cmd...>` | Launch a graphical app inside it |
| `rm` | `mesa rm [name] [-a] [-f]` | Remove the container, keep data (`-a`/`--all`: also destroy all data; `-f`/`--force`: skip confirmation) |
| `logs` | `mesa logs [name]` | Show container logs |
| `ls` | `mesa ls` | List environments and their status |
| `config` | `mesa config [key] [value]` | Show settings, or set one (key: `default`) |

Running `mesa` with no arguments prints the help.

An environment exists as long as its data workspace exists
(`~/.local/share/mesa/<name>/workspace`). Containers are disposable:

- `mesa shell` attaches and never needs to be told twice — a stopped container
  is started automatically, and a missing container is recreated from the
  image, mounting the existing data. You are only asked for confirmation when
  the environment itself does not exist yet (`y` runs the equivalent of
  `mesa new <name>` and then attaches).
- `mesa stop` leaves the container in a stopped state, so anything installed
  inside the container outside `/workspace` (system packages, conda
  environments, home-directory changes) survives and is back when you attach
  again.
- `mesa rm <name>` removes the container and keeps all data — the next
  `mesa shell <name>` recreates a pristine container from the image and mounts
  the existing data. State inside the container itself is lost, including
  home-directory changes; image-baked home content (dotfiles, micromamba)
  comes back with the fresh container. It asks for confirmation unless
  `-f`/`--force` is given.
- `mesa rm -a <name>` (`--all`) is the only command that removes the
  environment. It asks for confirmation and then deletes the container and all
  data under `~/.local/share/mesa/<name>/`; `-f`/`--force` skips the prompt.
- `mesa ls` lists every environment with one status: `running`, `stopped`,
  or `data only` (no container at the moment).

If no name is given, the configured default is used (`mesa config default <name>`,
stored under `~/.config/mesa/config`); it falls back to `default` when unset.

### Running GUI apps

```sh
./mesa gui default code --no-sandbox
```

This execs into the container with your host's `DISPLAY`/`WAYLAND_DISPLAY`
and runtime directory forwarded, so the app appears on your desktop.

## Data layout

Environment data lives under `~/.local/share/mesa/` (respects `XDG_DATA_HOME`):

```
~/.local/share/mesa/<name>/workspace   # mounted at /workspace in the container
```

Settings live in `~/.config/mesa/config` (respects `XDG_CONFIG_HOME`).

This data is the environment. It survives stopped, destroyed, or recreated
containers, and only `mesa rm -a <name>` deletes it. The container's home
directory is not mounted: it lives in the container layer, so image-baked
content (dotfiles, micromamba) is always present, and only `/workspace` data
survives container removal.

## Customizing the image

Edit the toolset layer in the `Dockerfile`, then rebuild:

```sh
./mesa build
./mesa rm <name>     # remove just the container; the next 'shell' starts a
                     # fresh container from the new image, keeping your data
```

## License

[MIT](LICENSE) — Copyright (c) 2026 Volodia Laniel
