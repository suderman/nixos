source $LIB; cd $PRJ_ROOT

ip="''${1-}"
empty "$ip" && error "Missing destination IP address"
hasnt seed.age && error "$(pwd)/seed.age missing"
hasnt /tmp/id_age && error "Age identity locked"

cat seed.age | rage -di /tmp/id_age | derive hex "$(ls hosts | smenu)" | derive ssh | nc -N $ip 12345
