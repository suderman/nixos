# Super-Tab - start script
hyprctl clients -j | jq -r 'sort_by(.focusHistoryID) | .[] | .address'
