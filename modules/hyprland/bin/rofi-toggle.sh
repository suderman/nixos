if $(pidof -q rofi >/dev/null); then 
  kill $(pidof -s rofi)
else
  keyd bind super.j=down super.k=up
  rofi "${@-}"
fi
