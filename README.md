# Goliath On-line

Docker container for all your DevOps needs. Goliath On-line!

This is a gaint docker container meant to be a portable DevOps environment you can take with you anywhere. Speed up your laptop setup or your onboarding process at your new job. They will be amazed!
***

## Features

- Configurable at build time
- Inject files at build time to home directory
- Zsh Custom Prompt (spaceship|starship)
- Docker CLI
- SSH Server
- Hashicorp tools
- Gruntwork tools
- Kubernetes CLI/Helm
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
options in the playbook to change the directory or spawn mode. Once you are
logged in, the server starts when the container boots. Set `autostart: no` to
start it by hand instead. `claude-rc` requires `install.tmux`.

***

## Running the Container

On a Linux server, use Docker Compose so the container starts again after a
reboot. Set `DOCKER_GID` in `build.cfg` to the group of the host Docker socket
(`stat -c %g /var/run/docker.sock`), then run:

```shell
docker compose --env-file build.cfg up -d
```

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
