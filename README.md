# mesa

Manage disposable, GUI-capable Podman work environments with a single command.

`mesa` wraps Podman to build and run isolated Arch Linux containers with a
persistent, host-mounted workspace. Each environment gets its own container,
workspace directory, and home directory — so you can experiment freely, throw
the container away, and keep your files (or wipe everything with one command).

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
./mesa rm lab           # removes the container, keeps workspace data
```

## Commands

| Command | Usage | Description |
| --- | --- | --- |
| `build` | `mesa build [name]` | Build the image (after Dockerfile changes) |
| `new` | `mesa new [name]` | Start a fresh environment (GUI-capable) |
| `shell` | `mesa shell [name]` | Attach to the environment (starts or creates it if needed) |
| `gui` | `mesa gui [name] <cmd...>` | Launch a graphical app inside it |
| `rm` | `mesa rm [name]` | Destroy the container (keeps workspace data) |
| `purge` | `mesa purge [name]` | Destroy the container and wipe workspace data |
| `logs` | `mesa logs [name]` | Show container logs |
| `ls` | `mesa ls` | List environments |
| `config` | `mesa config [key] [value]` | Show settings, or set one (key: `default`) |

Running `mesa` with no arguments prints the help.

`mesa shell` also copes with an environment that is not running: a stopped
container is started automatically, and if the environment does not exist you
are asked whether to create it (`y` runs the equivalent of `mesa new <name>`
and then attaches).

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
~/.local/share/mesa/<name>/home        # mounted at /home/researcher
```

Settings live in `~/.config/mesa/config` (respects `XDG_CONFIG_HOME`).

- `rm` keeps this data, so `mesa new <name>` picks up where you left off.
- `purge` deletes it permanently.

## Customizing the image

Edit the toolset layer in the `Dockerfile`, then rebuild:

```sh
./mesa build
./mesa new <name>   # --replace swaps in a fresh container from the new image
```

## License

[MIT](LICENSE) — Copyright (c) 2026 Volodia Laniel
