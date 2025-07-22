# Exit if standard input is missing
[[ -z "$input" ]] && exit 0

# If age identity detected, extract recipient from secret and output
if [[ ! -z "$(echo "$input" | grep "AGE-SECRET-KEY")" ]]; then
  echo "$input" | age-keygen -y

# If ssh ed25519 detected, extract public key from secret and output
elif [[ ! -z "$(echo "$input" | grep "OPENSSH PRIVATE KEY")" ]]; then
  echo $(ssh-keygen -y -f <(echo "$input") | cut -d ' ' -f 1,2) ${comment-}

# If ed25519 key detected, extract private key from secret and output
elif [[ ! -z "$(echo "$input" | grep "BEGIN PRIVATE KEY")" ]]; then
  openssl ec -in <(echo "$input") -pubout 2>/dev/null

# If certificate detected, extract private key from secret and output
elif [[ ! -z "$(echo "$input" | grep "BEGIN CERTIFICATE")" ]]; then
  openssl x509 -in <(echo "$input") -pubkey -noout 2>/dev/null

# Fallback on echoing the input to output
else
  echo "$input"
fi
