{ perSystem, pkgs, ... }: let

  # Python with required packages
  pythonWithPackages = pkgs.python3.withPackages (ps: [
    ps.cryptography
  ]);

  # Convert generated ssh keys to age identity
  ssh-to-age = pkgs.lib.getExe pkgs.ssh-to-age;

# Python script for deterministic key generation
in pkgs.stdenv.mkDerivation {
  pname = "deterministic-keygen";
  version = "0.1.0";

  src = ./.;

  buildInputs = [ pythonWithPackages ];

  installPhase = ''
    mkdir -p $out/bin
    cp ${./deterministic-keygen.py} $out/bin/deterministic-keygen.py
    chmod +x $out/bin/deterministic-keygen.py

    # Create wrapper script
    cat > $out/bin/deterministic-keygen << EOF
    #!${pkgs.bash}/bin/bash
    ${pythonWithPackages}/bin/python3 $out/bin/deterministic-keygen.py "\$@"

    # Also generate age identity from this ssh key pair
    if [[ -e id_ed25519 ]] && [[ -e id_ed25519.pub ]]; then
      echo "# imported from: \$(cat id_ed25519.pub)" > id_age
      echo "# public key: \$(${ssh-to-age} -i id_ed25519.pub)" >> id_age
      ${ssh-to-age} -private-key -i id_ed25519 >> id_age
      ${ssh-to-age} -i id_ed25519.pub > id_age.pub
      echo "Identity written to id_age and id_age.pub"
    fi

    EOF
    chmod +x $out/bin/deterministic-keygen
  '';
}
