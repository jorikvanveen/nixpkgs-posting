{
  pkgs,
  lib,
  config,
  ...
}:

with lib;

let
  cfg = config.services.documize;

  mkParams =
    optional:
    concatMapStrings (
      name:
      let
        predicate = optional -> cfg.${name} != null;
        template = " -${name} '${toString cfg.${name}}'";
      in
      optionalString predicate template
    );

in
{
  options.services.documize = {
    enable = mkEnableOption "Documize Wiki";

    stateDirectoryName = mkOption {
      type = types.str;
      default = "documize";
      description = ''
        The name of the directory below {file}`/var/lib/private`
        where documize runs in and stores, for example, backups.
      '';
    };

    package = mkPackageOption pkgs "documize-community" { };

    salt = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "3edIYV6c8B28b19fh";
      description = ''
        The salt string used to encode JWT tokens, if not set a random value will be generated.
      '';
    };

    cert = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        The {file}`cert.pem` file used for https.
      '';
    };

    key = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        The {file}`key.pem` file used for https.
      '';
    };

    port = mkOption {
      type = types.port;
      default = 5001;
      description = ''
        The http/https port number.
      '';
    };

    forcesslport = mkOption {
      type = types.nullOr types.port;
      default = null;
      description = ''
        Redirect given http port number to TLS.
      '';
    };

    offline = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Set `true` for offline mode.
      '';
      apply = v: if true == v then 1 else 0;
    };

    dbtype = mkOption {
      type = types.enum [
        "mysql"
        "percona"
        "mariadb"
        "postgresql"
        "sqlserver"
      ];
      default = "postgresql";
      description = ''
        Specify the database provider: `mysql`, `percona`, `mariadb`, `postgresql`, `sqlserver`
      '';
    };

    db = mkOption {
      type = types.str;
      description = ''
        Database specific connection string for example:
        - MySQL/Percona/MariaDB:
          `user:password@tcp(host:3306)/documize`
        - MySQLv8+:
          `user:password@tcp(host:3306)/documize?allowNativePasswords=true`
        - PostgreSQL:
          `host=localhost port=5432 dbname=documize user=admin password=secret sslmode=disable`
        - MSSQL:
          `sqlserver://username:password@localhost:1433?database=Documize` or
          `sqlserver://sa@localhost/SQLExpress?database=Documize`
      '';
    };

    location = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        reserved
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.services.documize-server = {
      description = "Documize Wiki";
      documentation = [ "https://documize.com/" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = concatStringsSep " " [
          "${cfg.package}/bin/documize"
          (mkParams false [
            "db"
            "dbtype"
            "port"
          ])
          (mkParams true [
            "offline"
            "location"
            "forcesslport"
            "key"
            "cert"
            "salt"
          ])
        ];
        Restart = "always";
        DynamicUser = "yes";
        StateDirectory = cfg.stateDirectoryName;
        WorkingDirectory = "/var/lib/${cfg.stateDirectoryName}";
      };
    };
  };
}
