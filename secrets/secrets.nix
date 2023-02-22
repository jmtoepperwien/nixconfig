let
  maltepc = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMIj8ipXRTEQYj+uPRlrSiJnybsC4lguYAA3KSS2/c3i";
  users = [ maltepc ];

  maltepchost = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDvLtYuHA9IbLURBOmjS6l/oi+9jjWdGh3q+Hcppq65C";
  pi3host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGTx5o298UgZ3gIBzFWwE+eOW3ACy0gXtdx71fcLdNvS";
  systems = [ maltepchost pi3host ];
in {
  "wifipassword.age".publicKeys = [ maltepc maltepchost pi3host ];
}
