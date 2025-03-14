source $LIB; cd $PRJ_ROOT

id="$(input)"
if empty "$id"; then
  hasnt secrets/id.age && error "$(pwd)/secrets/id.age missing"
  id="$(cat secrets/id.age | rage -d)"
  empty "$id" && error "Failed to unlock age identity"
fi

has /tmp/id_age && mv /tmp/id_age /tmp/id_age_prev
touch /tmp/id_age_prev
echo "$id" > /tmp/id_age
chmod 600 /tmp/id_age /tmp/id_age_prev

info "Age identity unlocked"
