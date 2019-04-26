# Saltstack

## Introduction
This is the repo for our configuration management/orchestration. For going into details on how [saltstack](https://docs.saltstack.com/en/latest/contents.html) works please go through the official documentation.

## Local Development Setup
- (Prerequisite) docker, docker-compose and python3.6 for local development
- clone this repo:
```
git clone git@github.com:appliedblockchain/saltstack.git
```

### Install Prerequesites

Python 3.6 (default for ubuntu 18.04)
```
brew install zlib pyenv
```
Run `pyenv init` and follow the instructions
```
pyenv install 3.6.5
```


If you find issues with `pyenv install` not finding the `zlib`,
```
brew info zlib
```
and run the commands under the section `For compilers to find zlib ...`

Pipenv
```
pip3 install pipenv
```

### Vagrant Setup
- (Prerequisite) please have virtualbox and vagrant installed to run dev and test environments
- clone repo as above
- change to the directory where you cloned the repo
- (optional) customize your cluster e.g. by changing the number of minions in `vagrant_overrides.yaml` (you can find an example with all the default options in `templates/vagrant/vagrant_overrides.yaml.example`)

```
vagrant up
```
The above will bring up 2 vm's using vagrant. A master and a minion.

To access the nix vm's:
```
vagrant ssh master
```
```
vagrant ssh minion-local-1
```

### Docker Setup
Docker setup relies on `Makefile`.

```
make docker-setup
```

Then, to access the containers run
```
make master-shell
```

```
make minion-shell
```

### Debugging

Salt can be debugged as a regular python application, the only difference is that you should use `salt` or `salt-call` or any of the other salt commands to run the various modules.

#### Vagrant

Python debugging is not possible ATM using vagrant, because of limitations with the Ubuntu images provided by Hashicorp (Vagrant needs to use root user or some other workaround since `vagrant` user can't run salt).

#### Docker

The development docker containers have an embedded ssh daemon so you can connect a remote debugger. This way you can debug salt natively in a linux context as long as you can ensure a tcp connection into the container.

If you're running locally with the provided `docker-compose.yml` the `salt-masterless` container has its ssh port mapped to the host's `2022` port. Authentication is via ssh key, with the path `${HOME}/.ssh/id_rsa.pub` being bind mounted to `/root/.ssh/authorized_keys`. If you have a different name in your key, please create a symlink (`cd ~/.ssh && ln -s your_key_name.pub id_rsa.pub`).

If everything is configured correctly, running `ssh -p 2022 root@localhost` should log you in to the container automagically.


## Folder Structure
The directory structure of the repo is as follows:
- `salt` -> this directory houses all salt code including states and modules
- `templates` -> templates for configuration and docker files
- `tests` -> tests that ensure validity of modules, states and team specific requirements (To be added)
- `vagrant` -> vagrant provisioning and setup files


### Salt
The salt is the directory where all the code goes.
  
`ext` : Contains custom code that extends/overwrites salt functionality. Their corresponding unit tests go into `tests/unit` directory.

`base` : All salt deployments need a `base` environment to pick the pillar base from. This environment is where we put common pillars. One thing to note here is we don't put state files here. More details in `prd` section.

`dev`, `stg`, `prd` : The other three environments each houses orchestrators, pillars, reactors and states. The pillars here are merged with base environment and overwritten. Orchestrators, reactors and states on the other hand can look ahead. For example: if you have a state `foo` in prd environment, it is available in dev environment. This is possible due to our `file_roots` setting in config. This allows us to have a sane production environment while also support testing new states without the overhead of maintaining two copies of the same state.

`local` : This environment serves as a fake for local development. It should be used to override stuff like pillars that, for instance,
have encrypted values for the remaining environments. Remember to create your own `top.sls` for this environment and do not ever commit your local pillars. `.gitignore` is setup so to ignore most files inside this folder but do make sure you do not commit and add any new case to the `.gitginore`.

### Best Practices and Conventions
Conventions are key in order to improve cross-team colaboration. Here follows some conventions and best practices in order for everyone to chip in safely :)
- All pillars need to have their top level key same as file name to ensure no collision.
- All states need to have their id start from state name.
- All files are snake case.
- All python code needs to be linted by flake8
- The environment should be top level concern so that code from one environment doesn't impact the other until explicitly asked.
- All state files need to have core files to make it easier for future maintenance:
    + state name
        * v(major)_(minor): version folder, ensure it matches the version of the recipe you are installing
            - defaults.yaml: list of all defaults that this recipe needs, also source for all options that can be overwritten
            - init.sls:  base state where things get done by default
            - map.jinja: merge default, pillars and any logic based on os etc
            - metadata.yml: tells us which file, service, package this file edits
            - readme.md: tells what the state does and how to execute for new devs
            - requisite.sls: a state to check whether the state can be run, this was added to support the use case wherein you are upgrading a cluster and need ot ensure that no one else is doing anything
            - verify.sls: state to ensure that everything is setup correctly, cannot modify the system and is only allowed to use modules.
        * latest.sls: this points to latest stable we support
- Ensure that all state files have sane defaults and can be parsed and executed without any custom cli options
- All execution modules and state should follow same template for anyone to diggin. Convention over configuration supported through templates.
