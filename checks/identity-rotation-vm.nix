{
  flake,
  pkgs,
  perSystem,
  ...
}: let
  fixtures =
    pkgs.runCommand "identity-rotation-vm-fixtures" {
      nativeBuildInputs = [
        pkgs.age
        perSystem.self.derive
      ];
    } ''
      mkdir -p "$out"

      for host in alpha beta; do
        for generation in current next; do
          root=${../secrets/rotation/fixtures}/$generation.hex
          derive hex "$host" <"$root" | derive ssh >"$out/$host-host-$generation"
          derive public <"$out/$host-host-$generation" >"$out/$host-host-$generation.pub"
          derive hex "$host" <"$root" | derive age >"$out/$host-age-$generation"
          derive public <"$out/$host-age-$generation" >"$out/$host-age-$generation.pub"
        done

        current_recipient="$(<"$out/$host-age-current.pub")"
        next_recipient="$(<"$out/$host-age-next.pub")"
        printf '%s-current\n' "$host" |
          age --encrypt --recipient "$current_recipient" --output "$out/$host-current.age"
        printf '%s-next\n' "$host" |
          age --encrypt --recipient "$next_recipient" --output "$out/$host-next.age"
        printf '%s-dual\n' "$host" |
          age --encrypt \
            --recipient "$current_recipient" \
            --recipient "$next_recipient" \
            --output "$out/$host-dual.age"
      done

      derive hex client <${../secrets/rotation/fixtures/current.hex} | derive ssh >"$out/client"
      derive public <"$out/client" >"$out/client.pub"
    '';

  nodeModule = hostName: {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.testIdentityRotation;
    peerName =
      if hostName == "alpha"
      then "beta"
      else "alpha";
    stateDir = "/var/lib/identity-rotation";
    currentHostKey = "${stateDir}/ssh_host_ed25519_key";
    nextHostKey = "${currentHostKey}.next";
    currentAgeIdentity = "${stateDir}/id_age";
    nextAgeIdentity = "${currentAgeIdentity}.next";
    fixture = name: "${fixtures}/${hostName}-${name}";
    peerFixture = name: "${fixtures}/${peerName}-${name}";
    selectedGeneration = cfg.generation;
    selectedMachineId = builtins.fromJSON (builtins.readFile ../secrets/rotation/fixtures/vectors.json);
  in {
    imports = [flake.inputs.agenix.nixosModules.default];

    options.testIdentityRotation = {
      active = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      targetState = lib.mkOption {
        type = lib.types.enum ["current" "bridge" "next"];
        default = "current";
      };
      generation = lib.mkOption {
        type = lib.types.enum ["current" "next"];
        default = "current";
      };
    };

    config = {
      networking.hostName = hostName;
      system.stateVersion = "26.05";
      virtualisation.memorySize = 512;

      environment.systemPackages = [
        perSystem.self.derive
        pkgs.openssh
      ];

      users.users.root.openssh.authorizedKeys.keys = [
        (builtins.readFile "${fixtures}/client.pub")
      ];

      services.openssh = {
        enable = true;
        hostKeys = let
          current = {
            path = currentHostKey;
            type = "ed25519";
          };
          next = current // {path = nextHostKey;};
        in
          if !cfg.active
          then [current]
          else if cfg.targetState == "current"
          then [current]
          else if cfg.targetState == "bridge"
          then [current next]
          else [next current];
        settings = {
          PasswordAuthentication = false;
          PermitRootLogin = "prohibit-password";
        };
      };

      programs.ssh.knownHosts = let
        canonicalPeerGeneration =
          if cfg.active
          then "current"
          else selectedGeneration;
      in
        {
          ${peerName} = {
            hostNames = [peerName];
            publicKey = builtins.readFile (peerFixture "host-${canonicalPeerGeneration}.pub");
          };
        }
        // lib.optionalAttrs cfg.active {
          "${peerName}-rotation" = {
            hostNames = [peerName];
            publicKey = builtins.readFile (peerFixture "host-next.pub");
          };
        };

      age = {
        identityPaths =
          [currentAgeIdentity]
          ++ lib.optional cfg.active nextAgeIdentity;
        secrets =
          if cfg.active
          then {
            current.file = fixture "current.age";
            next.file = fixture "next.age";
            dual.file = fixture "dual.age";
          }
          else if selectedGeneration == "next"
          then {next.file = fixture "next.age";}
          else {current.file = fixture "current.age";};
      };

      system.activationScripts.rotationFixture = {
        deps = ["specialfs"];
        text = let
          currentMachineId = selectedMachineId.current.${hostName}.machineId;
          nextMachineId = selectedMachineId.next.${hostName}.machineId;
          machineId =
            if cfg.active && cfg.targetState == "next" || selectedGeneration == "next"
            then nextMachineId
            else currentMachineId;
        in ''
          set -euo pipefail
          install -d -m 700 ${stateDir} /root/.ssh
          install -m 600 ${fixtures}/client /root/.ssh/id_ed25519

          verify_fixture() {
            local private_key="$1" fixture_key="$2"
            ${pkgs.diffutils}/bin/cmp -s "$private_key" "$fixture_key"
          }

          if [[ ! -s ${currentHostKey} ]]; then
            install -m 600 ${fixture "host-current"} ${currentHostKey}
          fi
          if [[ ! -s ${currentAgeIdentity} ]]; then
            install -m 600 ${fixture "age-current"} ${currentAgeIdentity}
          fi

          ${lib.optionalString cfg.active ''
            verify_fixture ${currentHostKey} ${fixture "host-current"}
            verify_fixture ${currentAgeIdentity} ${fixture "age-current"}
            install -m 600 ${fixture "host-next"} ${nextHostKey}
            install -m 600 ${fixture "age-next"} ${nextAgeIdentity}
            verify_fixture ${nextHostKey} ${fixture "host-next"}
            verify_fixture ${nextAgeIdentity} ${fixture "age-next"}
          ''}

          ${lib.optionalString (!cfg.active && selectedGeneration == "current") ''
            verify_fixture ${currentHostKey} ${fixture "host-current"}
            verify_fixture ${currentAgeIdentity} ${fixture "age-current"}
            rm -f ${nextHostKey} ${nextAgeIdentity}
          ''}

          ${lib.optionalString (!cfg.active && selectedGeneration == "next") ''
            verify_fixture ${nextHostKey} ${fixture "host-next"}
            verify_fixture ${nextAgeIdentity} ${fixture "age-next"}
            mv ${nextHostKey} ${currentHostKey}
            mv ${nextAgeIdentity} ${currentAgeIdentity}
            verify_fixture ${currentHostKey} ${fixture "host-next"}
            verify_fixture ${currentAgeIdentity} ${fixture "age-next"}
          ''}

          printf '%s\n' ${lib.escapeShellArg machineId} >${stateDir}/machine-id
        '';
      };
      system.activationScripts.agenixInstall.deps = ["rotationFixture"];

      specialisation = {
        prepared.configuration.testIdentityRotation = {
          active = true;
          targetState = "current";
        };
        bridge.configuration.testIdentityRotation = {
          active = true;
          targetState = "bridge";
        };
        next.configuration.testIdentityRotation = {
          active = true;
          targetState = "next";
        };
        finalized.configuration.testIdentityRotation = {
          generation = "next";
        };
      };
    };
  };
