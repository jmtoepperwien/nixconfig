{
  config,
  ...
}:

{
  disko.devices = {
    disk = {
      main = {
        device = "/dev/nvme0n1"; # not important after setting up
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zroot";
              };
            };
          };
        };
      };
      storage_0 = {
        device = "/dev/sdd"; # not important after setting up
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zstorage";
              };
            };
          };
        };
      };
      storage_1 = {
        device = "/dev/sdf"; # not important after setting up
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zstorage";
              };
            };
          };
        };
      };
      storage10_0 = {
        device = "/dev/sdc"; # not important after setting up
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zstorage";
              };
            };
          };
        };
      };
      storage10_1 = {
        device = "/dev/sde"; # not important after setting up
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zstorage";
              };
            };
          };
        };
      };
      storage4_0 = {
        device = "/dev/sda"; # not important after setting up
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zstorage";
              };
            };
          };
        };
      };
      storage4_1 = {
        device = "/dev/sdb"; # not important after setting up
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zstorage";
              };
            };
          };
        };
      };

    };
    zpool = {
      zroot = {
        type = "zpool";
        rootFsOptions = {
          acltype = "posixacl";
          xattr = "sa";
          atime = "off";
          compression = "lz4";
        };
        options.ashift = "12";
        mode = {
          topology = {
            type = "topology";
            vdev = [
              {
                members = [
                  "main"
                ];
              }
            ];
          };
        };
        datasets = {
          "root" = {
            type = "zfs_fs";
            mountpoint = "/";
            options = {
              canmount = "on";
              mountpoint = "legacy";
            };
          };
          "nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options = {
              canmount = "on";
              mountpoint = "legacy";
            };
          };
          "swap" = {
            type = "zfs_volume";
            size = "1GiB";
            content = {
              type = "swap";
            };
            options = {
              compression = "zle";
              logbias = "throughput";
              sync = "always";
              primarycache = "metadata";
              secondarycache = "none";
              "com.sun:auto-snapshot" = "false";
            };
          };
          "home" = {
            type = "zfs_fs";
            mountpoint = "/home";
            options.mountpoint = "legacy";
          };
          "var/lib" = {
            type = "zfs_fs";
            mountpoint = "/var/lib";
            options.mountpoint = "legacy";
          };
          "var/log" = {
            type = "zfs_fs";
            mountpoint = "/var/log";
            options.mountpoint = "legacy";
          };
          "var/cache" = {
            type = "zfs_fs";
            mountpoint = "/var/cache";
            options.mountpoint = "legacy";
          };
          "tmp" = {
            type = "zfs_fs";
            mountpoint = "/tmp";
            options.mountpoint = "legacy";
          };
          "snapshots" = {
            type = "zfs_fs";
            mountpoint = "/snapshots";
            options.mountpoint = "legacy";
          };
        };
      };
      zstorage = {
        type = "zpool";
        rootFsOptions = {
          acltype = "posixacl";
          xattr = "sa";
          atime = "off";
          compression = "lz4";
        };
        options.ashift = "12";
        mode = {
          topology = {
            type = "topology";
            vdev = [
              {
                mode = "mirror";
                members = [
                  "storage18_0"
                  "storage18_1"
                ];
              }
              {
                mode = "mirror";
                members = [
                  "storage10_0"
                  "storage10_1"
                ];
              }
              {
                mode = "mirror";
                members = [
                  "storage4_0"
                  "storage4_1"
                ];
              }
            ];
          };
        };

        datasets = {
          "media" = {
            type = "zfs_fs";
            mountpoint = config.server.media_folder;
            options = {
              canmount = "on";
              mountpoint = "legacy";
            };
          };
          "git" = {
            type = "zfs_fs";
            mountpoint = config.server.git_folder;
            options = {
              canmount = "on";
              mountpoint = "legacy";
            };
          };
          "cloud" = {
            type = "zfs_fs";
            mountpoint = config.server.cloud_folder;
            options = {
              canmount = "on";
              mountpoint = "legacy";
            };
          };
        };
      };
    };
  };
  systemd.tmpfiles.rules = [
    "d /mnt 0755 root root"
    "d /snapshots 0770 root root"
  ];
}
