let
  maltepc = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMIj8ipXRTEQYj+uPRlrSiJnybsC4lguYAA3KSS2/c3i";
  maltexps = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGOBi7azxnZ0RhYXaIoE/axNkfuxnbaJ8Gs3CvLc3OT6 mtoepperwien@maltexps";
  users = [ maltepc ];

  maltepchost = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII2uFpFcaacIH9yLyyABE0u2K1zuV/fph7RDA76zZ0wJ";
  maltexpshost = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ92znHGW5UwpOfOJD/fejUKrsQLpSwSh4dt1xtIrLLs";
  pi3host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGTx5o298UgZ3gIBzFWwE+eOW3ACy0gXtdx71fcLdNvS";
  serverhost = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEbDhNXRckcZW2FoQmR6CQFNG6XANuLcijh2vc3i1C3O";
  systems = [
    maltepchost
    pi3host
    serverhost
  ];
in
{
  "wifipassword.age".publicKeys = [
    maltepc
    maltepchost
    maltexps
    maltexpshost
    pi3host
    serverhost
  ];
  "nextcloud-adminpass.age".publicKeys = [
    maltepc
    serverhost
  ];
  "protonvpn.age".publicKeys = [
    maltepc
    maltexps
    serverhost
  ];
  "unpackerrConfig.age".publicKeys = [
    maltepc
    maltexps
    serverhost
  ];
  "autobrrConfig.age".publicKeys = [
    maltepc
    maltexps
    serverhost
  ];
  "znc_config.age".publicKeys = [
    maltepc
    maltexps
    serverhost
  ];
  "immich_env.age".publicKeys = [
    maltepc
    maltexps
    serverhost
  ];
  "ldap.age".publicKeys = [
    maltepc
    serverhost
  ];
  "ldap_bind_passwd.age".publicKeys = [
    maltepc
    serverhost
  ];
  "cross-seed.age".publicKeys = [
    maltepc
    maltexps
    serverhost
  ];
}
