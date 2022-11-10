{
  additions = final: prev: import ./additions { pkgs = final; };
  modifications = final: prev: import ./modifications { inherit final prev; };
}
