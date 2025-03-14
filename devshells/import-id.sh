source $LIB; cd $PRJ_ROOT

if has secrets/id.age; then
  [[ ! -s secrets/id.age ]] && rm -f secrets/id.age \
    || error "$(pwd)/secrets/id.age already exists"
fi

# Attempt to read QR code master key (hex32)
key="$(qr)"
defined "$key" && info "QR code scanned!" \
  || error "Failed to read QR code"

# Write a password-protected copy of the age identity
echo "$key" \
  | derive age \
  | rage -ep > secrets/id.age
info "Private age identity written: $(pwd)/secrets/id.age"

# Write the age identity's public key
echo "$key" \
  | derive age \
  | derive public \
  > secrets/id.pub
info "Public age identity written: $(pwd)/secrets/id.pub"
git add secrets/id.pub

# Write the encrypted master key (protected by age identity)
echo "$key" \
  | rage -eR secrets/id.pub \
  > secrets/key.age
info "Private master key written: $(pwd)/secrets/key.age"
git add secrets/key.age

# Unlock the id right away
echo "$key" | derive age | unlock-id
