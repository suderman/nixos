# Networks

These are the networks I frequent. `home` and `work` both have a router I've configured to use a dedicated IP range, and the IP addresses on `tail` are copied from my Tailscale's dashboard. 

- [`home`](https://github.com/suderman/nixos/tree/main/networks/home) `10.1.x.x`   
- [`work`](https://github.com/suderman/nixos/tree/main/networks/work) `10.2.x.x`  
- [`tail`](https://github.com/suderman/nixos/tree/main/networks/tail) `100.x.x.x`  

## Certificate Authority

The [CA certificate](https://github.com/suderman/nixos/raw/main/networks/ca.crt) and [key](https://github.com/suderman/nixos/blob/main/secrets/files/ca-key.age) included in this repo were created with the following commands:

```bash
openssl genrsa -out ca.key 4096
openssl req -new -x509 -nodes -extensions v3_ca -days 25568 -subj "/CN=Suderman CA" -key ca.key -out ca.crt
```

The CA won't expire in my lifetime, so installing it on each device is a one-time chore. Traefik uses this CA to generate brand new certificates used for internal services during each deploy. 

### Installation Instructions for each Operation System

If a `caPort` is provided to a server's [Traefik module](https://github.com/suderman/nixos/blob/main/modules/traefik/ca.nix), the [ca.crt](https://github.com/suderman/nixos/raw/main/networks/ca.crt) file can be downloaded on that port. 

For example, my [hub](https://github.com/suderman/nixos/tree/main/configurations/hub) configuration on my home network has a IP of `10.1.0.4` and has `caPort` set to `1234`:  

```nix
modules.traefik = {
  enable = true;
  caPort = 1234;
};
```

This means devices on my home network can download the CA certificate via `http://10.1.0.4:1234`.

#### GrapheneOS (Android)

- Open Firefox and download the `crt` file via the URL above
- Settings > Security > More security settings > Encryption & credentials > Install a certificate > CA certificate

#### iOS

- Open Safari and download the `crt` file via the URL above
- Settings > General > Downloaded Profile > Install
- Settings > General > About > Certificate Trust Settings > Enable

#### tvOS

- Settings > General > Privacy & Security > Share Apple TV Analytics (hit the `PLAY` button) > Add Profile
- Settings > General > About > Certificate Trust Settings > Enable

#### macOS (High Sierra)

- Open Firefox and download the `crt` file via the URL above
- Keychain Access > System
- Drag `crt` file into the Keychain Access window and double-click certificate
- Trust > When using this certificate > Always Trust




