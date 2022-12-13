# Dotfiles

Jon's dotfiles and system configuration

## Install home-manager 

<https://nix-community.github.io/home-manager/index.html#sec-install-standalone>

```
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
export NIX_PATH=$HOME/.nix-defexpr/channels:/nix/var/nix/profiles/per-user/root/channels${NIX_PATH:+:$NIX_PATH}
nix-shell '<home-manager>' -A install
source $HOME/.nix-profile/etc/profile.d/hm-session-vars.sh
```

## Browse config

```
nix repl
:lf .
nixosConfigurations.<tab>
```

## Env

```
PUID
PGID
UMASK
TZ
SELF_MEDIA_DIR

# baikal
MYSQL_DATABASE
MYSQL_USER
MYSQL_PASSWORD
MYSQL_ROOT_PASSWORD


DOZZLE_KEY (alpha secret)

FRESHRSS_INSTALL
FRESHRSS_USER

GITEA__database__PASSWD
```
