#!/usr/bin/env python3
import sys
import hashlib
import datetime
import argparse
from cryptography import x509
from cryptography.x509.oid import NameOID, ExtendedKeyUsageOID
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ed25519

def load_ca_cert_and_key(ca_cert_path, ca_key_path):
    """Load CA certificate and key from files."""
    with open(ca_cert_path, 'rb') as f:
        ca_cert_data = f.read()
        ca_cert = x509.load_pem_x509_certificate(ca_cert_data)
    
    with open(ca_key_path, 'rb') as f:
        ca_key_data = f.read()
        ca_key = serialization.load_pem_private_key(ca_key_data, password=None)
    
    return ca_cert, ca_key

def generate_deterministic_serial(ca_key, common_name):
    """Generate a deterministic serial number from CA key and domain name."""
    # Extract CA key info
    if isinstance(ca_key, ed25519.Ed25519PrivateKey):
        public_bytes = ca_key.public_key().public_bytes(
            encoding=serialization.Encoding.DER,
            format=serialization.PublicFormat.SubjectPublicKeyInfo
        )
    else:
        # Handle other key types if needed
        public_bytes = b"unsupported_key_type"
    
    # Create stable input for hash
    input_data = public_bytes + common_name.encode('utf-8')
    hash_digest = hashlib.sha256(input_data).digest()
    
    # Use first 19 bytes (152 bits) for serial number
    serial = int.from_bytes(hash_digest[:19], byteorder='big')
    return serial

def create_ca_certificate(private_key):
    """Create a self-signed CA certificate."""
    # Fixed certificate parameters
    name = x509.Name([
        x509.NameAttribute(NameOID.COUNTRY_NAME, u"CA"),
        x509.NameAttribute(NameOID.STATE_OR_PROVINCE_NAME, u"Alberta"),
        x509.NameAttribute(NameOID.ORGANIZATION_NAME, u"Suderman CA"),
        x509.NameAttribute(NameOID.COMMON_NAME, u"Suderman CA"),
    ])
    not_valid_before = datetime.datetime(2025, 1, 1, 0, 0, 0)
    not_valid_after = datetime.datetime(2075, 1, 1, 0, 0, 0)
    
    # Build certificate
    builder = x509.CertificateBuilder()
    builder = builder.subject_name(name)
    builder = builder.issuer_name(name)
    builder = builder.not_valid_before(not_valid_before)
    builder = builder.not_valid_after(not_valid_after)
    builder = builder.serial_number(1)
    builder = builder.public_key(private_key.public_key())
    
    # Add extensions
    builder = builder.add_extension(
        x509.BasicConstraints(ca=True, path_length=None),
        critical=True
    )
    builder = builder.add_extension(
        x509.KeyUsage(
            digital_signature=False,
            content_commitment=False,
            key_encipherment=False,
            data_encipherment=False,
            key_agreement=False,
            key_cert_sign=True,
            crl_sign=True,
            encipher_only=False,
            decipher_only=False
        ),
        critical=True
    )
    
    # Add subject and authority key identifiers
    ski = x509.SubjectKeyIdentifier.from_public_key(private_key.public_key())
    builder = builder.add_extension(ski, critical=False)
    builder = builder.add_extension(
        x509.AuthorityKeyIdentifier.from_issuer_public_key(private_key.public_key()),
        critical=False
    )
    
    # Sign the certificate - Ed25519 is inherently deterministic
    certificate = builder.sign(
        private_key=private_key,
        algorithm=None,  # Ed25519 doesn't use a separate hash algorithm
    )
    
    # Serialize to PEM
    return certificate.public_bytes(serialization.Encoding.PEM)

