{
  config,
  lib,
  pkgs,
  inputs,
  agenix,
  ...
}:

{
  age.secrets."zncconfig" = {
    file = ../secrets/znc_config.age;
    owner = "znc";
    group = "znc";
  };
  services.znc = {
    enable = true;
    openFirewall = true;
    configFile = config.age.secrets."zncconfig".path;
  };
}
