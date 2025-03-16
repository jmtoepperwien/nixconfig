{ config, lib, pkgs, inputs, agenix, ... }:

{
  services.prometheus = {
    enable = true;
    exporters = {
      node = {
        enable = true;
        enabledCollectors = [
          "systemd"
        ];
        port = 9000;
      };
    };
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [{
          targets = [ "localhost:${toString config.services.prometheus.exporters.node.port}" ];
        }];
      }
    ];
  };


  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3344;
        domain = "mosihome.duckdns.org";
        root_url = "http://mosihome.duckdns.org/grafana/";
        serve_from_sub_path = true;
      };
    };
  };
}
