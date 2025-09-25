# NixOS & Home Manager modules

Each of these directories are included via
[numtide's blueprint](https://numtide.github.io/blueprint/main/getting-started/folder_structure/)
and available under `flake.nixosModules.*` and `flake.homeModules.*`. The
`flake.nixosModules.default` module should be imported into every `host`
configuration and includes shared NixOS configuration and custom module options.
The `flake.homeModules.default` module should be imported into every `home`
configuration and includes shared home-manager configuration and custom module
options.

## Extended options

Here are a few notable extensions to the options available in NixOS and
home-manager modules:

### `config.persist`

The `persist` option is a wrapper for `environment.persistence` and available
for both NixOS and home-manager modules. Examples:

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
for both NixOS and home-manager modules. Examples:

```nix
config.tmpfiles.directories = [
  "/etc/ensure-this-dir-exists"
  {
    target = "/etc/my-copied-dir"; 
    source = "/mnt/example/original-dir";
    user = "jon"; 
    group = "users"; 
    mode = 775; 
  }
];

config.tmpfiles.files = [
  "/etc/ensure-this-file-exists"
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

config.tmpfiles.symlinks = [
  {
    target = "/etc/my-symlink.txt"; 
    source = "/mnt/example/my-real-file.txt";
  }
];
```

### `config.networking`

The `networking` option was included in home-manager and extended in NixOS with
the following options:

```nix
# All hostnames this host can be reached at 
config.networking.homeNames = ["kit" "kit.home" "kit.tail"];

# Primary IP address this host can be reached at";
config.networking.address = "10.1.0.6";

# All IP addresses this host can be reached at
config.networking.addresses = ["127.0.0.1" "10.1.0.6" "100.110.44.15"];
```

### `config.home`

The `home` option was extended in home-manager with the following options:

```nix
# Path to home scratch directory
config.home.scratchDirectory = "/home/jon/scratch";

# Path to home storage directory
config.home.storageDirectory = "/home/jon/storage";

# Lookup uid from flake.users.<name>.uid
config.home.uid = 1000;

# Calculate offet added to ports (uid - 1000)
config.home.offset = 0;
```
