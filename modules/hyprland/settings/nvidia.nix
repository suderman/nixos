{ lib, ... }: let inherit (lib) mkDefault; in {

  env = [
    "LIBVA_DRIVER_NAME,nvidia"
    "XDG_SESSION_TYPE,wayland"
    "GBM_BACKEND,nvidia-drm"
    "__GLX_VENDOR_LIBRARY_NAME,nvidia"
  ];

# env = SDL_VIDEODRIVER,wayland
# env = WLR_NO_HARDWARE_CURSORS,1
# env = __NV_PRIME_RENDER_OFFLOAD,1
# env = __VK_LAYER_NV_optimus,NVIDIA_only
# env = NVD_BACKEND,direct
# env = __GL_GSYNC_ALLOWED,1
# env = __GL_VRR_ALLOWED,1
# env = WLR_DRM_NO_ATOMIC,1
# env = __GL_MaxFramesAllowed,1
# env = WLR_RENDERER_ALLOW_SOFTWARE,1
# env = XWAYLAND_NO_GLAMOR,1 # with this you'll need to use gamescope for gaming

}
