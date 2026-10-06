# Disposable test only. Public roots and credentials must never be used on real hosts.
{
  flake,
  pkgs,
  lib,
}: let
  derive = flake.packages.x86_64-linux.derive;
  fixtures = pkgs.runCommand "dot-public-test-fixtures" {nativeBuildInputs = [pkgs.openssh pkgs.age pkgs.git derive];} ''
    mkdir -p "$out/hosts/dot" "$out/secrets" "$out/zones"
    # Exercise the normal checkout hook without fetching GitHub in the VM.
    git init --quiet "$out/agents"
    cp ${../../secrets/rotation/fixtures/current.hex} "$out/root.hex"
    cp ${../../secrets/default.nix} "$out/secrets/default.nix"
    cp ${../../zones/ca.crt} "$out/zones/ca.crt"
    derive hex dot <"$out/root.hex" | derive ssh >"$out/host"
    derive public <"$out/host" >"$out/host.pub"
    cp "$out/host.pub" "$out/hosts/dot/ssh_host_ed25519_key.pub"
    derive hex dot 32 <"$out/root.hex" >"$out/machine-id"
    for user in ${lib.concatStringsSep " " (builtins.attrNames flake.users)}; do
      mkdir -p "$out/users/$user"
      derive hex "$user" <"$out/root.hex" | derive ssh >"$out/users/$user/id_ed25519"
      derive public <"$out/users/$user/id_ed25519" >"$out/users/$user/id_ed25519.pub"
      derive hex "$user" <"$out/root.hex" | derive age >"$out/users/$user/id_age"
      derive public <"$out/users/$user/id_age" >"$out/users/$user/id_age.pub"
    done
    for name in client installer; do
      ssh-keygen -q -t ed25519 -N "" -C "dot-vm-test-only" -f "$out/$name"
    done
    age -r "$(cat "$out/host.pub")" <"$out/root.hex" >"$out/hex.age"
    printf 'dot-test-only\n' | age -r "$(cat "$out/host.pub")" >"$out/password.age"
    printf 'dot-test-secret\n' | age -r "$(cat "$out/host.pub")" >"$out/probe.age"
    printf 'dot-test-secret\n' | age -r "$(cat "$out/users/jon/id_age.pub")" >"$out/home.age"
  '';
  # Substitute public test identities, while running the real shared activation.
  testFlake =
    flake
    // {
      outPath = fixtures;
      users = lib.mapAttrs (name: user:
        if builtins.elem name ["root" "jon"]
        then user // {openssh.authorizedKeys.keys = [(builtins.readFile "${fixtures}/client.pub")];}
        else user)
      flake.users;
    };
  dot = flake.nixosConfigurations.dot;
  installed = dot.extendModules {
    specialArgs.flake = testFlake;
    modules = [
      {
        age.secrets =
          lib.mapAttrs (name: _: {
            rekeyFile = lib.mkForce null;
            file = lib.mkForce "${fixtures}/${
              if name == "hex"
              then "hex"
              else "password"
            }.age";
          })
          dot.config.age.secrets
          // {
            dot-vm-probe.file = "${fixtures}/probe.age";
          };
        home-manager.extraSpecialArgs = lib.mkForce (dot.config.home-manager.extraSpecialArgs // {flake = testFlake;});
        home-manager.users.jon.age.secrets =
          lib.mapAttrs (_: _: {
            rekeyFile = lib.mkForce null;
            file = lib.mkForce "${fixtures}/home.age";
          })
          dot.config.home-manager.users.jon.age.secrets;
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
