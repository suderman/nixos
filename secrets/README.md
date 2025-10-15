# NixOS & Home Manager secrets

Sensitive files are age-encrypted using
[agenix](https://github.com/ryantm/agenix) (extended by
[agenix-rekey](https://github.com/oddlama/agenix-rekey)) and decrypted using SSH
ed25519 host keys and age identities deterministically derived from a provided
32-byte hex. This hex is derived from a set of BIP-39 seed words using
[BIP-85](https://coldcard.com/docs/bip85/) and a derivation index number. In
this way, one can recover access to secrets and bootstrap a host on this flake
with seed words safely stored offline.

## Secret generation

This flake extends the agenix CLI with
[additional commands](https://github.com/suderman/nixos/tree/main/packages/agenix)
to work with this flake. Additionally, this flake's
[default package](https://github.com/suderman/nixos/tree/main/packages/nixos)
offers a `nixos generate` command to generate derived keys and missing files.

These include:

- Derived SSH public key per host
- Derived SSH public keys per user
- Derived public age identity per user
- RSA Certificate Authority key & certificate
- Rekeyed secrets via agenix

## CLI usage

To add or edit a secret:

```sh
agenix edit modules/home/users/jon/my-secret.age
```

To rekey (do this after adding, removing or changing access to a secret):

```sh
agenix rekey -a
```

To recover this flake's age identity:

```sh
agenix import
```

The QR code for index `1` can be found following this path on the COLDCARD Q:

`Advanced/Tools` > `Derive Seeds (BIP-85)` > `32-bytes hex` > `Index Number 1` >

To unlock and relock the age identity:

```sh
agenix unlock
agenix lock
```
