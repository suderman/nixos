if $(pidof -q rofi >/dev/null); then 
  kill $(pidof -s rofi)
else
  if [[ -n "${@-}" ]]; then
    # keyd bind super.j=down super.k=up super.h=left super.l=right
    # keyd bind super.enter=enter super.space=space
    rofi "${@}"
  fi
fi
