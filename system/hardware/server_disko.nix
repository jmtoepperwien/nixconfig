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
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  "/rootfs" = {
                    mountpoint = "/";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  "/var/lib" = {
                    mountpoint = "/var/lib";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  "/var/log" = {
                    mountpoint = "/var/log";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  "/var/cache" = {
                    mountpoint = "/var/cache";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  "/home" = {
                    mountpoint = "/home";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                };
              };
            };
          };
        };
      };
      storage_0 = {
        device = "/dev/vdb";
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
        device = "/dev/vdc";
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
      zstorage = {
        type = "zpool";
        #rootFsOptions = {
        #  acltype = "posixacl";
        #  xattr = "sa";
        #  atime = "off";
        #  compression = "lz4";
        #};
        options.ashift = "12";
        options.cachefile = "none";
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
            #mountpoint = "/mnt/media";
            options = {
              canmount = "on";
              mountpoint = "/mnt/media";
            };
          };
          "git" = {
            type = "zfs_fs";
            #mountpoint = "/mnt/git";
            options = {
              canmount = "on";
              mountpoint = "/mnt/git";
            };
          };
          "cloud" = {
            type = "zfs_fs";
            #mountpoint = "/mnt/cloud";
            options = {
              canmount = "on";
              mountpoint = "/mnt/cloud";
            };
          };
        };
      };
    };
  };
  systemd.tmpfiles.rules = [
    "d /mnt 0755 root root"
    "d /mnt/media 0755 root"
    "d /mnt/git 0755 root"
    "d /mnt/cloud 0755 root"
  ];
}
