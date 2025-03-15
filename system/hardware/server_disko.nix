# USAGE in your configuration.nix.
# Update devices to match your hardware.
# {
#  imports = [ ./disko-config.nix ];
#  disko.devices.disk.main.device = "/dev/sda";
# }
{
  disko.devices = {
    disk = {
      main = {
        device = "/dev/vda";
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
            root = {
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
        device = "/dev/vdb";
        type = "disk";
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
      storage_1 = {
        device = "/dev/vdc";
        type = "disk";
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
    zpool = {
      zroot = {
        type = "zpool";
        rootFsOptions = {
          mountpoint = "none";
          acltype = "posixacl";
          xattr = "sa";
          compression = "lz4";
        };
        options.ashift = 12;
        datasets = {
          "root" = {
            type = "zfs_fs";
            mountpoint = "/";
          };
          "root/nix" = {
            type = "zfs_fs";
            options.mountpoint = "/nix";
            mountpoint = "/nix";
          };
          "root/swap" = {
            type = "zfs_volume";
            size = "16GiB";
            content = {
              type = "swap";
            };
            options = {
              volblocksize = "4096";
              compression = "zle";
              logbias = "throughput";
              sync = "always";
              primarycache = "metadata";
              secondarycache = "none";
              "com.sun:auto-snapshot" = "false";
            };
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
        }
        options.ashift = 12;

        mode = {
          topology = {
            type = "topology";
            vdev = [
              {
                mode = "mirror";
                members = [
                  "storage_0"
                  "storage_1"
                ];
              }
            ];
          };
        };

        datasets = {
          "media" = {
            type = "zfs_fs";
            options.mountpoint = "/mnt/media";
            mountpoint = "/mnt/media";
          };
          "git" = {
            type = "zfs_fs";
            options.mountpoint = "/mnt/git";
            mountpoint = "/mnt/git";
          };
          "cloud" = {
            type = "zfs_fs";
            options.mountpoint = "/mnt/cloud";
            mountpoint = "/mnt/cloud";
          };
        };
      };
    };
  };
}
