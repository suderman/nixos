{
  config,
  perSystem,
  ...
}: {
  age.secrets.neovim = {
    rekeyFile = ./neovim.age;
    mode = "440";
    group = "users";
  };
  nixpkgs.overlays = [
    (_final: _prev: {
      nvf = (
        perSystem.self.mkScript {
          name = "nvim";
          text =
            # bash
            ''
              if [[ -f ${config.age.secrets.neovim.path} ]]; then
                while IFS='=' read -r key value; do
                  if [[ -n "$key" && -z "''${!key-}" ]]; then
                    export "$key"="$value"
                  fi
                done <${config.age.secrets.neovim.path}
              fi
              exec ${perSystem.neovim.default}/bin/nvim "$@"
            '';
        }
      );
    })
  ];
}
