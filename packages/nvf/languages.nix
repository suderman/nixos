{ ... }: { 

  vim.languages = {
    enableFormat = true; 
    enableTreesitter = true;
    enableExtraDiagnostics = true;

    nix = {
      enable = true;
      format.enable = true;
      format.type = "alejandra"; # nixfmt
    };
    markdown.enable = true;

    bash.enable = true;
    clang.enable = true;
    # css.enable = true;
    html.enable = true;
    sql.enable = true;
    java.enable = false;
    kotlin.enable = false;
    # ts.enable = true;
    go.enable = true;
    lua.enable = true;
    zig.enable = false;
    python.enable = true;
    typst.enable = false;
    rust = {
      enable = true;
      crates.enable = true;
    };

    assembly.enable = false;
    astro.enable = false;
    nu.enable = false;
    csharp.enable = false;
    julia.enable = false;
    vala.enable = false;
    scala.enable = false;
    r.enable = false;
    gleam.enable = false;
    dart.enable = false;
    ocaml.enable = false;
    elixir.enable = false;
    haskell.enable = false;
    ruby.enable = true;
    fsharp.enable = false;

    tailwind.enable = true;
    # svelte.enable = true;

    php = {
      enable = true;
      lsp.enable = true;
      treesitter.enable = true;
    };
    # python = {
    #   enable = true;
    #   lsp.enable = true;
    #   format.enable = true;
    #   format.type = "ruff";
    #   treesitter.enable = true;
    # };
  };

}
