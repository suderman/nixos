source $LIB; cd $PRJ_ROOT

if has id.age; then
  [[ ! -s id.age ]] && rm -f id.age || error "$(pwd)/id.age already exists"
fi

seed="$(qr)"
empty "$seed" && error "Failed to read QR code"

echo "$seed" | to-age | rage -ep > id.age
info "QR code imported as encrypted age identity: $(pwd)/id.age"

echo "$seed" | rage -er "$(echo "$seed" | to-age | to-public)" > seed.age
git add seed.age
info "QR code imported as encrypted seed: $(pwd)/seed.age"

echo "$seed" | to-age | unlock-id
