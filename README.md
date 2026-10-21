# claude-on-docker

Run [Claude Code](https://code.claude.com) inside Docker instead of installing it on your machine.
Works from the terminal and from VS Code (Dev Containers), with `git push` to GitHub —
without your SSH key or Claude login ever being baked into an image.

Tested on Ubuntu with Docker Engine.

## How it fits together

Think of a cookie cutter:

- **Base image** (`claude-base`) — the cutter. Built once: Claude Code, git, ssh client, safe default settings.
- **Containers** — the cookies. One fresh container per project; it only sees that project's folder.
- **Child image** (optional, `template/.devcontainer/Dockerfile`) — the cutter with an extra decoration, only for projects that need extra tools (e.g. Python, a compiler).
- **`claude-home` volume** — your locker. Keeps your Claude login and git config, shared by all containers. Lives only on your PC.

```
claude-base (image)
 ├── container: project-A   sees only ~/projects/A  at /workspace/A
 ├── container: project-B   sees only ~/projects/B  at /workspace/B
 └── child image (base + python)        ← only if a project needs extra tools
      └── container: project-C
all containers mount the claude-home volume → log in once
```

## What's in this repo

| File | Purpose |
|---|---|
| `base/Dockerfile` | Base image: Claude Code + git + ssh client, non-root user `node`, passwordless `sudo` |
| `base/managed-settings.json` | System-wide Claude settings: ask before running commands, always ask before `git push` |
| `claude.sh` | Run Claude in the terminal for the current folder |
| `template/.devcontainer/devcontainer.json` | Copy into a project to open it in VS Code inside a container |
| `template/.devcontainer/Dockerfile` | Optional child image for projects needing extra tools (used only when Option B is enabled) |

No secrets are stored anywhere in this repo.

---

## 1. Build the base image (once)

Requires Docker ([install guide](https://docs.docker.com/engine/install/ubuntu/)) and your user in the `docker` group.

```bash
git clone https://github.com/<you>/claude-on-docker.git
cd claude-on-docker
docker build -t claude-base base/
chmod +x claude.sh
sudo ln -sf "$PWD/claude.sh" /usr/local/bin/claude-docker  # makes "claude-docker" work from any folder
hash -r                                                     # refresh the shell's command list (zsh: rehash)
```

## 2. Set up GitHub access (SSH agent forwarding)

Your private key stays on the host. The container only gets a socket to ask the host's
SSH agent to sign — like a doorman who signs for your packages but never holds your house key.

**Load only the key meant for GitHub.** The container can use *every* key in the agent,
so remove all others (e.g. work keys) first:

```bash
ssh-add -D                              # clear the agent
ssh-add ~/.ssh/<your_github_key>        # the private key, no .pub
ssh-add -l                              # must list only that key
```

The agent forgets keys at logout/reboot, and Ubuntu may auto-load all keys again — so
re-check `ssh-add -l` after each login.

Optional helper for `~/.bashrc` (or `~/.zshrc` if you use zsh) — loads the right key and opens VS Code in one step:

```bash
export GITHUB_KEY="$HOME/.ssh/<your_github_key>"
claude-code() { ssh-add -D >/dev/null 2>&1; ssh-add "$GITHUB_KEY" && code "${1:-.}"; }
```

## 3. Use from the terminal

```bash
cd ~/projects/my-app      # always run it from INSIDE the project folder
claude-docker
```

`claude-docker` mounts the folder you run it from — run it in the wrong folder and Claude
works on that folder. The header shows which one: `/workspace/my-app`.

First run only: Claude shows a login URL — open it in your browser. The login is saved in
the `claude-home` volume, so every later run (any project) is already logged in.

Inside Claude, `!` runs a shell command in the container. One-time setup:

```
! git config --global user.name "Your Name"
! git config --global user.email "you@example.com"
! ssh -T git@github.com            # expect: "Hi <you>! You've successfully authenticated"
```

**Copying text:** hold **Shift** while selecting with the mouse, then **Ctrl+Shift+C**.
For longer output, ask Claude to write it to a file in the project folder and open it on the host.

## 4. Use from VS Code

1. Install VS Code and the **Dev Containers** extension (`ms-vscode-remote.remote-containers`).
   The Claude extension is installed *inside* the container automatically.
2. Copy the template into your project and set a name:
   ```bash
   cp -r ~/claude-on-docker/template/.devcontainer ~/projects/my-app/
   # edit .devcontainer/devcontainer.json → "name": "my-app"
   ```
   - By default the project uses `claude-base` as is — nothing else to do.
   - Project needs extra tools (Python, compilers, ...)? Add them to `.devcontainer/Dockerfile`,
     then in `devcontainer.json` comment out **Option A** and uncomment **Option B**.
3. Load your GitHub key, then **start VS Code from that same terminal** (it forwards the agent it started with):
   ```bash
   cd ~/projects/my-app
   claude-code          # or: ssh-add ... && code .
   ```
   Don't start VS Code from the dock — it may carry an agent with all your keys.
   If a VS Code window is already open, close it first.
4. Click **Reopen in Container** (or F1 → *Dev Containers: Reopen in Container*).
   Bottom-left shows `Dev Container: my-app`.
5. Open the Claude panel (spark icon) or type `claude` in the VS Code terminal.

**Shared/work repos:** keep the template out of commits without touching `.gitignore`:
```bash
echo ".devcontainer/" >> .git/info/exclude
```

## 5. Check everything works

Inside the container terminal:

| Check | Command | Expected |
|---|---|---|
| Right folder | `pwd` | `/workspace/<project-folder-name>` |
| Claude installed | `claude --version` | a version number |
| Safe settings | `cat /etc/claude-code/managed-settings.json` | the settings file |
| GitHub access | `ssh -T git@github.com` | `Hi <you>!` |

---

## Day-to-day

| Task | How |
|---|---|
| Install a package once | `sudo apt install <pkg>` — gone when the container is removed |
| Install for every project | Add to `base/Dockerfile`, then `docker build -t claude-base base/` |
| Install for one project | Add to `.devcontainer/Dockerfile`, enable Option B in `devcontainer.json`, then F1 → *Rebuild Container* |
| Continue an earlier session | `/resume` inside Claude (sessions are kept per project folder name) |
| Update Claude Code | `docker build --no-cache -t claude-base base/`, then rebuild project containers |
| Log out / reset everything | `docker volume rm claude-home` |

**Why `/workspace/<folder-name>`?** Claude files saved sessions by folder path. If every
project were mounted at plain `/workspace`, `/resume` would mix sessions from all projects.
Two projects with the same folder name still share sessions — rename one if that happens.

## Security notes

- Credentials are never in an image: the Claude login and git config live in the `claude-home` volume on your PC only.
- The SSH private key never enters a container (agent forwarding).
- Claude can only touch the mounted project folder; `sudo` works only inside the container.
- `managed-settings.json` makes Claude ask before running commands, and always before `git push`. It is outside the home folder, so it survives volume resets and can't be overridden by user settings.
- Check your employer's policy before using this on a work machine — running Claude in a container is still running Claude on that machine.