def create_server_certificate(subject_key, ca_cert, ca_key, common_name):
    """Create a server certificate signed by the CA."""
    # Generate subject name
    subject_name = x509.Name([
        x509.NameAttribute(NameOID.COUNTRY_NAME, u"CA"),
        x509.NameAttribute(NameOID.STATE_OR_PROVINCE_NAME, u"Alberta"),
        x509.NameAttribute(NameOID.ORGANIZATION_NAME, u"Suderman Services"),
        x509.NameAttribute(NameOID.COMMON_NAME, common_name),
    ])
    
    # Get issuer name from CA cert
    issuer_name = ca_cert.subject
    
    # Generate deterministic serial number
    serial = generate_deterministic_serial(ca_key, common_name)
    
    # Get current year for certificate validity
    current_year = datetime.datetime.now().year
    
    # Validity period (2 years from January 1 of current year)
    not_valid_before = datetime.datetime(current_year, 1, 1, 0, 0, 0)
    not_valid_after = datetime.datetime(current_year + 2, 1, 1, 0, 0, 0)
    
    # Build certificate
    builder = x509.CertificateBuilder()
    builder = builder.subject_name(subject_name)
    builder = builder.issuer_name(issuer_name)
    builder = builder.not_valid_before(not_valid_before)
    builder = builder.not_valid_after(not_valid_after)
    builder = builder.serial_number(serial)
    builder = builder.public_key(subject_key.public_key())
    
    # Add extensions
    builder = builder.add_extension(
        x509.BasicConstraints(ca=False, path_length=None),
        critical=True
    )
    
    builder = builder.add_extension(
        x509.KeyUsage(
            digital_signature=True,
            content_commitment=True,
            key_encipherment=True,
            data_encipherment=False,
            key_agreement=False,
            key_cert_sign=False,
            crl_sign=False,
            encipher_only=False,
            decipher_only=False
        ),
        critical=True
    )
    
    # Add extended key usage for server authentication
    builder = builder.add_extension(
        x509.ExtendedKeyUsage([
            ExtendedKeyUsageOID.SERVER_AUTH,
            ExtendedKeyUsageOID.CLIENT_AUTH
        ]),
        critical=False
    )
    
    # Add subject alternative names (domain and wildcard)
    builder = builder.add_extension(
        x509.SubjectAlternativeName([
            x509.DNSName(common_name),
            x509.DNSName(f"*.{common_name}")
        ]),
        critical=False
    )
    
    # Add subject key identifier
    builder = builder.add_extension(
        x509.SubjectKeyIdentifier.from_public_key(subject_key.public_key()),
        critical=False
    )
    
    # Add authority key identifier
    builder = builder.add_extension(
        x509.AuthorityKeyIdentifier.from_issuer_public_key(ca_key.public_key()),
        critical=False
    )
    
    # Sign the certificate - Ed25519 is inherently deterministic
    certificate = builder.sign(
        private_key=ca_key,
        algorithm=None,  # Ed25519 doesn't use a separate hash algorithm
    )
    
    # Serialize to PEM
    return certificate.public_bytes(serialization.Encoding.PEM)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Create a certificate from an Ed25519 private key')
    parser.add_argument('--cacert', help='Path to CA certificate file (.pem)')
    parser.add_argument('--cakey', help='Path to CA private key file (.pem)')
    parser.add_argument('--name', help='Common name for the server certificate (formerly --common-name)')
    
    args = parser.parse_args()
    
    try:
        # Read private key from stdin
        input_data = sys.stdin.buffer.read()
        private_key = serialization.load_pem_private_key(input_data, password=None)
        
        # Ensure it's an Ed25519 key
        if not isinstance(private_key, ed25519.Ed25519PrivateKey):
            raise ValueError("Input is not an Ed25519 private key")
        
        # Determine which type of certificate to create
        if args.cacert and args.cakey and args.name:
            # Create server certificate
            ca_cert, ca_key = load_ca_cert_and_key(args.cacert, args.cakey)
            cert_pem = create_server_certificate(private_key, ca_cert, ca_key, args.name)
        else:
            # Create CA certificate
            cert_pem = create_ca_certificate(private_key)
        
        # Output certificate
        sys.stdout.buffer.write(cert_pem)
    except Exception as e:
        sys.stderr.write(f"Error: {str(e)}\n")
        sys.exit(1)
