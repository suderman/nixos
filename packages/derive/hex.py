#!/usr/bin/env python3
"""
Parse input data into a 32-byte key, optionally mixing in a salt.

Supported input formats:
- Base64 string
- Hex string
- Raw text

If salt is provided, the input is salted and hashed.
If input is exactly 32 bytes and no salt is provided, it is returned unchanged.
"""

from __future__ import annotations

import sys
import base64
import hashlib
import binascii


def parse_input(input_data: str, salt: str | None = None) -> bytes:
    """
    Parse input into a 32-byte key.

    Args:
        input_data: Input string (Base64, hex, or raw text).
        salt: Optional salt to mix in before hashing.

    Returns:
        32-byte key.

    Raises:
        ValueError: If the input cannot be parsed.
    """
    try:
        # Base64 decode
        try:
            data_bytes = base64.b64decode(input_data, validate=True)
            if len(data_bytes) == 32 and salt is None:
                return data_bytes
        except (binascii.Error, ValueError):
            pass

        # Hex decode
        try:
            data_bytes = binascii.unhexlify(input_data)
            if len(data_bytes) == 32 and salt is None:
                return data_bytes
        except (binascii.Error, ValueError):
            pass

        # UTF-8 encode
        data_bytes = input_data.encode("utf-8")

        # If exactly 32 bytes and no salt → return directly
        if len(data_bytes) == 32 and salt is None:
            return data_bytes

        if salt is not None:
            salt_bytes = salt.encode("utf-8")
            mixed_input = data_bytes + b":" + salt_bytes
            result_bytes = hashlib.sha256(mixed_input).digest()
        elif len(data_bytes) != 32:
            result_bytes = hashlib.sha256(data_bytes).digest()
        else:
            result_bytes = data_bytes

        return result_bytes[:32]

    except Exception as err:
        raise ValueError(f"Could not parse input data: {err}") from err


def main() -> None:
    """Read stdin and optional salt from argv, output derived 32-byte key as hex."""
    salt = sys.argv[1] if len(sys.argv) > 1 else None
    input_data = sys.stdin.read().strip()

    if not input_data:
        print("Error: No input data provided on standard input", file=sys.stderr)
        sys.exit(1)

    try:
        key_bytes = parse_input(input_data, salt)
        print(binascii.hexlify(key_bytes).decode("utf-8"), end="")
    except ValueError as err:
        print(f"Error: {err}", file=sys.stderr)
        sys.exit(1)
    except Exception as err:
        print(f"Unexpected error: {err}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
