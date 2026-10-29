# Goliath On-line

Docker container for all your DevOps needs. Goliath On-line!

This is a gaint docker container meant to be a portable DevOps environment you can take with you anywhere. Speed up your laptop setup or your onboarding process at your new job. They will be amazed!
***

## Features

- Configurable at build time
- Inject files at build time to home directory
- Zsh Custom Prompt (spaceship|starship)
- Docker CLI
- Code Server (web VS Code)
- SSH Server
- Hashicorp tools
- Gruntwork tools
- Kubernetes CLI/Helm, k9s, talosctl
- tflint, terraform-docs, yq, direnv, uv, fnm
- Custom tmux/vim themes
- Atuin shell history sync (self-hosted or public server)
- Claude Code with Remote Control
- OpenAI Codex CLI

***

## Building

This image can be built as is out of the box, but there a few options you will want to configure.

1. Copy `build.cfg.example` to `build.cfg` (Build script will do this for you if you want defaults)
2. Edit `build.cfg`
3. Adjust values for your setup. Some of the notable ones are explained below.
    - `BUILD_USER` will be created and its home directory set as the working directory in the container.
    - `GITHUB_TOKEN` set to avoid Github rate limiting
    - `IMAGE_PUSH` will set if the image should be pushed after a successful build or not.
    - `IMAGE_SERVICE` sets if you want to push to Docker Hub or AWS. Be sure to configure the appropriate values.
4. Edit the playbook to configure what options you want enabled.

