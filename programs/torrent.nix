{ config, lib, pkgs, agenix, ... }:

{
  imports = [ ./rutorrent_setup.nix ];
  users.groups."rtorrent" = {};
  users.users."rtorrent" = {
    isSystemUser = true;
    group = "rtorrent";
    extraGroups= [ "usenet" ];
  };

  environment.systemPackages = [ pkgs.flood ];

  services.rtorrent = {
    enable = true;
    user = "rtorrent";
    dataPermissions = "0775";
    downloadDir = "/mnt/kodi_lib/downloads_torrent";
    configText = ''
      dht.mode.set = auto
      protocol.pex.set = yes

      trackers.use_udp.set = yes

      system.umask.set = 0002
    '';
  };

  systemd.services."natpmp-proton" = {
    enable = true;
    description = "Acquire incoming port from protonvpn natpmp";
    requires = [ "protonvpn.service" ];
    bindsTo = [ "protonvpn.service" ];
    serviceConfig = {
      User = "root";
      NetworkNamespacePath = "/var/run/netns/vpn";
      # [TODO: not hardcoded gateway]
      ExecStart = pkgs.writers.writeBash "get-port-vpn" ''
        echo "getting udp"
        eval "${pkgs.libnatpmp}/bin/natpmpc -g 10.2.0.1 -a 0 0 udp 60 | ${pkgs.busybox}/bin/grep 'Mapped public port' | ${pkgs.busybox}/bin/sed -E 's/.*Mapped public port ([0-9]+) .*/UDPPORT=\1/' > /run/proton_incoming"
        echo "getting tcp"
        eval "${pkgs.libnatpmp}/bin/natpmpc -g 10.2.0.1 -a 0 0 tcp 60 | ${pkgs.busybox}/bin/grep 'Mapped public port' | ${pkgs.busybox}/bin/sed -E 's/.*Mapped public port ([0-9]+) .*/TCPPORT=\1/' >> /run/proton_incoming && chown rtorrent:rtorrent /run/proton_incoming"
        echo "looping to keep"
        while true ; do
          ${pkgs.libnatpmp}/bin/natpmpc -g 10.2.0.1 -a 0 0 udp 60 && ${pkgs.libnatpmp}/bin/natpmpc -g 10.2.0.1 -a 0 0 tcp 60
          sleep 45
        done
      '';
      Type = "simple";
      Restart = "always";
    };
  };

  systemd.services.rtorrent = let
    configFile = pkgs.writeText "rtorrent.rc" config.services.rtorrent.configText;
    rtorrentPackage = config.services.rtorrent.package;
  in {
    bindsTo = [ "netns@vpn.service" ];
    requires = [ "network-online.target" "protonvpn.service" "natpmp-proton.service" ];
    after = [ "protonvpn.service" "natpmp-proton.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      EnvironmentFile = "/run/proton_incoming";
      NetworkNamespacePath = "/var/run/netns/vpn";
      ExecStart = lib.mkForce (pkgs.writers.writeBash "start-rtorrent" ''
        echo "${rtorrentPackage}/bin/rtorrent -n -o system.daemon.set=true -o import=${configFile} -o network.port_range.set=$TCPPORT-$TCPPORT -o dht.port.set=$UDPPORT
"
        ${rtorrentPackage}/bin/rtorrent -n -o system.daemon.set=true -o import=${configFile} -o network.port_range.set=$TCPPORT-$TCPPORT -o dht.port.set=$UDPPORT
      '');
    };
  };

  systemd.services.rtorrent-setup = let
    rtorrentPackage = pkgs.callPackage ./rutorrent.nix {};
    rutorrentRoot = "/var/www/rutorrent";
    rutorrentConfig = pkgs.writeText "rutorrent-config.php" ''
      <?php
	// configuration parameters

	// for snoopy client
	@define('HTTP_USER_AGENT', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36', true);
	@define('HTTP_TIME_OUT', 30, true);	// in seconds
	@define('HTTP_USE_GZIP', true, true);
	$httpIP = null;				// IP string. Or null for any.
	$httpProxy = array
	(
		'use' 	=> false,
		'proto'	=> 'http',		// 'http' or 'https'
		'host'	=> 'PROXY_HOST_HERE',
		'port'	=> 3128
	);

	@define('RPC_TIME_OUT', 5, true);	// in seconds

	@define('LOG_RPC_CALLS', false, true);
	@define('LOG_RPC_FAULTS', true, true);

	// for php
	@define('PHP_USE_GZIP', false, true);
	@define('PHP_GZIP_LEVEL', 2, true);

	$schedule_rand = 10;			// rand for schedulers start, +0..X seconds

	$do_diagnostic = true;
	$log_file = '/tmp/errors.log';		// path to log file (comment or leave blank to disable logging)

	$saveUploadedTorrents = true;		// Save uploaded torrents to profile/torrents directory or not
	$overwriteUploadedTorrents = false;     // Overwrite existing uploaded torrents in profile/torrents directory or make unique name

	$topDirectory = '/';			// Upper available directory. Absolute path with trail slash.
	$forbidUserSettings = false;

	$scgi_port = 0;
	$scgi_host = "unix:///run/rtorrent/rpc.sock";

	// For web->rtorrent link through unix domain socket 
	// (scgi_local in rtorrent conf file), change variables 
	// above to something like this:
	//
	// $scgi_port = 0;
	// $scgi_host = "unix:///tmp/rpc.socket";

	$XMLRPCMountPoint = "/RPC2";		// DO NOT DELETE THIS LINE!!! DO NOT COMMENT THIS LINE!!!

        $pathToExternals = array(
                  "php" 	=> "${pkgs.php}/bin/php",			// Something like /usr/bin/php. If empty, will be found in PATH.
                  "curl"	=> "${pkgs.curl}/bin/curl",			// Something like /usr/bin/curl. If empty, will be found in PATH.
                  "gzip"	=> "${pkgs.gzip}/bin/gzip",			// Something like /usr/bin/gzip. If empty, will be found in PATH.
                  "id"	=> "${pkgs.coreutils}/bin/id",			// Something like /usr/bin/id. If empty, will be found in PATH.
                  "stat"	=> "${pkgs.coreutils}/bin/stat",			// Something like /usr/bin/stat. If empty, will be found in PATH.
                  "pgrep" => "${pkgs.procps}/bin/pgrep",  // TODO why can't we use phpEnv.PATH
                );

	$localhosts = array( 			// list of local interfaces
		"127.0.0.1",
		"localhost",
	);

	$profilePath = '../share';		// Path to user profiles
	$profileMask = 0777;			// Mask for files and directory creation in user profiles.
						// Both Webserver and rtorrent users must have read-write access to it.
						// For example, if Webserver and rtorrent users are in the same group then the value may be 0770.

	$tempDirectory = null;			// Temp directory. Absolute path with trail slash. If null, then autodetect will be used.

	$canUseXSendFile = false;		// If true then use X-Sendfile feature if it exist

	$locale = "UTF8";

    '';
  in {
    enable = true;
    wantedBy = [ "multi-user.target" ];
    after = [ "rtorrent.service" ];
    script = ''
      #mkdir -p ${rutorrentRoot}
      #cp -rsf ${rtorrentPackage}/* ${rutorrentRoot}/
      #chown ruTorrent:ruTorrent -R ${rutorrentRoot}
      #ln -sf ${rutorrentConfig} /var/www/rutorrent/conf/config.php

      ln -sf ${rutorrentPackage}/{css,images,js,lang,index.html} ${rutorrentRoot}/
      mkdir -p ${rutorrentRoot}/{conf,logs,plugins} ${rutorrentRoot}/share/{settings,torrents,users}
      ln -sf ${rutorrentPackage}/conf/{access.ini,plugins.ini} ${rutorrentRoot}/conf/
      ln -sf ${rutorrentConfig} ${rutorrentRoot}/conf/config.php
      cp -r ${rutorrentPackage}/php ${rutorrentRoot}/
      chown -R rutorrent:rutorrent ${rutorrentRoot}/{conf,share,logs,plugins}
      chmod -R 755 ${rutorrentRoot}/{conf,share,logs,plugins}
    '';
    serviceConfig.Type = "oneshot";
  };

  # systemd.services.flood = {
  #   enable = true;
  #   description = "Flood frontend for rtorrent";
  #   bindsTo = [ "rtorrent.service" ];
  #   after = [ "rtorrent.service" ];
  #   wantedBy = [ "multi-user.target" ];
  #   serviceConfig = {
  #     ExecStart = "${pkgs.flood}/bin/flood --rtsocket /run/rtorrent/rpc.sock --port 5678 --host 0.0.0.0";
  #     Restart = "on-failure";
  #     Type = "simple";
  #     User = "rtorrent";
  #     Group = "rtorrent";
  #   };
  # };
  networking.firewall.allowedTCPPorts = [ 5678 ];
}
