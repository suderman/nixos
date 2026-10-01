{
  flake,
  pkgs,
  ...
}: let
  serverPin = flake.inputs.pins.default.github.camofox-browser;
  enginePin = flake.inputs.pins.default.fetchurl.camoufox;
  engineVersion = pkgs.lib.splitString "-" enginePin.version;
  runtimeLibs = with pkgs; [
    stdenv.cc.cc.lib
    alsa-lib
    dbus-glib
    gtk3
    libX11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxrender
    libxcb
    libxtst
    pango
  ];
  runtimeLibPath = pkgs.lib.makeLibraryPath runtimeLibs;
  engine = pkgs.stdenv.mkDerivation {
    pname = "camoufox";
    inherit (enginePin) version;
    src = pkgs.fetchurl {
      inherit (enginePin) url sha256;
    };
    nativeBuildInputs = [pkgs.unzip pkgs.patchelf];
    buildInputs = runtimeLibs;
    dontUnpack = true;
    # Rewriting bundled libraries breaks libxul's dynamic initializers.
    dontFixup = true;
    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      unzip -q "$src" -d "$out"
      chmod -R u+w "$out"
      for executable in camoufox camoufox-bin vulkantest; do
        chmod +x "$out/$executable"
        patchelf --set-interpreter "${pkgs.stdenv.cc.bintools.dynamicLinker}" \
          --set-rpath "$out:${runtimeLibPath}" "$out/$executable"
      done
      printf '%s\n' '${builtins.toJSON {
        version = builtins.head engineVersion;
        release = builtins.elemAt engineVersion 1;
      }}' > "$out/version.json"
      runHook postInstall
    '';
  };
in
  pkgs.buildNpmPackage {
    pname = "camofox-browser";
    inherit (serverPin) version npmDepsHash;
    src = pkgs.fetchFromGitHub {
      inherit (serverPin) owner repo rev hash;
    };
    # The upstream postinstall fetches the newest browser, independently of the client.
    npmFlags = ["--ignore-scripts"];
    npmInstallFlags = ["--omit=optional"];
    nativeBuildInputs = [pkgs.python3];
    postConfigure = ''
      npm rebuild better-sqlite3 --build-from-source --ignore-scripts=false
    '';
    postInstall = ''
      # camoufox-js ignores XDG_CACHE_HOME and looks under os.homedir().
      wrapProgram "$out/bin/camofox-browser" \
        --prefix PATH : "${pkgs.lib.makeBinPath [pkgs.coreutils]}" \
        --prefix LD_LIBRARY_PATH : "${runtimeLibPath}" --run '
        umask 077
        export HOME="''${XDG_CACHE_HOME:-$HOME/.cache/camofox-browser}/runtime-home"
        mkdir -p "$HOME/.cache"
        ln -sfnT "${engine}" "$HOME/.cache/camoufox"
      '
    '';
    passthru = {inherit engine;};
    meta = {
      description = "Camofox REST server with a compatible, pinned Camoufox browser";
      homepage = "https://github.com/redf0x1/camofox-browser";
      license = pkgs.lib.licenses.mit;
      platforms = ["x86_64-linux"];
    };
  }
