# List directories and files that can be imported by nix
# ls ./modules;
# ls { path = ./modules; dirsWith = [ "default.nix" "configuration.nix" ]; filesExcept = [ "default.nix" ]; asPath = true; };
{lib, ...}: x: let
  inherit (builtins) attrNames concatMap elem filter isAttrs isPath pathExists readDir;
  inherit (lib) filterAttrs hasPrefix hasSuffix removeSuffix unique;

  # Return list of directory names (with default.nix) inside path
  dirNames = path: dirsWith: dirsExcept: asPath: let
    dirs = attrNames (filterAttrs (n: v: v == "directory") (readDir path));
    isAllowed = name: !elem name dirsExcept; # default filters out dirs named "user"
    isVisible = name: (!hasPrefix "." name);
    dirsWithFiles = dirs: concatMap (dir: concatMap (file: ["${dir}/${file}"]) dirsWith) dirs;
    isValid = dirFile: pathExists "${path}/${dirFile}";
    format = paths:
      map (dirFile: (
        if (asPath == true)
        then path + "/${dirFile}"
        else dirOf dirFile
      ))
      paths;
  in
    format (filter isValid (dirsWithFiles (filter isVisible (filter isAllowed dirs))));

  # Return list of filenames (ending in .nix) inside path
  fileNames = path: filesExcept: asPath: let
    files = attrNames (filterAttrs (n: v: v == "regular") (readDir path));
    isVisible = name: (!hasPrefix "." name);
    isNix = name: (hasSuffix ".nix" name);
    isAllowed = name: !elem name filesExcept;
    format = paths:
      map (file: (
        if (asPath == true)
        then path + "/${file}"
        else file
      ))
      paths;
  in
    format (filter isAllowed (filter isNix (filter isVisible files)));

  # Shortcut to pass path directly with default options
  fromPath = path: fromAttrs {inherit path;};

  # Return list of directory/file names if asPath is false, otherwise list of absolute paths
  fromAttrs = {
    path,
    dirsWith ? ["default.nix"],
    dirsExcept ? ["user"],
    filesExcept ? ["flake.nix" "default.nix" "configuration.nix" "home-configuration.nix"],
    asPath ? true,
  }:
    unique
    (
      if ! pathExists path
      then []
      else # If path doesn't exist, return an empty list
        (
          if hasSuffix ".nix" path
          then [path]
          else # If path is a nix file, return that path in a list
            (
              if dirsWith == false
              then []
              else (dirNames path dirsWith dirsExcept asPath)
            )
            ++ # No subdirs if dirsWith is false,
            (
              if filesExcept == false
              then []
              else (fileNames path filesExcept asPath)
            ) # No files if filesExcept is false
        )
    );
in
  if (isPath x)
  then (fromPath x)
  else if (isAttrs x)
  then (fromAttrs x)
  else []
