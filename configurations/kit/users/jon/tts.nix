# https://github.com/badly-drawn-wizards/dotfiles/blob/master/home-manager/tts.nix
{ config, lib, pkgs, ... }: {}

# let
#   speechdDir = ".config/speech-dispatcher";
#   configFile = "${speechdDir}/speechd.conf";
#   moduleDir = "${speechdDir}/modules";
#   speechd = pkgs.speechd.override { withPulse = true; withAlsa = true; };
#   ryan-model = pkgs.fetchzip {
#     url = "https://github.com/rhasspy/piper/releases/download/v0.0.2/voice-en-us-ryan-high.tar.gz";
#     stripRoot=false;
#     sha256 = "sha256-BbAoryDFYD95DK7PactjeQkhLTbhEmnHfbZJRaZ2EBk=";
#   };
#   mimicEnv = ".local/share/mimic/.env";
#   mimic-dispatch = pkgs.writeScriptBin "mimic-dispatch" ''
#     #!${pkgs.bash}/bin/bash
#     source ${config.home.homeDirectory}/${mimicEnv}
#     tee /tmp/last-mimic-dispatch | ${pkgs.docker}/bin/docker exec -i mimic3 run-venv mimic3 --remote --interactive --voice "$VOICE" --length-scale "$SCALE" --play-program "pw-play"
#   '';
#   tts-packages = with pkgs; [mimic-dispatch flite espeak-ng coreutils sox];
# in
# {
#     systemd.user.services.speech-dispatcher = {
#       Unit = {
#         Description = "speech-dispatcher";
#         After = [ "graphical-session-pre.target" ];
#         PartOf = [ "graphical-session.target" ];
#       };
#
#       Install = { WantedBy = [ "graphical-session.target" ]; };
#
#       Service = {
#         Environment = [
#           "HOME=${config.home.homeDirectory}"
#           "PATH=${lib.makeBinPath tts-packages}"
#         ];
#         Type="forking";
#         ExecStart = "${speechd}/bin/speech-dispatcher -d -t0 -C ${config.home.homeDirectory}/${speechdDir}";
#         ExecReload="kill -HUP $MAINPID";
#         Restart = "on-failure";
#       };
#     };
#
#     home.file = {
#       ${configFile}.text = ''
#         LogLevel 3
#         LogDir /tmp
#         # AddModule "piper" "sd_generic" "piper.conf"
#         # AddModule "mimic" "sd_generic" "mimic.conf"
#         # AddModule "espeak-ng" "sd_espeak-ng" "espeak-ng.conf"
#         # AddModule "dummy" "sd_dummy" ""
#         AddModule "flite" "sd_flite" ""
#
#         DefaultLanguage "en"
#         DefaultVoiceType "MALE1"
#         DefaultModule "flite"
#         AudioOutputMethod "libao"
#       '';
#
#       ".local/share/piper/models/ryan".source = ryan-model;
#
#       ${mimicEnv}.text = ''
#         export VOICE="en_UK/apope_low"
#         export SCALE="0.6"
#       '';
#
#       "${moduleDir}/mimic.conf".text = ''
#         # GenericRate is not working
#         GenericRateAdd 150
#         GenericRateMultiply 1
#         GenericExecuteSynth "printf %s \'$DATA\' | mimic-dispatch"
#         AddVoice "en" "MALE1" "mimic"
#       '';
#       "${moduleDir}/flite.conf".text = ''
#       '';
#     };
#
#     home.packages = [
#       speechd
#     ] ++ tts-packages;
# }
