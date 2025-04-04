#!/usr/bin/env python3
import sys
import binascii
import hashlib
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import ec

def create_private_key_from_seed(seed_bytes):
    """Create an EC private key from a 32-byte seed."""
    private_key = ec.derive_private_key(
        int.from_bytes(seed_bytes, byteorder="big"),
        ec.SECP256R1()
    )
    return private_key

if __name__ == "__main__":
    try:
        # Read hex from stdin
        input_data = sys.stdin.buffer.read()
        input_str = input_data.decode('utf-8', errors='ignore').strip()
        
        # Handle input as hex or hash it
        if len(input_str) == 64 and all(c in "0123456789abcdefABCDEF" for c in input_str):
            seed_bytes = binascii.unhexlify(input_str)
        else:
            seed_bytes = hashlib.sha256(input_data).digest()
        
        # Create and serialize the key
        private_key = create_private_key_from_seed(seed_bytes)
        pem_data = private_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.PKCS8,
            encryption_algorithm=serialization.NoEncryption()
        )
        
        # Output PEM
        sys.stdout.buffer.write(pem_data)
    except Exception as e:
        sys.stderr.write(f"Error: {str(e)}\n")
        sys.exit(1)
