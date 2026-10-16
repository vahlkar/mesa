# workenv

Manage disposable, GUI-capable Podman work environments with a single command.

`work` wraps Podman to build and run isolated Arch Linux containers with a
persistent, host-mounted workspace. Each environment gets its own container,
workspace directory, and home directory — so you can experiment freely, throw
the container away, and keep your files (or wipe everything with one command).

## What's in the box

- `work` — the manager script (build, create, attach, destroy environments)
- `Dockerfile` — an Arch Linux image with a development and network-analysis
  toolset: `base-devel`, `git`, `python`, `gdb`, `radare2`, `nmap`, `tcpdump`,
  `wireshark-cli`, `metasploit`, `sqlmap`, `hydra`, `john`, `code`, and more
- Rootless containers with `--userns=keep-id`, so bind-mounted files are owned
  by your host user instead of root
- GUI support: forwards your Wayland/X11 sockets and `/dev/dri`, so graphical
  apps run inside the container
- `micromamba` (aliased to `m`), dotfiles, and `fish` preinstalled in the image

## Requirements

- Podman (rootless)
- A Wayland or X11 session on the host (for GUI apps)

## Quick start

```sh
# Build the image (required once, and after any Dockerfile change)
./work build

# Start a fresh environment (named "default")
./work new

# Attach to it
./work shell
```

Named environments are fully isolated from each other:

```sh
./work new lab          # creates container "swe-lab"
./work shell lab        # attaches to it
./work rm lab           # removes the container, keeps workspace data
```

## Commands

| Command | Usage | Description |
| --- | --- | --- |
| `build` | `work build [name]` | Build the image (after Dockerfile changes) |
| `new` | `work new [name]` | Start a fresh environment (GUI-capable) |
| `shell` | `work shell [name]` | Attach to the running environment |
| `gui` | `work gui [name] <cmd...>` | Launch a graphical app inside it |
| `rm` | `work rm [name]` | Destroy the container (keeps workspace data) |
| `purge` | `work purge [name]` | Destroy the container and wipe workspace data |
| `logs` | `work logs [name]` | Show container logs |
| `ls` | `work ls` | List environments |
| `config` | `work config [key] [value]` | Show settings, or set one (key: `default`) |

Running `work` with no arguments prints the help.

If no name is given, the configured default is used (`work config default <name>`,
stored under `~/.config/work/config`); it falls back to `default` when unset.

### Running GUI apps

```sh
./work gui default code --no-sandbox
```

This execs into the container with your host's `DISPLAY`/`WAYLAND_DISPLAY`
and runtime directory forwarded, so the app appears on your desktop.

## Data layout

Environment data lives under `workspaces/` next to the script (git-ignored):

```
workspaces/<name>/workspace   # mounted at /workspace in the container
workspaces/<name>/home        # mounted at /home/researcher
```

- `rm` keeps this data, so `work new <name>` picks up where you left off.
- `purge` deletes it permanently.

## Customizing the image

Edit the toolset layer in the `Dockerfile`, then rebuild:

```sh
./work build
./work new <name>   # --replace swaps in a fresh container from the new image
```

## License

[MIT](LICENSE) — Copyright (c) 2026 Volodia Laniel
