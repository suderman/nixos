#!/usr/bin/env python3
"""
Generate a deterministic ED25519 SSH private key from a provided seed.

The seed may be provided as:
- Base64 string
- Hex string
- Raw string/bytes
- Any other string (will be SHA-256 hashed to 32 bytes)
"""

from __future__ import annotations

import sys
import base64
import hashlib
import binascii

from cryptography.hazmat.primitives.asymmetric import ed25519 as crypto_ed25519
from cryptography.hazmat.primitives import serialization


def parse_seed(seed_input: str) -> bytes:
    """
    Parse seed input and normalize to 32 bytes.

    Args:
        seed_input: Seed string (Base64, hex, or raw text).

    Returns:
        A 32-byte seed.

    Raises:
        ValueError: If input cannot be parsed into a valid seed.
    """
    # Try Base64
    try:
        seed_bytes = base64.b64decode(seed_input, validate=True)
        if len(seed_bytes) == 32:
            return seed_bytes
    except (binascii.Error, ValueError):
        pass

    # Try Hex
    try:
        seed_bytes = binascii.unhexlify(seed_input)
        if len(seed_bytes) == 32:
            return seed_bytes
    except (binascii.Error, ValueError):
        pass

    # Raw UTF-8
    seed_bytes = seed_input.encode("utf-8")

    # If not exactly 32 bytes, hash to 32 bytes
    if len(seed_bytes) != 32:
        seed_bytes = hashlib.sha256(seed_bytes).digest()

    return seed_bytes[:32]


def generate_deterministic_keypair(seed: bytes) -> crypto_ed25519.Ed25519PrivateKey:
    """
    Generate a deterministic ED25519 private key from a 32-byte seed.

    Args:
        seed: 32-byte seed.

    Returns:
        An Ed25519PrivateKey instance.

    Raises:
        ValueError: If the seed is not 32 bytes.
    """
    if len(seed) != 32:
        raise ValueError("Seed must be exactly 32 bytes long")
    return crypto_ed25519.Ed25519PrivateKey.from_private_bytes(seed)


def format_ssh_private_key(private_key: crypto_ed25519.Ed25519PrivateKey) -> str:
    """
    Format the private key in OpenSSH format.

    Args:
        private_key: Ed25519 private key.

    Returns:
        String containing the OpenSSH private key.
    """
    pem_private = private_key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.OpenSSH,
        encryption_algorithm=serialization.NoEncryption(),
    )
    return pem_private.decode("utf-8")


def main() -> None:
    """
    Main entry point: read seed from stdin, generate key, output to stdout.
    """
    seed_input = sys.stdin.read().strip()
    if not seed_input:
        print("Error: No seed provided on standard input", file=sys.stderr)
        sys.exit(1)

    try:
        seed_bytes = parse_seed(seed_input)
        private_key = generate_deterministic_keypair(seed_bytes)
        formatted_key = format_ssh_private_key(private_key)
        print(formatted_key, end="")
    except ValueError as err:
        print(f"Error: {err}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
