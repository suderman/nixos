source $LIB; cd $PRJ_ROOT

# Confirm derivation path
pause "Derive Seeds (BIP-85) > 32-bytes hex > Index Number $DERIVATION_INDEX"

if [[ -f id.age ]]; then
  [[ ! -s id.age ]] && 
    rm -f id.age || 
    error "./id.age already exists"
fi

# Attempt to read QR code master key (hex32)
hex="$(qr)"
[[ ! -z "$hex" ]] && 
  info "QR code scanned!" || 
  error "Failed to read QR code"

# Write a password-protected copy of the age identity
echo "$hex" | 
  derive age | 
  rage -ep > id.age
info "Private age identity written: ./id.age"

# Write the age identity's public key
echo "$hex" | 
  derive age | 
  derive public > id.pub
git add id.pub 2>/dev/null || true
info "Public age identity written: ./id.pub"

# Write the 32-byte hex (protected by age identity)
echo "$hex" | 
  rage -eR id.pub > hex.age
git add hex.age 2>/dev/null || true
info "Private 32-byte hex written: ./hex.age"

# Unlock the id right away
echo "$hex" | derive age | unlock-id
