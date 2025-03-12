source $LIB; cd $PRJ_ROOT

hasnt seed.age && error "$(pwd)/seed.age missing"
hasnt /tmp/id_age && error "Age identity locked"

for host in $(ls hosts); do
  echo "$(cat seed.age | rage -di /tmp/id_age | to-hex "$host" | to-ssh | to-public) @$host" > hosts/$host/ssh.pub
  git add hosts/$host/ssh.pub
  info "Public ssh host key generated: $(pwd)/hosts/$host/ssh.pub"
done
