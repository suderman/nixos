source $LIB; cd $PRJ_ROOT

id="$(input)"
if [[ -z "$id" ]]; then
  [[ ! -f id.age ]] && error "./id.age missing"
  id="$(cat id.age | age -d)"
  [[ -z "$id" ]] && error "Failed to unlock age identity"
fi

[[ -f /tmp/id_age ]] && mv /tmp/id_age /tmp/id_age_
touch /tmp/id_age_
echo "$id" > /tmp/id_age
chmod 600 /tmp/id_age /tmp/id_age_

info "Age identity unlocked"
