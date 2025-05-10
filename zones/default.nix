{ 
  # Self-signed CA certificate
  ca = ./ca.pem;

  # Assume any subdomains are part of this internal network
  domainName = "suderman.org";
}
