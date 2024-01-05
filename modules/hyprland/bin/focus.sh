hyprctl clients | grep class:.foot \
 && echo hyprctl keyword workspace $( hyprctl clients | grep class..foot -B4 && wlrctl window focus foot )
 || foot -L

