{ final, prev, ... }: prev.nerd-fonts
# { final, prev, ... }: 
#
#   # Missing on 24.11
#   if prev.this.stable then {
#
#     fira-code = prev.nerdfonts.override {
#       fonts = [ "FiraCode" ];
#     };
#
#     monofur = prev.nerdfonts.override {
#       fonts = [ "Monofur" ];
#     };
#
#     jetbrains-mono = prev.nerdfonts.override {
#       fonts = [ "JetBrainsMono" ];
#     };
#
#     symbols-only = prev.nerdfonts.override {
#       fonts = [ "NerdFontsSymbolsOnly" ];
#     };
#
#   } 
#
#   # https://search.nixos.org/packages?channel=unstable&from=0&size=50&sort=relevance&type=packages&query=nerd-fonts.
#   else prev.nerd-fonts
