# Networking

These are the network zones I frequent. `home` and `work` both have a router
I've configured to use a dedicated IP range, and the IP addresses on `tail` are
copied from my Tailscale's dashboard.

- [`home`](https://github.com/suderman/nixos/tree/main/zones/home) `10.1.x.x`
- [`work`](https://github.com/suderman/nixos/tree/main/zones/work) `10.2.x.x`
- [`tail`](https://github.com/suderman/nixos/tree/main/zones/tail) `100.x.x.x`

## Certificate Authority

The [CA certificate](https://github.com/suderman/nixos/raw/main/zones/ca.crt)
and [key](https://github.com/suderman/nixos/raw/main/zones/ca.age) included in
this repo were created with the following commands:

```bash
openssl genrsa -out ca.key 4096
cat >ca.conf <<'EOF'
[ req ]
distinguished_name = req_distinguished_name
x509_extensions = v3_ca
prompt = no

[ req_distinguished_name ]
CN = Suderman CA

[ v3_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, keyCertSign, cRLSign
EOF

openssl req -new -x509 -nodes -config ca.conf -extensions v3_ca -days 25568 -key ca.key -out ca.crt
age -e -r $(derive public </tmp/id_age) <ca.key >ca.age
rm ca.key ca.conf
```

The explicit OpenSSL config matters here: some stricter TLS clients reject a CA
certificate that does not declare certificate-signing usage.

The CA won't expire in my lifetime, so installing it on each device is a
one-time chore. Traefik uses this CA to generate brand new certificates used for
internal services during each deploy.

### Installation Instructions for each Operation System

If a `caPort` is provided to a server's
[Traefik module](https://github.com/suderman/nixos/tree/main/modules/nixos/default/options/traefik),
the [ca.crt](https://github.com/suderman/nixos/raw/main/networks/ca.crt) file
can be downloaded on that port.

For example, my
[hub](ttps://github.com/suderman/nixos/tree/main/hosts/hub)
configuration on my home network has a IP of `10.1.0.4` and has `caPort` set to
`1234`:

```nix
services.traefik = {
  enable = true;
  caPort = 1234;
};
```

This means devices on my home network can download the CA certificate via
`http://10.1.0.4:1234`.

#### GrapheneOS (Android)

- Open Firefox and download the `crt` file via the URL above
- Settings > Security > More security settings > Encryption & credentials >
  Install a certificate > CA certificate

#### iOS

- Open Safari and download the `crt` file via the URL above
- Settings > General > Downloaded Profile > Install
- Settings > General > About > Certificate Trust Settings > Enable

#### tvOS

- Settings > General > Privacy & Security > Share Apple TV Analytics (hit the
  `PLAY` button) > Add Profile
- Settings > General > About > Certificate Trust Settings > Enable

#### macOS (High Sierra)

- Open Firefox and download the `crt` file via the URL above
- Keychain Access > System
- Drag `crt` file into the Keychain Access window and double-click certificate
- Trust > When using this certificate > Always Trust
