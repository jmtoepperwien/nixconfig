{
  config,
  options,
  lib,
  ...
}:

{
  options.server = {
    media_folder = lib.mkOption {
      default = "/mnt/media";
    };
    git_folder = lib.mkOption {
      default = "/mnt/git";
    };
    cloud_folder = lib.mkOption {
      default = "/mnt/cloud";
    };
  };
}
