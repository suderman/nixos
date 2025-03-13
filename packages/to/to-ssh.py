#!/usr/bin/env python3

import sys
import base64
import hashlib
import binascii
import cryptography.hazmat.primitives.asymmetric.ed25519 as crypto_ed25519
import cryptography.hazmat.primitives.serialization as serialization

def parse_seed(seed_input):
    """
    Parse seed input, supporting multiple formats:
    - Base64 encoded string
    - Hex encoded string
    - Raw bytes/string
    
    Returns 32-byte seed
    """
    try:
        # Try base64 decoding first
        try:
            seed_bytes = base64.b64decode(seed_input)
            if len(seed_bytes) == 32:
                return seed_bytes
        except:
            pass

        # Try hex decoding
        try:
            seed_bytes = binascii.unhexlify(seed_input)
            if len(seed_bytes) == 32:
                return seed_bytes
        except:
            pass

        # Try direct string to bytes (UTF-8)
        seed_bytes = seed_input.encode('utf-8')
        
        # If input is not exactly 32 bytes, hash to get 32 bytes
        if len(seed_bytes) != 32:
            seed_bytes = hashlib.sha256(seed_bytes).digest()
        
        return seed_bytes[:32]

    except Exception as e:
        raise ValueError(f"Could not parse seed: {e}")

def generate_deterministic_keypair(seed):
    """
    Generate a deterministic ED25519 key pair from a 32-byte seed.
    
    Args:
        seed (bytes): 32-byte seed for key generation
    
    Returns:
        private_key: Ed25519 private key
    """
    # Ensure seed is exactly 32 bytes
    if len(seed) != 32:
        raise ValueError("Seed must be exactly 32 bytes long")
    
    # Generate private key from seed using cryptography library
    private_key = crypto_ed25519.Ed25519PrivateKey.from_private_bytes(seed)
    
    return private_key

def format_ssh_private_key(private_key):
    """
    Format private key in OpenSSH format.
    
    Args:
        private_key: Cryptography Ed25519 private key
    
    Returns:
        str: Formatted SSH private key
    """
    # Serialize to OpenSSH format
    pem_private = private_key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.OpenSSH,
        encryption_algorithm=serialization.NoEncryption()
    )
    
    return pem_private.decode('utf-8')

def main():
    try:
        # Read seed from standard input
        seed_input = sys.stdin.read().strip()
        
        if not seed_input:
            print("Error: No seed provided on standard input", file=sys.stderr)
            sys.exit(1)
        
        # Parse seed with flexible input
        seed_bytes = parse_seed(seed_input)
        
        # Generate deterministic key pair
        private_key = generate_deterministic_keypair(seed_bytes)
        
        # Output private key to stdout
        formatted_key = format_ssh_private_key(private_key)
        print(formatted_key, end='')
    
    except ValueError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
