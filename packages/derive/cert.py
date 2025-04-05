#!/usr/bin/env python3
import sys
import hashlib
import datetime
import binascii
import argparse
from cryptography import x509
from cryptography.x509.oid import NameOID, ExtendedKeyUsageOID
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from ecdsa import SigningKey, NIST256p
from ecdsa.der import encode_sequence, encode_integer
from asn1crypto import x509 as asn1_x509, algos, core

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
    if isinstance(ca_key, ec.EllipticCurvePrivateKey):
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
    
    # Use first 20 bytes (160 bits) for serial number
    # This avoids negative serial numbers and keeps a good size
    serial = int.from_bytes(hash_digest[:20], byteorder='big')
    return serial

def create_ca_certificate(private_key):
    """Create a deterministic self-signed CA certificate."""
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
    
    return create_deterministic_signature(builder, private_key)

def create_server_certificate(subject_key, ca_cert, ca_key, common_name):
    """Create a deterministic server certificate signed by the CA."""
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
    
    return create_deterministic_signature(builder, ca_key)

def create_deterministic_signature(builder, signing_key):
    """Create a certificate with deterministic signature using RFC 6979."""
    # Get TBS bytes
    temp_cert = builder.sign(signing_key, hashes.SHA256())
    tbs_bytes = temp_cert.tbs_certificate_bytes
    
    # Extract private key value for deterministic signing
    private_numbers = signing_key.private_numbers()
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
    
    # Fix the warning by using a SignedDigestAlgorithm structure without Null parameters
    cert['signature_algorithm'] = algos.SignedDigestAlgorithm({
        'algorithm': '1.2.840.10045.4.3.2',  # OID for ecdsa-with-SHA256
    })
    cert['signature_value'] = signature
    
    # Serialize to PEM
    cert_der = cert.dump()
    cert_pem = b"-----BEGIN CERTIFICATE-----\n" + \
               binascii.b2a_base64(cert_der, newline=False) + \
               b"\n-----END CERTIFICATE-----\n"
    
    return cert_pem

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Create a deterministic certificate from an EC private key')
    parser.add_argument('--cacert', help='Path to CA certificate file (.pem)')
    parser.add_argument('--cakey', help='Path to CA private key file (.pem)')
    parser.add_argument('--name', help='Common name for the server certificate (formerly --common-name)')
    
    args = parser.parse_args()
    
    try:
        # Read private key from stdin
        input_data = sys.stdin.buffer.read()
        private_key = serialization.load_pem_private_key(input_data, password=None)
        
        # Ensure it's an EC key
        if not isinstance(private_key, ec.EllipticCurvePrivateKey):
            raise ValueError("Input is not an EC private key")
        
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




# #!/usr/bin/env python3
# import sys
# import hashlib
# import datetime
# import binascii
# from cryptography import x509
# from cryptography.x509.oid import NameOID
# from cryptography.hazmat.primitives import hashes, serialization
# from cryptography.hazmat.primitives.asymmetric import ec
# from ecdsa import SigningKey, NIST256p
# from ecdsa.der import encode_sequence, encode_integer
# from asn1crypto import x509 as asn1_x509, algos, core
#
# def create_deterministic_certificate(private_key):
#     """Create a deterministic self-signed certificate with RFC 6979 compliant signature."""
#     # Fixed certificate parameters
#     name = x509.Name([
#         x509.NameAttribute(NameOID.COUNTRY_NAME, u"CA"),
#         x509.NameAttribute(NameOID.STATE_OR_PROVINCE_NAME, u"Alberta"),
#         x509.NameAttribute(NameOID.ORGANIZATION_NAME, u"Suderman CA"),
#         x509.NameAttribute(NameOID.COMMON_NAME, u"Suderman CA"),
#     ])
#     not_valid_before = datetime.datetime(2025, 1, 1, 0, 0, 0)
#     not_valid_after = datetime.datetime(2075, 1, 1, 0, 0, 0)
#     
#     # Build certificate
#     builder = x509.CertificateBuilder()
#     builder = builder.subject_name(name)
#     builder = builder.issuer_name(name)
#     builder = builder.not_valid_before(not_valid_before)
#     builder = builder.not_valid_after(not_valid_after)
#     builder = builder.serial_number(1)
#     builder = builder.public_key(private_key.public_key())
#     
#     # Add extensions
#     builder = builder.add_extension(
#         x509.BasicConstraints(ca=True, path_length=None),
#         critical=True
#     )
#     builder = builder.add_extension(
#         x509.KeyUsage(
#             digital_signature=False,
#             content_commitment=False,
#             key_encipherment=False,
#             data_encipherment=False,
#             key_agreement=False,
#             key_cert_sign=True,
#             crl_sign=True,
#             encipher_only=False,
#             decipher_only=False
#         ),
#         critical=True
#     )
#     
#     # Add subject and authority key identifiers
#     ski = x509.SubjectKeyIdentifier.from_public_key(private_key.public_key())
#     builder = builder.add_extension(ski, critical=False)
#     builder = builder.add_extension(
#         x509.AuthorityKeyIdentifier.from_issuer_public_key(private_key.public_key()),
#         critical=False
#     )
#     
#     # Get TBS bytes
#     temp_cert = builder.sign(private_key, hashes.SHA256())
#     tbs_bytes = temp_cert.tbs_certificate_bytes
#     
#     # Extract private key value for deterministic signing
#     private_numbers = private_key.private_numbers()
#     private_value = private_numbers.private_value.to_bytes(32, 'big')
#     
#     # Create deterministic signature using the ecdsa library (RFC 6979 compliant)
#     sk = SigningKey.from_string(private_value, curve=NIST256p, hashfunc=hashlib.sha256)
#     digest = hashlib.sha256(tbs_bytes).digest()
#     signature = sk.sign_deterministic(
#         digest, 
#         sigencode=lambda r, s, order: encode_sequence(encode_integer(r), encode_integer(s))
#     )
#     
#     # Construct certificate with asn1crypto for full control over the structure
#     cert = asn1_x509.Certificate()
#     cert['tbs_certificate'] = asn1_x509.TbsCertificate.load(tbs_bytes)
#     cert['signature_algorithm'] = algos.SignedDigestAlgorithm({
#         'algorithm': '1.2.840.10045.4.3.2',  # OID for ecdsa-with-SHA256
#         'parameters': core.Null()
#     })
#     cert['signature_value'] = signature
#     
#     # Serialize to PEM
#     cert_der = cert.dump()
#     cert_pem = b"-----BEGIN CERTIFICATE-----\n" + \
#                binascii.b2a_base64(cert_der, newline=False) + \
#                b"\n-----END CERTIFICATE-----\n"
#     
#     return cert_pem
#
# if __name__ == "__main__":
#     try:
#         # Read PEM private key from stdin
#         input_data = sys.stdin.buffer.read()
#         private_key = serialization.load_pem_private_key(input_data, password=None)
#         
#         # Ensure it's an EC key
#         if not isinstance(private_key, ec.EllipticCurvePrivateKey):
#             raise ValueError("Input is not an EC private key")
#             
#         # Create certificate
#         cert_pem = create_deterministic_certificate(private_key)
#         
#         # Output certificate
#         sys.stdout.buffer.write(cert_pem)
#     except Exception as e:
#         sys.stderr.write(f"Error: {str(e)}\n")
#         sys.exit(1)
