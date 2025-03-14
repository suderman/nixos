source $LIB; cd $PRJ_ROOT

ip="''${1-}"
empty "$ip" && error "Missing destination IP address"
hasnt secrets/key.age && error "$(pwd)/secrets/key.age missing"
hasnt /tmp/id_age && error "Age identity locked"

cat secrets/key.age \
  | rage -di /tmp/id_age \
  | derive hex "$(ls hosts | smenu)" \
  | derive ssh \
  | nc -N $ip 12345
