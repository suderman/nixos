#!/usr/bin/env python3

import sys
import base64
import hashlib
import binascii


def parse_input(input_data, salt=None):
    """
    Parse input data, supporting multiple formats:
    - Base64 encoded string
    - Hex encoded string
    - Raw bytes/string

    Optionally mix with salt to create a derivative key.
    If input is exactly 32 bytes and no salt is provided, return it unchanged.

    Returns 32-byte key
    """
    try:
        # Try base64 decoding first
        try:
            data_bytes = base64.b64decode(input_data)
            if len(data_bytes) == 32 and salt is None:
                return data_bytes
        except:
            pass

        # Try hex decoding
        try:
            data_bytes = binascii.unhexlify(input_data)
            if len(data_bytes) == 32 and salt is None:
                return data_bytes
        except:
            pass

        # Try direct string to bytes (UTF-8)
        data_bytes = input_data.encode("utf-8")

        # Special case: If input is exactly 32 bytes and no salt, return unchanged
        if len(data_bytes) == 32 and salt is None:
            return data_bytes

        # If salt is provided, mix it with the input
        if salt:
            salt_bytes = salt.encode("utf-8")
            # Create a combined input for hashing
            mixed_input = data_bytes + b":" + salt_bytes
            # Always hash when salt is provided for consistent derivation
            result_bytes = hashlib.sha256(mixed_input).digest()
        # If input without salt is not exactly 32 bytes, hash to get 32 bytes
        elif len(data_bytes) != 32:
            result_bytes = hashlib.sha256(data_bytes).digest()
        else:
            result_bytes = data_bytes

        return result_bytes[:32]

    except Exception as e:
        raise ValueError(f"Could not parse input data: {e}")


def main():
    try:
        # Get salt from first command line argument if provided
        salt = sys.argv[1] if len(sys.argv) > 1 else None

        # Read input from standard input
        input_data = sys.stdin.read().strip()

        if not input_data:
            print("Error: No input data provided on standard input", file=sys.stderr)
            sys.exit(1)

        # Parse input with flexible input and optional salt
        key_bytes = parse_input(input_data, salt)

        # Output the key in hex format
        print(binascii.hexlify(key_bytes).decode("utf-8"), end="")

    except ValueError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
