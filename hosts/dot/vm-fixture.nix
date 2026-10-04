# Disposable test only. These deliberately public dummy credentials are not fleet identities.
{
  flake,
  pkgs,
  lib,
}: let
  fixtures = pkgs.runCommand "dot-public-test-fixtures" {nativeBuildInputs = [pkgs.openssh pkgs.openssl pkgs.age];} ''
    mkdir "$out"
    for name in host client installer; do
      ssh-keygen -q -t ed25519 -N "" -C "dot-vm-test-only" -f "$out/$name"
    done
    openssl passwd -6 -salt dot-test-only dot-test-only >"$out/recovery.hash"
    printf '%s\n' 9dbbfc8683d44058b9a2f2f837430168 >"$out/machine-id"
    printf 'dot-test-secret\n' | age -r "$(cat "$out/host.pub")" >"$out/probe.age"
  '';
  dot = flake.nixosConfigurations.dot;
  installed = dot.extendModules {
    modules = [
      {
        dot.backupPublicKey = builtins.readFile "${fixtures}/client.pub";
        users.users.root.openssh.authorizedKeys = lib.mkForce {keys = [(builtins.readFile "${fixtures}/client.pub")];};
        users.users.jon.openssh.authorizedKeys = lib.mkForce {keys = [(builtins.readFile "${fixtures}/client.pub")];};
        age.rekey.hostPubkey = lib.mkForce (builtins.readFile "${fixtures}/host.pub");
        age.secrets.dot-vm-probe.file = "${fixtures}/probe.age";
        systemd.services.dot-identity.script = lib.mkForce (lib.replaceStrings
          ["${./ssh_host_ed25519_key.pub}"] ["${fixtures}/host.pub"]
          dot.config.systemd.services.dot-identity.script);
      }
    ];
  };
  installer = flake.inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ({modulesPath, ...}: {imports = [(modulesPath + "/virtualisation/qemu-vm.nix")];})
      {
        networking.hostName = "dot-installer-test";
        system.stateVersion = "26.05";
        system.nixos.variant_id = "installer";
        virtualisation = {
          memorySize = 4096;
          graphics = false;
          diskImage = "installer.qcow2";
          forwardPorts = [
            {
              from = "host";
              host.address = "127.0.0.1";
              host.port = 22281;
              guest.port = 22;
            }
          ];
          qemu.options = ["-drive file=system.qcow2,format=qcow2,if=ide"];
        };
        services.openssh = {
          enable = true;
          hostKeys = [
            {
              path = "/etc/ssh/ssh_host_ed25519_key";
              type = "ed25519";
            }
          ];
          settings = {
            PermitRootLogin = "prohibit-password";
            PasswordAuthentication = false;
            KbdInteractiveAuthentication = false;
          };
        };
        users.users.root.hashedPassword = lib.mkForce "";
        users.users.root.openssh.authorizedKeys.keys = [(builtins.readFile "${fixtures}/client.pub")];
        system.activationScripts.installerKey.text = ''
          install -D -m600 ${fixtures}/installer /etc/ssh/ssh_host_ed25519_key
        '';
        boot.supportedFilesystems = ["btrfs"];
        environment.systemPackages = [pkgs.jq pkgs.openssh];
        nix.settings.experimental-features = ["nix-command" "flakes"];
      }
    ];
  };
in {
  inherit fixtures;
  system = installed.config.system.build.toplevel;
  second = (installed.extendModules {modules = [{environment.etc."dot-vm-generation".text = "second";}];}).config.system.build.toplevel;
  disko = installed.config.system.build.diskoScript;
  mount = installed.config.system.build.mountScript;
  installer = installer.config.system.build.vm;
  tools = pkgs.buildEnv {
    name = "dot-test-tools";
    paths = [pkgs.qemu pkgs.nixos-anywhere (pkgs.python3.withPackages (p: [p.pexpect]))];
  };
}
