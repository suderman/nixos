{
  flake,
  pkgs,
  inputs,
  perSystem,
  ...
}: let
  inherit (inputs.nixpkgs) lib;
  inherit (lib) hasPrefix match stringLength;
  inherit (lib.generators) mkLuaInline;
  inherit (inputs.nvf.lib.nvim.lua) toLuaObject;

  # extend flake lib
  extend.lib = rec {
    inherit mkLuaInline toLuaObject;

    # function name and options argument
    mkLuaCallback = name: options:
    # lua
    ''
      function()
        ${name}(${toLuaObject options})
      end
    '';

    # Build keymap attr and detect if action is lua
    keyMap = mode: key: action: desc: {
      inherit mode key action desc;
      noremap = true;
      silent = true;
      lua =
        if hasPrefix "function(" action
        then true
        else if match "^[A-Z]" action != null
        then true
        else
          !(hasPrefix ":" action
            || hasPrefix "<" action
            || stringLength action < 10);
    };

    # Shortcuts to each mode
    imap = key: action: desc: keyMap "i" key action desc;
    nmap = key: action: desc: keyMap "n" key action desc;
    tmap = key: action: desc: keyMap "t" key action desc;
    vmap = key: action: desc: keyMap "v" key action desc;
  };

  basic = [
    {
      vim.viAlias = true;
      vim.vimAlias = true;
      vim.enableLuaLoader = true;
      vim.globals.mapleader = " "; # use space as leader key
      vim.globals.maplocalleader = ","; # use comma as local leader key
      vim.options.mouse = "nvi"; # normal, visual, insert, commandline, help, all, r
    }
  ];

  local = [
    {
      vim.luaConfigRC.local =
        # lua
        ''
          -- Expands to full path
          local dir = vim.fn.expand("~/.config/nvf/lua/local")
          local file = dir .. "/init.lua"

          -- Create directory & file if it doesn't exist
          if vim.fn.filereadable(file) == 0 then
            vim.fn.system({ "mkdir", "-p", dir })
            vim.fn.system({ "touch", file })

          -- Otherwise, require the package
          else
            require("local")
          end
        '';
    }
  ];
in
  (inputs.nvf.lib.neovimConfiguration {
    inherit pkgs;
    extraSpecialArgs = {
      inherit perSystem;
      flake = lib.recursiveUpdate flake extend;
    };
    modules = basic ++ (flake.lib.ls ./.) ++ local;
  }).neovim
