# == Class: puppet::server::puppetserver
#
# Configures the puppetserver jvm configuration file using augeas.
#
# === Parameters:
#
# * `java_bin`
# Path to the java executable to use
#
# * `config`
# Path to the jvm configuration file.
# This file is usually either /etc/default/puppetserver or
# /etc/sysconfig/puppetserver depending on your *nix flavor.
#
# * `jvm_min_heap_size`
# Translates into the -Xms option and is added to the JAVA_ARGS
#
# * `jvm_max_heap_size`
# Translates into the -Xmx option and is added to the JAVA_ARGS
#
# * `jvm_extra_args`
# Custom options to pass through to the java binary. These get added to
# the end of the JAVA_ARGS variable
#
#
# === Example
#
# @example
#
#   # configure memory for java < 8
#   class {'::puppet::server::puppetserver':
#     jvm_min_heap_size => '1G',
#     jvm_max_heap_size => '3G',
#     jvm_extra_args    => '-XX:MaxPermSize=256m',
#   }
#
class puppet::server::puppetserver (
  $java_bin          = $::puppet::server_jvm_java_bin,
  $config            = $::puppet::server_jvm_config,
  $jvm_min_heap_size = $::puppet::server_jvm_min_heap_size,
  $jvm_max_heap_size = $::puppet::server_jvm_max_heap_size,
  $jvm_extra_args    = $::puppet::server_jvm_extra_args,
  $ssl_ca_cert       = $::puppet::server::ssl_ca_cert,
  $ssl_ca_crl        = $::puppet::server::ssl_ca_crl,
  $ssl_cert          = $::puppet::server::ssl_cert,
  $ssl_cert_key      = $::puppet::server::ssl_cert_key,
  $ssl_chain         = $::puppet::server::ssl_chain,
) {

  $puppetserver_package = pick($::puppet::server_package, 'puppetserver')

  $jvm_cmd_arr = ["-Xms${jvm_min_heap_size}", "-Xmx${jvm_max_heap_size}", $jvm_extra_args]
  $jvm_cmd = strip(join(flatten($jvm_cmd_arr),' '))

  augeas {'puppet::server::puppetserver::jvm':
    lens    => 'Shellvars.lns',
    incl    => $config,
    context => "/files${config}",
    changes => [
      "set JAVA_ARGS '\"${jvm_cmd}\"'",
      "set JAVA_BIN ${java_bin}",
    ],
  }

  ::ca::config::puppetserver{ 'webserver.conf/webserver/ssl-host':
    value => '0.0.0.0',
  }
  ::ca::config::puppetserver{ 'webserver.conf/webserver/ssl-port':
    value => '8140',
  }

  if $::puppet::server_ca {
    $authority_service = 'present'
    $authority_disabled_service = 'absent'
  } else {
    $authority_service = 'absent'
    $authority_disabled_service = 'present'
    ::puppet::server::config::puppetserver{ 'webserver.conf/webserver/ssl-cert':
      value => $ssl_cert,
    }
    ::puppet::server::config::puppetserver{ 'webserver.conf/webserver/ssl-key':
      value => $ssl_cert_key,
    }
    ::puppet::server::config::puppetserver{ 'webserver.conf/webserver/ssl-ca-cert':
      value => $ssl_ca_cert,
    }
  }
  ::puppet::server::config::bootstrap { 'puppetlabs.services.ca.certificate-authority-service/certificate-authority-service':
    ensure => $authority_service,
  }
  ::puppet::server::config::bootstrap{ 'puppetlabs.services.ca.certificate-authority-disabled-service/certificate-authority-disabled-service' :
    ensure => $authority_disabled_service,
  }



}
