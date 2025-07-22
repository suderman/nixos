{
  config,
  perSystem,
  ...
}: let
  nvimSecrets = config.age.secrets.neovim.path;
  nvimPackage = perSystem.neovim.default;
in {
  age.secrets.neovim = {
    rekeyFile = ./neovim.age;
    mode = "440";
    group = "users";
  };

  environment.systemPackages = [
    (
      perSystem.self.mkScript {
        name = "nvim";
        text =
          # bash
          ''
            if [[ -f ${nvimSecrets} ]]; then
              while IFS='=' read -r key value; do
                if [[ -n "$key" && -z "''${!key}" ]]; then
                  export "$key"="$value"
                fi
              done < ${nvimSecrets}
            fi
            exec ${nvimPackage}/bin/nvim "$@"
          '';
      }
    )
  ];
}
