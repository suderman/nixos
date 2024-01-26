{ lib, writeTextFile, runtimeShell, adoptopenjdk-icedtea-web }: 

let 
  name = "isy";
  description = "ISY994i Admin Console";
  runtimeInputs = [ adoptopenjdk-icedtea-web ];
  text = ''
    javaws http://10.1.0.8/admin.jnlp
  '';
in 

writeTextFile {
  inherit name;
  executable = true;
  destination = "/bin/${name}";

  text = ''
    #!${runtimeShell}
  '' + lib.optionalString (runtimeInputs != [ ]) ''
    export PATH="${lib.makeBinPath runtimeInputs}:$PATH"
  '' + ''
    ${text}
  '';

  meta = with lib; {
    mainProgram = name;
    description = description;
    license = licenses.mit;
    platforms = platforms.all;
  };

}