in
  pkgs.testers.runNixOSTest {
    name = "identity-rotation-vm";
    nodes = {
      alpha = nodeModule "alpha";
      beta = nodeModule "beta";
    };
    testScript = {nodes, ...}: let
      alphaSystem = nodes.alpha.system.build.toplevel;
      betaSystem = nodes.beta.system.build.toplevel;
    in ''
      start_all()
      alpha.wait_for_unit("sshd.service")
      beta.wait_for_unit("sshd.service")

      systems = {
        "alpha": "${alphaSystem}",
        "beta": "${betaSystem}",
      }
      node_map = {"alpha": alpha, "beta": beta}

      def switch(name, phase):
        node_map[name].succeed(
          f"{systems[name]}/specialisation/{phase}/bin/switch-to-configuration test >&2"
        )
        node_map[name].wait_for_unit("sshd.service")

      def assert_pair(machine, private_key, public_key):
        machine.succeed(
          f'test "$(derive public <{private_key} | xargs)" = "$(xargs <{public_key})"'
        )

      def assert_probe(machine, name, value):
        machine.succeed(f"grep -qx {value} /run/agenix/{name}")

      def assert_ssh(source, target):
        source.succeed(
          f"ssh -o BatchMode=yes -o StrictHostKeyChecking=yes root@{target} true"
        )

      state_dir = "/var/lib/identity-rotation"

      with subtest("current generation boots and decrypts"):
        assert_probe(alpha, "current", "alpha-current")
        assert_probe(beta, "current", "beta-current")
        assert_pair(alpha, f"{state_dir}/ssh_host_ed25519_key", "${fixtures}/alpha-host-current.pub")
        assert_pair(beta, f"{state_dir}/ssh_host_ed25519_key", "${fixtures}/beta-host-current.pub")
        assert_ssh(alpha, "beta")
        assert_ssh(beta, "alpha")

      with subtest("all-current preparation publishes both identities"):
        switch("alpha", "prepared")
        switch("beta", "prepared")
        for name, machine in node_map.items():
          assert_probe(machine, "current", f"{name}-current")
          assert_probe(machine, "next", f"{name}-next")
          assert_probe(machine, "dual", f"{name}-dual")
          machine.succeed(f"test -s {state_dir}/ssh_host_ed25519_key.next")
          machine.succeed(f"test -s {state_dir}/id_age.next")
        assert_ssh(alpha, "beta")
        assert_ssh(beta, "alpha")

      with subtest("one node advances while its peer remains current"):
        switch("alpha", "bridge")
        assert_ssh(alpha, "beta")
        assert_ssh(beta, "alpha")
        switch("alpha", "next")
        assert_pair(alpha, f"{state_dir}/ssh_host_ed25519_key.next", "${fixtures}/alpha-host-next.pub")
        alpha.succeed("grep -qx ee6e7e9f76313e4dceeb06c924638ff7 /var/lib/identity-rotation/machine-id")
        assert_ssh(alpha, "beta")
        assert_ssh(beta, "alpha")

      with subtest("persistent keys survive target rollback and cancel"):
        switch("alpha", "bridge")
        switch("alpha", "prepared")
        assert_pair(alpha, f"{state_dir}/ssh_host_ed25519_key", "${fixtures}/alpha-host-current.pub")
        assert_pair(alpha, f"{state_dir}/ssh_host_ed25519_key.next", "${fixtures}/alpha-host-next.pub")
        alpha.succeed("${alphaSystem}/bin/switch-to-configuration test >&2")
        alpha.wait_for_unit("sshd.service")
        alpha.fail(f"test -e {state_dir}/ssh_host_ed25519_key.next")
        alpha.fail(f"test -e {state_dir}/id_age.next")
        assert_pair(alpha, f"{state_dir}/ssh_host_ed25519_key", "${fixtures}/alpha-host-current.pub")
        assert_probe(alpha, "current", "alpha-current")

      with subtest("both nodes advance and finalize on next identities"):
        for name in node_map:
          switch(name, "prepared")
          switch(name, "bridge")
          switch(name, "next")
        assert_ssh(alpha, "beta")
        assert_ssh(beta, "alpha")

        for name, machine in node_map.items():
          switch(name, "finalized")
          machine.fail(f"test -e {state_dir}/ssh_host_ed25519_key.next")
          machine.fail(f"test -e {state_dir}/id_age.next")
          assert_pair(
            machine,
            f"{state_dir}/ssh_host_ed25519_key",
            f"${fixtures}/{name}-host-next.pub",
          )
          assert_pair(
            machine,
            f"{state_dir}/id_age",
            f"${fixtures}/{name}-age-next.pub",
          )
          assert_probe(machine, "next", f"{name}-next")

        assert_ssh(alpha, "beta")
        assert_ssh(beta, "alpha")
    '';
  }
