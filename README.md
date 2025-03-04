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
- Bashhub (Custom Server) via ENV

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

More info: **[Bashhub](#bashhub)**

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

***

## Running the Container

Edit `docker_run.sh` for an example of mounting various home dir configs.

```shell
./docker_run.sh
```

***

## Referances

***

## Bashhub

Bashhub allows you to sync your bash or zshell history to the cloud or your own private server. You can set the address of your private server at build time via `build.cfg` or run time via
Docker Env.

`-e BH_URL=https://supersecret-bashhub.homelab`

**Note:** If already set at build time, the run time env won't override it. Either disable during build or remove from `~/.zshrc.custom` for the curren session and relogin.

https://github.com/nicksherron/bashhub-server
https://github.com/rcaloras/bashhub-client

## Fonts

https://github.com/tonsky/FiraCode/wiki/Installing

## Ideas

- Option to sync shell history to S3 on write.
- Option to sync fasd db.
- Autorun bashhub setup on first login via flag file.
