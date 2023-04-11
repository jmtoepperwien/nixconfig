let
  maltepc = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMIj8ipXRTEQYj+uPRlrSiJnybsC4lguYAA3KSS2/c3i";
  maltexps = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGOBi7azxnZ0RhYXaIoE/axNkfuxnbaJ8Gs3CvLc3OT6 mtoepperwien@maltexps";
  users = [ maltepc ];

  maltepchost = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII2uFpFcaacIH9yLyyABE0u2K1zuV/fph7RDA76zZ0wJ";
  maltexpshost = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ92znHGW5UwpOfOJD/fejUKrsQLpSwSh4dt1xtIrLLs";
  pi3host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGTx5o298UgZ3gIBzFWwE+eOW3ACy0gXtdx71fcLdNvS";
  pi4host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICGDf5ouwaiRlKetP7zb1OxmeronwE2/8S+YwS7tY0g6";
  systems = [ maltepchost pi3host pi4host ];
in {
  "wifipassword.age".publicKeys = [ maltepc maltepchost maltexps maltexpshost pi3host pi4host ];
  "nextcloud-adminpass.age".publicKeys = [ maltepc pi4host ];
  "protonvpn.age".publicKeys = [ maltepc maltexps pi4host ];
}
