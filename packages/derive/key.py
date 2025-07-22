#!/usr/bin/env python3
import sys
import binascii
import hashlib
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import ed25519


def create_private_key_from_seed(seed_bytes):
    """Create an Ed25519 private key from a 32-byte seed."""
    # Ed25519 private key is directly constructed from 32 bytes
    private_key = ed25519.Ed25519PrivateKey.from_private_bytes(seed_bytes)
    return private_key


if __name__ == "__main__":
    try:
        # Read hex from stdin
        input_data = sys.stdin.buffer.read()
        input_str = input_data.decode("utf-8", errors="ignore").strip()

        # Handle input as hex or hash it
        if len(input_str) == 64 and all(
            c in "0123456789abcdefABCDEF" for c in input_str
        ):
            seed_bytes = binascii.unhexlify(input_str)
        else:
            seed_bytes = hashlib.sha256(input_data).digest()

        # Ensure seed is exactly 32 bytes
        if len(seed_bytes) != 32:
            raise ValueError("Seed must be exactly 32 bytes")

        # Create and serialize the key
        private_key = create_private_key_from_seed(seed_bytes)
        pem_data = private_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.PKCS8,
            encryption_algorithm=serialization.NoEncryption(),
        )

        # Output PEM
        sys.stdout.buffer.write(pem_data)
    except Exception as e:
        sys.stderr.write(f"Error: {str(e)}\n")
        sys.exit(1)
