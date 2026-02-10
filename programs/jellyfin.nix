{
  config,
  lib,
  ...
}:

{
  services.jellyfin = {
    enable = true;
  };
  # Set this to limit ram usage, see https://github.com/jellyfin/jellyfin/issues/6306#issuecomment-1774093928
  systemd.services.jellyfin.environment."MALLOC_TRIM_THRESHOLD_" = "100000";

  users.users.jellyfin.extraGroups = [ "media" ];

  services.jellyseerr = {
    enable = true;
  };
}
