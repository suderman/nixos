{ final, prev, ... }: 

  # Missing on 24.11
  if prev.this.stable then {

    symbols-only = prev.nerdfonts.override {
      fonts = [ "NerdFontsSymbolsOnly" ];
    };

    jetbrains-mono = prev.nerdfonts.override {
      fonts = [ "JetBrainsMono" ];
    };

  } 

  # https://search.nixos.org/packages?channel=unstable&from=0&size=50&sort=relevance&type=packages&query=nerd-fonts.
  else prev.nerd-fonts
