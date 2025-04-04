#!/usr/bin/env python3
import sys
import hashlib
import datetime
import binascii
from cryptography import x509
from cryptography.x509.oid import NameOID
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from ecdsa import SigningKey, NIST256p
from ecdsa.der import encode_sequence, encode_integer
from asn1crypto import x509 as asn1_x509, algos, core

def create_deterministic_certificate(private_key):
    """Create a deterministic self-signed certificate with RFC 6979 compliant signature."""
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
    
    # Get TBS bytes
    temp_cert = builder.sign(private_key, hashes.SHA256())
    tbs_bytes = temp_cert.tbs_certificate_bytes
    
    # Extract private key value for deterministic signing
    private_numbers = private_key.private_numbers()
    private_value = private_numbers.private_value.to_bytes(32, 'big')
    
    # Create deterministic signature using the ecdsa library (RFC 6979 compliant)
    sk = SigningKey.from_string(private_value, curve=NIST256p, hashfunc=hashlib.sha256)
    digest = hashlib.sha256(tbs_bytes).digest()
    signature = sk.sign_deterministic(
        digest, 
        sigencode=lambda r, s, order: encode_sequence(encode_integer(r), encode_integer(s))
    )
    
    # Construct certificate with asn1crypto for full control over the structure
    cert = asn1_x509.Certificate()
    cert['tbs_certificate'] = asn1_x509.TbsCertificate.load(tbs_bytes)
    cert['signature_algorithm'] = algos.SignedDigestAlgorithm({
        'algorithm': '1.2.840.10045.4.3.2',  # OID for ecdsa-with-SHA256
        'parameters': core.Null()
    })
    cert['signature_value'] = signature
    
    # Serialize to PEM
    cert_der = cert.dump()
    cert_pem = b"-----BEGIN CERTIFICATE-----\n" + \
               binascii.b2a_base64(cert_der, newline=False) + \
               b"\n-----END CERTIFICATE-----\n"
    
    return cert_pem

if __name__ == "__main__":
    try:
        # Read PEM private key from stdin
        input_data = sys.stdin.buffer.read()
        private_key = serialization.load_pem_private_key(input_data, password=None)
        
        # Ensure it's an EC key
        if not isinstance(private_key, ec.EllipticCurvePrivateKey):
            raise ValueError("Input is not an EC private key")
            
        # Create certificate
        cert_pem = create_deterministic_certificate(private_key)
        
        # Output certificate
        sys.stdout.buffer.write(cert_pem)
    except Exception as e:
        sys.stderr.write(f"Error: {str(e)}\n")
        sys.exit(1)
