class profile::database_services::sqlserver {

  $sql_source  = hiera('profile::database_services::sqlserver::sql_source')
  $sql_passwd  = hiera('profile::database_services::sql_passwd')
  $sql_version = hiera('profile::database_services::sql_version','MSSQL12')
  $db_hash     = hiera_hash('profile::database_services::sqlserver::db_hash')

  sqlserver_instance{'MSSQLSERVER':
    features              => ['SQL'],
    source                => $sql_source,
    security_mode         => 'SQL',
    sa_pwd                => $sql_passwd,
    sql_sysadmin_accounts => ['dbuser'],
  }

  sqlserver_features { 'Generic Features':
    source    => $sql_source,
    features  => ['ADV_SSMS', 'BC', 'Conn', 'SDK', 'SSMS'],
  }

  sqlserver::config { 'MSSQLSERVER':
    admin_user => 'sa',
    admin_pass => $sql_passwd,
  }

  $db_hash.each |$key, $value| {
    sqlserver::database { $key:
      instance => 'MSSQLSERVER',
    }
    sqlserver::login{ "${key}_login":
      password => $value['password'],
    }

    sqlserver::user{ "${key}_user":
      user     => "${key}_user",
      database => $key,
      require  => Sqlserver::Login["${key}_login"],
    }
  }

  windows_firewall::exception { 'Sql browser access':
    ensure       => present,
    direction    => 'in',
    action       => 'Allow',
    enabled      => 'yes',
    program      => 'C:\Program Files (x86)\Microsoft SQL Server\90\Shared\sqlbrowser.exe',
    display_name => 'MSSQL Browser',
    description  => "MS SQL Server Browser Inbound Access",
  }

  windows_firewall::exception { 'Sqlserver access':
    ensure       => present,
    direction    => 'in',
    action       => 'Allow',
    enabled      => 'yes',
    program      => "C:\\Program Files\\Microsoft SQL Server\\${sql_version}.${db_instance}\\MSSQL\\Binn\\sqlservr.exe",
    display_name => 'MSSQL Access',
    description  => "MS SQL Server Inbound Access",
  }
}
