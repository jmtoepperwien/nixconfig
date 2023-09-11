{ config, lib, pkgs, ...}:

{
  fileSystems."/export/movies" = {
    device = "/mnt/lib0/movies";
    options = [ "bind" ];
  };
  fileSystems."/export/series" = {
    device = "/mnt/lib0/series";
    options = [ "bind" ];
  };
  fileSystems."/export/books" = {
    device = "/mnt/kodi_lib/books";
    options = [ "bind" ];
  };

  services.nfs.server.enable = true;
  services.nfs.server.exports = ''
    /export/series  192.168.1.244(rw,async,insecure,subtree_check,all_squash,anongid=988)
    /export/movies  192.168.1.244(rw,async,insecure,subtree_check,all_squash,anongid=988)
    /export/books  192.168.1.244(rw,async,insecure,subtree_check,all_squash,anongid=988)
    /export/series  192.168.1.149(rw,async,insecure,subtree_check,all_squash,anongid=988)
    /export/movies  192.168.1.149(rw,async,insecure,subtree_check,all_squash,anongid=988)
    /export/books  192.168.1.149(rw,async,insecure,subtree_check,all_squash,anongid=988)
  '';

  networking.firewall.allowedTCPPorts = [ 2049 ];
}
