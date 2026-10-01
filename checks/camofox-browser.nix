{
  pkgs,
  perSystem,
  ...
}: let
  tlsFixture =
    pkgs.runCommand "camofox-test-certificates" {
      nativeBuildInputs = [pkgs.openssl];
    } ''
      mkdir -p "$out"
      # Disposable test keys, not production credentials.
      openssl req -x509 -newkey rsa:2048 -nodes -days 36500 \
        -subj '/CN=Camofox test CA' -addext 'basicConstraints=critical,CA:TRUE' \
        -keyout "$out/ca.key" -out "$out/ca.crt"
      openssl req -newkey rsa:2048 -nodes -subj '/CN=127.0.0.1' \
        -addext 'subjectAltName=IP:127.0.0.1' -keyout "$out/server.key" -out server.csr
      openssl x509 -req -in server.csr -CA "$out/ca.crt" -CAkey "$out/ca.key" \
        -CAcreateserial -days 36500 -copy_extensions copy -out "$out/server.crt"
      openssl req -x509 -newkey rsa:2048 -nodes -days 36500 -subj '/CN=Untrusted test CA' \
        -addext 'basicConstraints=critical,CA:TRUE' \
        -keyout untrusted-ca.key -out untrusted-ca.crt
      openssl x509 -req -in server.csr -CA untrusted-ca.crt -CAkey untrusted-ca.key \
        -CAcreateserial -days 36500 -copy_extensions copy -out "$out/untrusted.crt"
      cp "$out/server.key" "$out/untrusted.key"
    '';
  testPackage = perSystem.self.camofox-browser.override {
    trustedCertificates = ["${tlsFixture}/ca.crt"];
  };
in
  pkgs.runCommand "camofox-browser-check" {
    nativeBuildInputs = [pkgs.python3];
  } ''
    ${perSystem.self.camofox-browser.nodejs}/bin/node --max-old-space-size=64 \
      ${../packages/camofox-browser/test-gc.mjs} ${perSystem.self.camofox-browser}
    python3 ${../packages/camofox-browser/test.py} ${testPackage}/bin/camofox-browser ${tlsFixture}
    touch "$out"
  ''
