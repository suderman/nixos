# Wrapper script for zbarcam to convert QR codes into 32-byte hex
{ pkgs, perSystem, ... }: perSystem.self.mkScript {

  path = [ 
    pkgs.v4l-utils
    pkgs.zbar
    perSystem.self.derive
  ];

  name = "qr";

  text = ''
    # Disable webcam autofocus
    autofocus="$(v4l2-ctl --get-ctrl=focus_automatic_continuous 2>/dev/null | cut -d' ' -f2 || echo "")"
    [[ -z "$autofocus" ]] || v4l2-ctl --set-ctrl=focus_automatic_continuous=0

    # Set webcam focus level to 200 (0 = furthest back, 250 = closest possible)
    focus="$(v4l2-ctl --get-ctrl=focus_absolute 2>/dev/null | cut -d' ' -f2 || echo "")"
    [[ -z "$focus" ]] || v4l2-ctl --set-ctrl=focus_absolute=200

    # Scan QR code from webcam
    qr="$(zbarcam --oneshot --raw --set "*.enable=0" --set "qrcode.enable=1" && echo "")"

    # Reset webcam settings to what they were before
    [[ -z "$focus" ]] || v4l2-ctl --set-ctrl=focus_absolute=$focus
    [[ -z "$autofocus" ]] || v4l2-ctl --set-ctrl=focus_automatic_continuous=$autofocus

    # Output QR code as 32-byte hex
    [[ -z "$qr" ]] || echo "$qr" | derive hex
  '';

}
