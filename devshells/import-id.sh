source $LIB; cd $PRJ_ROOT

pause "Derive Seeds (BIP-85) > 32-bytes hex > Index Number $DERIVATION_INDEX"

if has secrets/id.age; then
  [[ ! -s secrets/id.age ]] && rm -f secrets/id.age \
    || error "./secrets/id.age already exists"
fi

# Attempt to read QR code master key (hex32)
hex="$(qr)"
defined "$hex" && info "QR code scanned!" \
  || error "Failed to read QR code"

# Write a password-protected copy of the age identity
echo "$hex" \
  | derive age \
  | rage -ep > secrets/id.age
info "Private age identity written: ./secrets/id.age"

# Write the age identity's public key
echo "$hex" \
  | derive age \
  | derive public \
  > secrets/id.pub
info "Public age identity written: ./secrets/id.pub"
git add secrets/id.pub

# Write the encrypted master key (protected by age identity)
echo "$hex" \
  | rage -eR secrets/id.pub \
  > secrets/hex.age
info "Private master key written: ./secrets/hex.age"
git add secrets/hex.age

# Unlock the id right away
echo "$hex" | derive age | unlock-id
