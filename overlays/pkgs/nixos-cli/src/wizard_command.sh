echo "# this file is located in 'src/wizard_command.sh'"
echo "# code for 'nixos wizard' goes here"
echo "# you can edit it freely and regenerate (it will not be overwritten)"
inspect_args

info "Choose your disk"
local disk="refresh"; while [[ "$disk" = "refresh" ]]; do
  disk="$(ask_disk)"
done
task -d $disk

info "What's it gonna be?"
val=$(ask ready set go)
echo $val
info "What is your name?"
name="$(ask)"
echo $name
# pause
# pause "Again people"
if confirm --warn Scary?; then
  echo "You think scary"
else
  echo "You dunna want it"
fi


echo $(choose "do re mi")
echo "one two three" | ask "What it gonna be"
info "What is your name?"
name="$(ask)"
echo $name
warn "Well? What it gunna be?"
# if choose
#   echo you agreed
# else
#   echo you did not agree
# fi
pause "Hold it!"
