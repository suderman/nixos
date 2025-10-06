# NixOS & Home Manager modules

Each of these directories are available under `flake.nixosModules.*` and
`flake.homeModules.*`. The `flake.nixosModules.default` module should be
imported into every `host` configuration and includes shared NixOS configuration
and custom module options. The `flake.homeModules.default` module should be
imported into every `home` configuration and includes shared home-manager
configuration and custom module options.

## Extended options

Here are a few notable extensions to the options available in NixOS and
home-manager modules:

### `config.persist`

The `persist` option is a wrapper for `environment.persistence` and available
for both
[NixOS](https://github.com/suderman/nixos/blob/main/modules/nixos/default/configs/impermanence.nix)
and
[home-manager](https://github.com/suderman/nixos/blob/main/modules/home/default/configs/impermanence.nix)
modules. Examples:

```nix
# "storage" persists reboots and has snapshots + backups
config.persist.storage.directories = [
  "/var/lib/nixos"
  {
    directory = "/var/lib/colord";
    user = "colord";
    group = "colord";
    mode = "u=rwx,g=rx,o=";
  }
];

config.persist.storage.files = [
  "/etc/machine-id"
  {
    file = "/var/keys/secret_file";
    parentDirectory = { mode = "u=rwx,g=,o="; }; 
  }
];

# "scratch" persists reboots without snapshots or backups
config.persist.scratch.directories = ["/var/log"];
config.persist.scratch.files = ["/opt/persist-without-backups.txt"];
```

### `config.tmpfiles`

The `tmpfiles` option is a wrapper for `systemd.tmpfiles.rules` and available
for both
[NixOS](https://github.com/suderman/nixos/blob/main/modules/nixos/default/configs/tmpfiles.nix)
and
[home-manager](https://github.com/suderman/nixos/blob/main/modules/home/default/configs/tmpfiles.nix)
modules. Examples:

```nix
# nixos
config.tmpfiles.directories = [
  "/etc/ensure-this-dir-exists"
  {
    target = "/etc/my-copied-dir"; 
    source = "/mnt/example/original-dir";
    user = "someuser"; 
    group = "somegroup"; 
    mode = 775; 
  }
];

# home-manager (relative to home dir, assumes user/group)
config.tmpfiles.directories = [
  ".mydir"
  {
    target = ".local/share/example-dir"; 
    source = "/mnt/example/original-dir";
    mode = 700; 
  }
];

# nixos
config.tmpfiles.files = [
  {
    target = "/etc/my-copied-file.txt"; 
    source = "/mnt/example/original-file.txt";
    user = "jon"; 
    group = "users"; 
    mode = 775; 
  }
  {
    target = "/etc/my-created-file.txt"; 
    text = "Hello world!";
    user = "jon"; 
    group = "users"; 
    mode = 775; 
  }
];

# home-manager
config.tmpfiles.files = [
  ".config/example-file.yaml"
];


# nixos / home-manager
config.tmpfiles.symlinks = [
  {
    target = "/tmp/my-symlink.txt"; 
    source = "/mnt/example/my-real-file.txt";
  }
];
```

### `config.networking`

The `networking` option was included in
[home-manager](https://github.com/suderman/nixos/blob/main/modules/home/default/configs/networking.nix)
and extended in
[NixOS](https://github.com/suderman/nixos/blob/main/modules/nixos/default/configs/networking.nix)
with the following options:

```nix
# All hostnames this host can be reached at 
config.networking.homeNames = ["kit" "kit.home" "kit.tail"];

# Primary IP address this host can be reached at";
config.networking.address = "10.1.0.6";

# All IP addresses this host can be reached at
config.networking.addresses = ["127.0.0.1" "10.1.0.6" "100.67.76.42"];
```

### `config.home`

The `home` option was extended in
[home-manager](https://github.com/suderman/nixos/blob/main/modules/home/default/configs/home.nix)
with the following options:

```nix
# Rename and create custom XDG user directories (optionally persisted)
config.home.directories.XDG_NAME_DIR = {
  path = "Name"; # relative to user home directory
  persist = "storage"; # set to "storage", "scratch" or null
  sync = true; # add folder to syncthing
  enable = true;
};

# List of paths to move to writeable ~/.local/store to ease tinkering with configurations
config.home.localStorePath = [
  ".config/hypr/hyprland.conf"
  ".config/waybar/config"
  ".config/waybar/style.css"
];

# Lookup uid from flake.users.<name>.uid
config.home.uid = 1000;

# Calculated offet added to ports (uid - 1000)
config.home.portOffset = 0;
```

### `config.services.btrbk`

The `services.btrbk` module has been extended in
[NixOS](https://github.com/suderman/nixos/blob/main/modules/nixos/default/options/btrbk.nix)
with a new `volumes` option that declares which mounts get snapshots (subvolume
`storage`) and an option list of targets for backups:

```nix
services.btrbk.volumes = with config.networking; {
  "/mnt/main" = ["ssh://fit/mnt/pool/backups/${hostName}" "ssh://eve/mnt/pool/backups/${hostName}"];
  "/mnt/data" = ["ssh://fit/mnt/pool/backups/${hostName}"];
  "/mnt/game" = []; # no backups, just local snapshots
};
```
