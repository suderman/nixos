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
services.traefik = {
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


---

# Assuming you have your BIP85 seed as a hex string in a file called bip85seed.hex
# We'll use OpenSSL to convert this deterministically to a private key

# Create an EC parameters file for secp256r1
openssl ecparam -name prime256v1 -out secp256r1.pem

# Generate private key from your seed
# (You may need a small script to properly format your seed as input)
cat bip85seed.hex | xxd -r -p | openssl ec -inform DER -outform PEM -out ca_key.pem -param_enc explicit -paramfile secp256r1.pem

# Generate root CA
openssl req -new -x509 -days 3650 -key ca_key.pem -out ca_cert.pem -subj "/CN=My Root CA/O=My Organization/C=US" -addext "basicConstraints=critical,CA:TRUE" -addext "keyUsage=critical,keyCertSign,cRLSign"

# Verify
openssl x509 -in ca_cert.pem -text -noout

# Generate a CSR for a server certificate
openssl req -new -key server_key.pem -out server.csr -subj "/CN=example.com"

# Sign the CSR with your CA
openssl x509 -req -in server.csr -CA ca_cert.pem -CAkey ca_key.pem -CAcreateserial -out server_cert.pem -days 365











#!/usr/bin/env python3
import sys
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives import serialization
import binascii

# Read the hex seed from stdin
seed_hex = sys.stdin.read().strip()

# Convert hex to bytes
try:
    seed_bytes = binascii.unhexlify(seed_hex)
except binascii.Error:
    sys.stderr.write("Error: Invalid hex input\n")
    sys.exit(1)

# Ensure it is exactly 32 bytes for secp256r1
if len(seed_bytes) != 32:
    sys.stderr.write(f"Error: Seed must be exactly 32 bytes (got {len(seed_bytes)})\n")
    sys.exit(1)
    
# Create a private key directly from the raw bytes
private_key = ec.derive_private_key(
    int.from_bytes(seed_bytes, byteorder="big"),
    ec.SECP256R1()
)

# Generate the private key in PEM format
pem = private_key.private_bytes(
    encoding=serialization.Encoding.PEM,
    format=serialization.PrivateFormat.PKCS8,
    encryption_algorithm=serialization.NoEncryption()
)

# Output to stdout
sys.stdout.buffer.write(pem)







openssl req -new -x509 -key ca_key.pem -out ca_cert.pem \
  -subj "/CN=My Root CA/O=My Organization/C=US" \
  -addext "basicConstraints=critical,CA:TRUE" \
  -addext "keyUsage=critical,keyCertSign,cRLSign" \
  -set_serial 1 \
  -startdate 20240101000000Z \
  -enddate 20341231235959Z
