{
  config,
  flake,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.comfyui;
  pin = flake.inputs.pins.default.containers.comfyui;
  # Only repair static JS over the prebuilt image. Never install or compile dependencies.
  context = pkgs.runCommand "comfyui-container" {} ''
    mkdir "$out"
    cp ${pkgs.writeText "Dockerfile" ''
      FROM ${cfg.image}
      COPY frontend-fixes.py impact-sam-editor.js /opt/comfyui-frontend-fixes/
      RUN set -- /nix/store/*-python3-*-env/bin/python3; \
          "$1" /opt/comfyui-frontend-fixes/frontend-fixes.py && \
          rm -r /opt/comfyui-frontend-fixes
    ''} "$out/Dockerfile"
    cp ${./frontend-fixes.py} "$out/frontend-fixes.py"
    cp ${pkgs.fetchurl {
      url = pin.samEditorUrl;
      hash = pin.samEditorHash;
    }} "$out/impact-sam-editor.js"
  '';
  image = "comfyui-patched:${builtins.baseNameOf context}";
in {
  disabledModules = ["services/misc/comfyui.nix"];

  options.services.comfyui = {
    enable = lib.mkEnableOption "ComfyUI in a prebuilt CUDA container";

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/data/comfyui";
      description = "Persistent directory for models, custom nodes, workflows, inputs and outputs.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "jon";
      description = "Existing host user that owns ComfyUI's mutable data and runs the container process.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "users";
      description = "Existing host group that owns ComfyUI's mutable data.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8188;
      description = "Loopback port for ComfyUI's HTTP backend.";
    };

    name = lib.mkOption {
      type = lib.types.str;
      default = "comfyui";
      description = "Private Traefik proxy name.";
    };

    image = lib.mkOption {
      type = lib.types.str;
      default = pin.image;
      description = "Prebuilt CUDA base image, digest-pinned through the pins flake.";
    };
  };

  config = lib.mkIf cfg.enable {
    tmpfiles.directories = [
      {
        target = cfg.dataDir;
        user = cfg.user;
        group = cfg.group;
        mode = "2775";
      }
    ];

    virtualisation.oci-containers.containers.comfyui = {
      inherit image;
      user = "${toString config.users.users.${cfg.user}.uid}:${toString config.users.groups.${cfg.group}.gid}";
      volumes = ["${cfg.dataDir}:/data"];
      ports = ["127.0.0.1:${toString cfg.port}:8188"];
      environment = {
        HOME = "/data";
        USER = cfg.user;
        LOGNAME = cfg.user;
      };
      entrypoint = "/bin/sh";
      cmd = [
        "-c"
        "umask 0002; exec /bin/comfy-ui --listen 0.0.0.0 --port 8188 --enable-manager"
      ];
      extraOptions = [
        "--device=nvidia.com/gpu=all"
        "--cap-drop=ALL"
        "--security-opt=no-new-privileges"
        "--read-only"
        "--tmpfs=/tmp:rw,nosuid,nodev,mode=1777"
      ];
    };

    systemd.services.docker-comfyui = {
      after = ["systemd-tmpfiles-setup.service" "nvidia-container-toolkit-cdi-generator.service"];
      requires = ["nvidia-container-toolkit-cdi-generator.service"];
      unitConfig.RequiresMountsFor = [cfg.dataDir];
      serviceConfig.ExecStartPre = lib.mkBefore [
        (lib.getExe (pkgs.self.mkScript {
          name = "comfyui-image";
          path = [config.virtualisation.docker.package];
          text =
            # bash
            ''
              if ! docker image inspect ${lib.escapeShellArg image} >/dev/null 2>&1; then
                docker build --network=none --pull=false --tag ${lib.escapeShellArg image} ${context}
              fi
            '';
        }))
      ];
    };

    services.traefik = {
      enable = true;
      proxy.${cfg.name} = "http://127.0.0.1:${toString cfg.port}";
      # Keep the browser Host/Origin match instead of rewriting Host to loopback.
      dynamicConfigOptions.http.middlewares.${cfg.name}.headers.customRequestHeaders.Host =
        lib.mkForce (config.services.traefik.lib.mkHostName cfg.name);
    };
  };
}
