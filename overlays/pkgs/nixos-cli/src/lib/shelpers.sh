info() { 
  echo "$(green_bold "#") $(green $*)" 
}

warn() { 
  echo "$(red_bold "#") $(red $*)" 
}

cmd() { 
  local command execute
  case "$1" in
    "--dry-run" | "-d" )
      command="${@:2}"
      ;;
    *)  
      command="${@}"
      execute="1"
      ;;
  esac
  echo "$(magenta_bold ">") $(magenta ${command//\%/%%})";
  [ -z "$execute" ] || $command > /tmp/cmd
}

url() { 
  echo $1 | wl-copy; xdg-open $1
  echo "$(magenta_bold ">") $(cyan_underlined $1)"
}

ask() { 
  local tone question answer
  case "$1" in
    "--warn" | "-w" )
      question="${@:2}"
      tone="warn"
      ;;
    "--info" | "-i" )
      question="${@:2}"
      ;;
    *)  
      question="${@}"
      ;;
  esac

  if [[ "$answer" == "y" ]]; then 
    return 0
  fi

  if [ "$tone" = "warn" ]; then
    echo -n "$(red_bold "#") $(red $question)" 
  else
    echo -n "$(green_bold "#") $(green $question)" 
  fi

  read -p " $(blue_bold y)/[$(red_bold n)] " -n 1 -r
  echo

  [[ $REPLY =~ ^[Yy]$ ]]

  if [ ! $? -ne 0 ]; then 
    return 0
  else 
    return 1
  fi
}

pause() {
  echo -n "$(green_bold "#") $(green "Press") $(blue_bold "y") $(green "to continue:") " 
  local continue=""
  while [[ "$continue" != "y" ]]; do 
    read -n 1 continue; 
  done
  echo
}
