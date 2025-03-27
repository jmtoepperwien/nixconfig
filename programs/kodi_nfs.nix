{
  config,
  lib,
  pkgs,
  ...
}:

{
  fileSystems."/export/movies" = {
    device = "${config.server.media_folder}/movies";
    options = [ "bind" ];
  };
  fileSystems."/export/series" = {
    device = "${config.server.media_folder}/series";
    options = [ "bind" ];
  };
  fileSystems."/export/books" = {
    device = "${config.server.media_folder}/books";
    options = [ "bind" ];
  };
  fileSystems."/export/music" = {
    device = "${config.server.media_folder}/music";
    options = [ "bind" ];
  };

  services.nfs.server.enable = true;
  services.nfs.server.exports = ''
    /export/series  192.168.1.244(ro,async,insecure,all_squash,anongid=988,fsid=10)
    /export/movies  192.168.1.244(ro,async,insecure,all_squash,anongid=988,fsid=11)
    /export/books  192.168.1.244(ro,async,insecure,all_squash,anongid=988,fsid=12)
    /export/music  192.168.1.244(ro,async,insecure,all_squash,anongid=988,fsid=13)
    /export/series  192.168.1.149(ro,async,insecure,all_squash,anongid=988,fsid=10)
    /export/movies  192.168.1.149(ro,async,insecure,all_squash,anongid=988,fsid=11)
    /export/books  192.168.1.149(ro,async,insecure,all_squash,anongid=988,fsid=12)
    /export/music  192.168.1.149(ro,async,insecure,all_squash,anongid=988,fsid=13)
  '';

  networking.firewall.allowedTCPPorts = [ 2049 ];
}
