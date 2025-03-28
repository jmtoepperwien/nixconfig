{
  config,
  lib,
  pkgs,
  ...
}:

{
  systemd.tmpfiles.rules = [
    "d /mnt/lib0 0775 mtoepperwien media"
    "d /mnt/lib1 0775 mtoepperwien media"
    "d /mnt/kodi_lib 0775 mtoepperwien media"
  ];
  fileSystems."/mnt/lib0" = {
    device = "/dev/disk/by-uuid/af71a65d-c25d-40c8-98fa-792c61de0630";
    fsType = "btrfs";
    options = [
      "subvol=@"
      "defaults"
      "noatime"
    ];
  };
  fileSystems."/mnt/lib1" = {
    device = "/dev/disk/by-uuid/0dc95e30-d5bc-4385-b883-15ba5aaa172d";
    fsType = "btrfs";
    options = [
      "subvol=@"
      "defaults"
      "noatime"
    ];
  };
  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
  };

  systemd.services.mergerfskodilib = {
    after = [
      "mnt-lib0.mount"
      "mnt-lib1.mount"
    ];
    requires = [
      "mnt-lib0.mount"
      "mnt-lib1.mount"
    ];
    wantedBy = [ "local-fs.target" ];
    before = [
      "export-books.mount"
      "export-movies.mount"
      "export-series.mount"
      "export-music.mount"
    ];
    unitConfig.DefaultDependencies = "no";
    serviceConfig = {
      User = "root";
      Type = "oneshot";
      KillMode = "none";
      ExecStart = "${pkgs.mergerfs}/bin/mergerfs -o cache.files=partial,dropcacheonclose=true,category.create=mfs,category.search=newest /mnt/lib0:/mnt/lib1 /mnt/kodi_lib";
      Restart = "on-failure";
    };
  };

}
