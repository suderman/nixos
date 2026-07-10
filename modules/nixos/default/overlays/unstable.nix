{flake, ...}: {
  nixpkgs.overlays = [
    (_final: prev: {
      unstable = import flake.inputs.nixpkgs-unstable {
        system = prev.stdenv.hostPlatform.system;
        config = prev.config;
        overlays = [
          (_final: unstablePrev: {
            pythonPackagesExtensions =
              (unstablePrev.pythonPackagesExtensions or [])
              ++ [
                (_pyFinal: pyPrev: {
                  click-threading = pyPrev.click-threading.overridePythonAttrs (_old: {
                    enabledTestPaths = ["tests"];
                  });
                })
              ];
          })
        ];
      };
    })
  ];
}
