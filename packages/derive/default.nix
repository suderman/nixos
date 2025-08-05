{
  pkgs,
  perSystem,
  ...
}:
perSystem.self.mkScript {
  name = "derive";
  path = [
    (pkgs.python3.withPackages (ps: [ps.cryptography]))
    pkgs.age
    pkgs.gnugrep
    pkgs.openssh
    pkgs.openssl
    pkgs.ssh-to-age
  ];

  # Paths to python scripts
  env = {
    path_to_cert_py = ./cert.py;
    path_to_hex_py = ./hex.py;
    path_to_key_py = ./key.py;
    path_to_ssh_py = ./ssh.py;
  };

  # Bash script
  text = builtins.readFile ./derive.sh;
}
