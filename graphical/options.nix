{
  config,
  options,
  lib,
  ...
}:

{
  options.graphical = {
    swayOptions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };
}
