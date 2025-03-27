{
  config,
  options,
  lib,
  ...
}:

{
  options.server.media_folder = lib.mkOption {
    default = "/mnt/media";
  };
}
