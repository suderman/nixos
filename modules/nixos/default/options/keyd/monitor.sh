#!/usr/bin/env bash
while read -r line; do

  this=/run/keyd/this
  last=/run/keyd/last
  touch $this $last

  button() {
    echo $1 >/run/keyd/button
    # ( sleep 1 && echo "" > /run/keyd/button ) &
  }

  key() {
    [[ "$1" == "$(cat $this)" ]] || cp -f $this $last
    echo "$1" >$this
  }

  if [[ "$line" == *"kpminus down"* ]]; then
    key kpminus
  elif [[ "$line" == *"kpplus down"* ]]; then
    key kpplus
  elif [[ "$line" == *"kp6 down"* ]]; then
    key kp6
  elif [[ "$line" == *"leftmouse down"* ]]; then
    key leftmouse
  elif [[ "$line" == *"middlemouse down"* ]]; then
    key middlemouse
  elif [[ "$line" == *"rightmouse down"* ]]; then
    key rightmouse
  fi

  case "$(cat $last) $(cat $this)" in
  *"middlemouse") button middle ;;
  "kp6 kpminus") button left ;;
  *"kp6"*) button right ;;
  *"rightmouse") button right ;;
  *"kpminus") button left ;;
  *"leftmouse") button left ;;
  esac

done < <(exec keyd -m)
