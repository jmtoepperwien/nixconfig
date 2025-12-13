{
  config,
  lib,
  pkgs,
  ...
}:

{
  users.groups.cloud = {};
  users.users.seafile = {
    isSystemUser = true;
    group = "seafile";
    extraGroups = [ "cloud" ];
    uid = 500; # Fixed UID to match container
  };
  users.groups.seafile = {
    gid = 500; # Fixed GID to match container
  };

  systemd.tmpfiles.rules = [
    "d ${config.server.cloud_folder}/seafile 0750 seafile seafile"
    "d ${config.server.cloud_folder}/seafile/data 0750 seafile seafile"
    "d ${config.server.cloud_folder}/seafile/logs 0750 seafile seafile"
    "d ${config.server.cloud_folder}/seafile/shared 0750 seafile seafile"
    "d ${config.server.cloud_folder}/seafile/conf 0750 seafile seafile"
  ];

  age.secrets.ldap_bind_passwd_seafile = {
    file = ../secrets/ldap_bind_passwd.age;
    owner = "seafile";
    group = "seafile";
  };

  virtualisation.oci-containers.containers = {
    seafile = {
      image = "seafileltd/seafile-mc:latest";
      autoStart = true;
      
      # Environment variables to preserve your current configuration
      environment = {
        DB_HOST = "host.containers.internal";
        DB_ROOT_PASSWD = ""; # Will use PostgreSQL authentication
        SEAFILE_ADMIN_EMAIL = "admin@local.com";
        SEAFILE_ADMIN_PASSWORD = "changethisseafilepassword";
        SEAFILE_SERVER_LETSENCRYPT = "false"; # We handle SSL with nginx
        SEAFILE_SERVER_HOSTNAME = "mosiseafile.duckdns.org";
        TIME_ZONE = "Europe/Berlin";
      };
      
      ports = [
        "8000:8000"  # Seafile server
        "8001:8001"  # Seahub (web interface)
      ];
      
      volumes = [
        # Data persistence
        "${config.server.cloud_folder}/seafile/data:/shared:Z"
        # Custom configuration will be mounted here
        "${config.server.cloud_folder}/seafile/conf:/shared/seafile/conf:Z"
        # Logs
        "${config.server.cloud_folder}/seafile/logs:/shared/logs:Z"
        # LDAP password file
        "${config.age.secrets.ldap_bind_passwd_seafile.path}:/shared/ldap_passwd:ro,Z"
      ];

      extraOptions = [
        "--add-host=host.containers.internal:host-gateway"  # Access to host PostgreSQL
        "--user=500:500"  # Run as seafile user
      ];
    };
  };

  # Create custom configuration files for LDAP integration
  systemd.services.seafile-config-setup = {
    description = "Setup Seafile container configuration";
    wantedBy = [ "multi-user.target" ];
    before = [ "podman-seafile.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "seafile";
      Group = "seafile";
    };
    script = ''
      # Ensure config directory exists
      mkdir -p ${config.server.cloud_folder}/seafile/conf
      
      # Create seahub_settings.py for LDAP configuration
      cat > ${config.server.cloud_folder}/seafile/conf/seahub_settings.py << 'EOF'
# LDAP Configuration
ENABLE_LDAP = True
LDAP_SERVER_URL = "ldap://host.containers.internal:3890"
LDAP_BASE_DN = "ou=people,dc=mosi,dc=com"
LDAP_ADMIN_DN = "uid=binduser,ou=people,dc=mosi,dc=com"

# Read LDAP password from mounted file
with open("/shared/ldap_passwd", "r") as f:
    LDAP_ADMIN_PASSWORD = f.readline().rstrip()

LDAP_PROVIDER = "ldap"
LDAP_LOGIN_ATTR = "uid"
LDAP_CONTACT_EMAIL_ATTR = "mail"
LDAP_USER_ROLE_ATTR = ""
LDAP_USER_FIRST_NAME_ATTR = "first_name"
LDAP_USER_LAST_NAME_ATTR = "last_name"
LDAP_USER_NAME_REVERSE = False
LDAP_FILTER = "memberof=cn=cloud,ou=groups,dc=mosi,dc=com"

# Database configuration
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'seahub',
        'USER': 'seafile',
        'PASSWORD': '',  # Using peer authentication
        'HOST': 'host.containers.internal',
        'PORT': '5432',
    }
}

