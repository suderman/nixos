{ config, pkgs, ... }: let

  # OBS, MPV, HandBrake, Davinci Resolve, etc
  FFmpeg = with pkgs; [
    ffmpeg-full       # Full FFmpeg build with codec support
    libvpx            # VP8/VP9 video codec
    x264 x265         # H.264 / H.265 encoding
    dav1d             # Fast AV1 decoder
    lame              # MP3 encoding
    flac              # FLAC audio codec
  ];

  # GNOME media players, PipeWire, etc
  GStreamer = with pkgs.gst_all_1; [
    gst-libav         # FFmpeg-based codecs (H.264, AAC, MP3, etc.)
    gst-plugins-good  # Commonly used codecs (FLAC, VP8, WebM, Matroska, etc.)
    gst-plugins-bad   # Additional formats (DTS, WebRTC, etc.)
    gst-plugins-ugly  # Proprietary codecs (MP3, MPEG-2, DVD playback, etc.)
  ];

in {
  environment.systemPackages = FFmpeg ++ GStreamer;
}
