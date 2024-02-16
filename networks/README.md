# Networks

## Certificate Authority

```bash
openssl genrsa -out ca.key 4096
openssl req -new -x509 -nodes -extensions v3_ca -days 25568 -subj "/CN=Suderman CA" -key ca.key -out ca.crt
```

[Download](https://github.com/suderman/nixos/raw/main/networks/ca.crt)