# Other settings to match your current setup
FILE_SERVER_ROOT = 'https://mosiseafile.duckdns.org/seafhttp'
SERVICE_URL = 'https://mosiseafile.duckdns.org'
SITE_ROOT = '/'
SITE_NAME = 'Seafile'
SITE_TITLE = 'Seafile'

# Security settings
ALLOWED_HOSTS = ['mosiseafile.duckdns.org', 'localhost', '127.0.0.1']

# File upload settings
FILE_UPLOAD_MAX_MEMORY_SIZE = 10485760  # 10MB
DATA_UPLOAD_MAX_MEMORY_SIZE = 10485760  # 10MB

# Token expiry settings (preserve 5h expiry for longer uploads)
WEB_TOKEN_EXPIRE_TIME = 18000
EOF

      # Create seafile.conf to match your current settings
      cat > ${config.server.cloud_folder}/seafile/conf/seafile.conf << 'EOF'
[database]
type = postgresql
host = host.containers.internal
port = 5432
user = seafile
password = 
db_name = seafile

[fileserver]
# Use internal address for container communication
host = 0.0.0.0
port = 8001

# History settings
[history]
keep_days = 14
EOF

      # Create ccnet.conf
      cat > ${config.server.cloud_folder}/seafile/conf/ccnet.conf << 'EOF'
[General]
USER_NAME = admin@local.com
ID = $(uuidgen)
NAME = seafile
SERVICE_URL = https://mosiseafile.duckdns.org

[Database]
ENGINE = postgresql
HOST = host.containers.internal
PORT = 5432
USER = seafile
PASSWD = 
DB = ccnet
EOF

      # Set proper permissions
      chown -R seafile:seafile ${config.server.cloud_folder}/seafile/conf
      chmod 600 ${config.server.cloud_folder}/seafile/conf/seahub_settings.py
    '';
  };

  # Update nginx configuration for container
  services.nginx.virtualHosts."mosiseafile.duckdns.org" = {
    forceSSL = true;
    useACMEHost = "mosihome.duckdns.org";
    locations = {
      "/" = {
        proxyPass = "http://localhost:8001";  # Seahub container port
        extraConfig = ''
          proxy_read_timeout 1200s;
          client_max_body_size 0;
          proxy_set_header Host $http_host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_connect_timeout 36000s;
          proxy_send_timeout 36000s;
          send_timeout 36000s;
        '';
      };
      "/seafhttp" = {
        proxyPass = "http://localhost:8000";  # Seafile server container port
        extraConfig = ''
          rewrite ^/seafhttp(.*)$ $1 break;
          client_max_body_size 0;
          proxy_set_header Host $http_host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_connect_timeout 36000s;
          proxy_read_timeout 36000s;
          proxy_send_timeout 36000s;
          send_timeout 36000s;
        '';
      };
    };
  };

  # Garbage collection schedule (matches original configuration)
  systemd.services.seafile-gc = {
    description = "Seafile garbage collection";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.podman}/bin/podman exec seafile /scripts/gc.sh";
      User = "root";
    };
  };

  systemd.timers.seafile-gc = {
    description = "Run Seafile garbage collection weekly";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Sun 03:00:00";
      Persistent = true;
    };
  };

  # Ensure PostgreSQL database and user exist
  services.postgresql = {
    ensureDatabases = [ "seafile" "ccnet" "seahub" ];
    ensureUsers = [
      {
        name = "seafile";
        ensureDBOwnership = true;
      }
    ];
  };
}