More info: **[Atuin](#atuin)**

### Custom Home Files

During the build process you can inject files to be part of the image by
placing them in `ansible/files/`.
These files and directories will be copied to the build users home
directory. For example if you want your ssh keys copied, you can plop them in `.ssh` and they will be injected during build time.

Tools are installed to `/usr/local/bin` so they update with each rebuild.
`~/.bin` is on the `PATH` ahead of it for your own tools, such as a version of
Terraform picked with `tfs`.

The image's shell settings live in `/etc/goliath/zshrc` for the same reason.
`~/.zshrc.custom` loads them, and anything you add below that line is kept
across rebuilds.

### Optional Tools

Each tool has a flag under `install` in the playbook.

- `direnv`, `fnm`, `k9s`, `talosctl`, `terraform_docs`, `tflint`, `uv` and `yq`
  are on by default. Set `talosctl_version` to match your cluster.
- `uv` only downloads Python versions when asked to (`uv python install`). Set
  `uv.python_downloads` to `automatic` to let projects fetch the version they
  need.
- `fnm` manages Node versions in your home directory, for example
  `fnm install 24 && fnm default 24`.
- `github_known_hosts` adds GitHub's published SSH host keys, so
  `git@github.com:` remotes work without a prompt.
- `playwright_deps` installs the system libraries for Playwright's Chromium.
  It is off by default since it adds a few hundred MB. Browsers are still
  installed per project with `npx playwright install chromium`.
- `mosh` is off by default. When enabled, publish a UDP range for it in
  `compose.yaml` and connect with
  `mosh --ssh="ssh -p 2222" -p 60000:60010 user@host`.

### Running the build

Once you are happy with your configuation run the follow.

```shell
./docker_build.sh
```

***

## Use Cases

This container can be configured for different roles. Here are few examples to get started.

### Server

 By enabling the SSH server feature you can run as a server for remote
 devops. For example, running on a remote docker server or kubernetes cluster with SSH exposed so you can ssh from your workstation.

 Be sure to enable `ssh_server: yes` in the ansible playbook `ubuntu-docker.yml`.

 The SSH host keys are generated on the first start and kept in the home
 volume under `~/.local/share/goliath/ssh`, so rebuilding the image does not
 change the fingerprint.

### Local

If you want to run the container locally you can run it on demand or keep it running in the background and `docker exec -it` when needed. If SSH server is enabled you could SSH in locally to the container.

When using the container locally you may want to mount your local enviroment so it can be used seamlessly.

Some examples of mounting your local enviornment. Add the following to your `docker run` command.

- `-v ~/.ssh:/home/$BUILD_USER/.ssh`
- `-v ~/.zhistory:/home/$BUILD_USER/.zhistory`
- `-v ${IMAGE_NAME}:/home/$BUILD_USER`
- `-v //var/run/docker.sock:/var/run/docker.sock`
- `-e SSH_AUTH_SOCK=${SSH_AUTH_SOCK} -v $SSH_AUTH_SOCK:${SSH_AUTH_SOCK}`

You could map your entire home directory to the containers user but it's not recommended.

- `-v ~/:/home/$BUILD_USER`

### Code Server

[code-server](https://github.com/coder/code-server) runs VS Code in the browser
on port 8443. It is password protected and served over HTTPS with a
self-signed certificate by default. The password is shown in the container
output at startup.

The certificate is generated on first start and kept in
`~/.local/share/code-server/`. To get a trusted certificate, put it behind a
reverse proxy such as Traefik and connect to the container over HTTPS, skipping
verification of the self-signed certificate (for Traefik, a `serversTransport`
with `insecureSkipVerify`). Keep the route internal, since code-server gives a
shell in the container.

Set `codeserver.cert: no` to serve plain HTTP on the same port, or `codeserver.auth: no` if
your proxy handles authentication.

### AI Coding Agents

Claude Code and the OpenAI Codex CLI can be installed by setting
`install.claude_code` and `install.codex` in the playbook. Both are
installed for the build user, and their logins live in the home directory
(`~/.claude`, `~/.claude.json` and `~/.codex`). Keep the home directory on a
volume (as `docker-run.sh` does) so you stay logged in across restarts.
If you only mount `~/.claude`, also set `-e CLAUDE_CONFIG_DIR=/home/$BUILD_USER/.claude`
so `.claude.json` is stored there too.

#### Claude Remote Control

With the container running on a server, [Remote Control](https://code.claude.com/docs/en/remote-control)
lets you start and drive Claude Code sessions from claude.ai/code or the
Claude mobile app. It only makes outbound HTTPS connections, so no extra
ports need to be exposed.

Remote Control requires a claude.ai subscription login. API keys and
`claude setup-token` tokens do not work with it.

1. SSH or `docker exec` into the container and run `claude auth login`.
2. Run `claude-rc` to start the server in a tmux session and attach to it.
   Answer the one-time prompts, then detach with the tmux prefix + `d`.
3. Open claude.ai/code or the Claude app and select the session named after
   the container hostname.

`claude-rc` also accepts `start`, `stop` and `status`. Sessions start in
`~/workspace` by default. Clone repos there, or set `claude_code.remote_control`
options in the playbook to change the directory, spawn mode or permission mode.
Sessions start in auto mode, where Claude Code checks each action and blocks
risky ones such as force pushes or `terraform destroy`. Once you are
logged in, the server starts when the container boots. Set `autostart: no` to
start it by hand instead. `claude-rc` requires `install.tmux`.

***

## Running the Container

On a Linux server, use Docker Compose so the container starts again after a
reboot. Set `DOCKER_GID` in `build.cfg` to the group of the host Docker socket
(`stat -c %g /var/run/docker.sock`), then run:

```shell
make up
```

Run `make` to list the other targets. `make upgrade` pulls the repo, rebuilds
the image and recreates the container, keeping the home volume. Run it on the
Docker host, since recreating the container from inside it would stop
halfway.

For local use, `docker-run.sh` also mounts your host `~/.ssh`, `~/.kube`,
`~/.aws`, `~/.zhistory` and `~/.docker` when they exist, and works with Docker
Desktop on macOS.

```shell
./docker-run.sh
```

SSH is published on port 2222 by default so it does not clash with an SSH
server on the host. Change `SSH_PORT` and `CODE_SERVER_PORT` in `build.cfg`.

***

## Referances

***

## Atuin

[Atuin](https://atuin.sh) syncs shell history between machines. Sync is
end-to-end encrypted, so a server -- including the public one -- only ever
stores ciphertext.

The sync address and version are set at build time:

```
docker build \
  --build-arg ATUIN_SERVER=https://atuin.example.com \
  --build-arg ATUIN_VERSION=18.19.0 .
```

`ATUIN_SERVER` defaults to the public service at `https://api.atuin.sh`. Point
it at your own [atuin-server](https://docs.atuin.sh/self-hosting/) to keep
history on infrastructure you control.

First run, on one machine:

```
atuin register -u <username> -e <email>
atuin key        # store this somewhere safe
atuin import auto
atuin sync
```

Then on every other machine, using the key printed above:

```
atuin login -u <username> -k "<key>"
atuin sync
```

That key is the only thing that can decrypt synced history. The server cannot
recover it.

### Database location

By default atuin keeps its SQLite databases in the home directory. If the
container home is on a network mount (NFS, SMB) or some bind-mounted volumes,
SQLite's WAL mode can misbehave: the write-ahead log grows without
checkpointing, then `database disk image is malformed`.

Set `atuin.db_on_tmpfs: yes` in the playbook to move the databases to
`/dev/shm` (tmpfs) instead. tmpfs is cleared when the container restarts, so
only use this with sync configured: the history lives server-side and
`atuin sync` rebuilds the local copy. The key and session files stay in the
home directory, so a restart does not require logging in again.

The config is written with `force: no`, so edits made inside a running container
survive image rebuilds. Delete `~/.config/atuin/config.toml` to regenerate it.

## Fonts

https://github.com/tonsky/FiraCode/wiki/Installing

## Ideas

- Option to sync shell history to S3 on write.
- Option to sync fasd db.
- Prompt for `atuin login` on first shell if no session exists.
