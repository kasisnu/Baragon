#!/bin/bash -x
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Fail fast and fail hard.
set -eo pipefail

function install_baragon_config {
  mkdir -p /etc/baragon
  cat > /etc/baragon/baragon_agent.yaml <<EOF

server:
  type: simple
  applicationContextPath: /baragon/v1
  connector:
    type: http
    port: 8081
  requestLog:
    appenders:
      - type: file
        currentLogFilename: ../logs/access.log
        archivedLogFilenamePattern: ../logs/access-%d.log.gz

zookeeper:
  quorum: 192.168.33.20:2181
  zkNamespace: baragon
  sessionTimeoutMillis: 60000
  connectTimeoutMillis: 5000
  retryBaseSleepTimeMilliseconds: 1000
  retryMaxTries: 3

loadBalancerConfig:
  name: $1
  domain: $1.baragon.biz
  rootPath: /etc/nginx/conf.d
  checkConfigCommand: /usr/sbin/nginx -t
  reloadConfigCommand: /usr/sbin/nginx -s reload

templates:
  - filename: proxy/%s.conf
    template: |
      # This configuration is automatically generated by Baragon, local changes may be lost!
      #
      # Service ID: {{{service.serviceId}}}
      # Service base path: {{{service.serviceBasePath}}}
      # Last applied: {{formatTimestamp timestamp}} UTC
      # Owners:
      {{#if service.owners}}
      #   - {{{.}}}
      {{else}}
      #   No owners!
      {{/if}}

      {{#if upstreams}}
      {{#if service.options.nginxExtraConfigs}}
      # BEGIN CUSTOM NGINX CONFIGS
      {{#each service.options.nginxExtraConfigs}}{{{.}}}
      {{/each}}
      # END CUSTOM NGINX CONFIGS
      {{/if}}

      location {{{service.options.nginxLocationModifier}}} {{{service.serviceBasePath}}} {
          proxy_pass_header Server;
          proxy_set_header Host \$http_host;
          proxy_redirect off;
          proxy_set_header X-RealIP \$remote_addr;
          proxy_set_header X-Scheme \$scheme;
          proxy_set_header X-Request-Start "\${msec}";
          {{#if service.options.nginxProxyPassOverride}}
          proxy_pass http://{{{service.options.nginxProxyPassOverride}}};
          {{else}}
          proxy_pass http://baragon_{{{service.serviceId}}};
          {{/if}}
          proxy_connect_timeout {{firstOf service.options.nginxProxyConnectTimeout 55}};
          proxy_read_timeout {{firstOf service.options.nginxProxyReadTimeout 60}};

          {{#if service.options.nginxExtraLocationConfigs}}
          # BEGIN CUSTOM NGINX LOCATION CONFIGS
          {{#each service.options.nginxExtraLocationConfigs}}{{{.}}}
          {{/each}}
          # END CUSTOM NGINX LOCATION CONFIGS
          {{/if}}
      }
      {{else}}
      #
      # Service is disabled due to no defined upstreams!
      # It's safe to delete this file if not needed.
      #
      {{/if}}

    extraTemplates:
      template2: |
          # This configuration is automatically generated by Baragon, local changes may be lost!
          #
          # Service ID: {{{service.serviceId}}}
          # Service base path: {{{service.serviceBasePath}}}
          # Last applied: {{formatTimestamp timestamp}} UTC
          # Owners:
          {{#if service.owners}}
          #   - {{{.}}}
          {{else}}
          #   No owners!
          {{/if}}

          {{#if upstreams}}
          {{#if service.options.nginxExtraConfigs}}
          # BEGIN CUSTOM NGINX CONFIGS
          {{#each service.options.nginxExtraConfigs}}{{{.}}}
          {{/each}}
          # END CUSTOM NGINX CONFIGS
          {{/if}}

          location {{{service.options.nginxLocationModifier}}} {{{service.serviceBasePath}}} {
              proxy_pass_header Server;
              proxy_set_header Host \$http_host;
              proxy_redirect off;
              proxy_set_header X-RealIP \$remote_addr;
              proxy_set_header X-Scheme \$scheme;
              proxy_set_header X-Request-Start "\${msec}";
              {{#if service.options.nginxProxyPassOverride}}
              proxy_pass http://{{{service.options.nginxProxyPassOverride}}};
              {{else}}
              proxy_pass http://baragon_{{{service.serviceId}}};
              {{/if}}
              proxy_connect_timeout {{firstOf service.options.nginxProxyConnectTimeout 55}};
              proxy_read_timeout {{firstOf service.options.nginxProxyReadTimeout 60}};

              {{#if service.options.nginxExtraLocationConfigs}}
              # BEGIN CUSTOM NGINX LOCATION CONFIGS
              {{#each service.options.nginxExtraLocationConfigs}}{{{.}}}
              {{/each}}
              # END CUSTOM NGINX LOCATION CONFIGS
              {{/if}}
          }
          {{else}}
          #
          # Service is disabled due to no defined upstreams!
          # It's safe to delete this file if not needed.
          #
          {{/if}}

  - filename: upstreams/%s.conf
    template: |
      # This configuration is automatically generated by Baragon, local changes may be lost!
      #
      # Service ID: {{{service.serviceId}}}
      # Service base path: {{{service.serviceBasePath}}}
      # Last applied: {{formatTimestamp timestamp}} UTC
      # Owners:
      {{#if service.owners}}
      #   - {{{.}}}
      {{else}}
      #   No owners!
      {{/if}}

      {{#if upstreams}}
      upstream baragon_{{{service.serviceId}}} {
          {{#each upstreams}}server {{{upstream}}};  # {{{requestId}}}
          {{/each}}
          {{#if service.options.nginxExtraUpstreamConfigs}}
          # BEGIN CUSTOM NGINX UPSTREAM CONFIGS
          {{#each service.options.nginxExtraUpstreamConfigs}}{{{.}}}
          {{/each}}
          # END CUSTOM NGINX UPSTREAM CONFIGS
          {{/if}}
      }
      {{else}}
      #
      # Service is disabled due to no defined upstreams!
      # It's safe to delete this file if not needed.
      #
      {{/if}}
    extraTemplates:
      template2: |
          # This configuration is automatically generated by Baragon, local changes may be lost!
          #
          # Service ID: {{{service.serviceId}}}
          # Service base path: {{{service.serviceBasePath}}}
          # Last applied: {{formatTimestamp timestamp}} UTC
          # Owners:
          {{#if service.owners}}
          #   - {{{.}}}
          {{else}}
          #   No owners!
          {{/if}}

          {{#if upstreams}}
          upstream baragon_{{{service.serviceId}}} {
              {{#each upstreams}}server {{{upstream}}};  # {{{requestId}}}
              {{/each}}
              {{#if service.options.nginxExtraUpstreamConfigs}}
              # BEGIN CUSTOM NGINX UPSTREAM CONFIGS
              {{#each service.options.nginxExtraUpstreamConfigs}}{{{.}}}
              {{/each}}
              # END CUSTOM NGINX UPSTREAM CONFIGS
              {{/if}}
          }
          {{else}}
          #
          # Service is disabled due to no defined upstreams!
          # It's safe to delete this file if not needed.
          #
          {{/if}}
EOF
}

function build_baragon {
  cd /baragon
  sudo -u vagrant HOME=/home/vagrant mvn clean package
}

function install_baragon {
  mkdir -p /var/log/baragon
  mkdir -p /usr/local/baragon/bin
  cp /baragon/BaragonAgentService/target/BaragonAgentService-*-SNAPSHOT.jar /usr/local/baragon/bin/baragon_agent.jar

  cat > /etc/init/baragon_agent.conf <<EOF
#!upstart
description "Baragon Agent Service"

env PATH=/usr/local/baragon/bin:/usr/local/sbin:/usr/sbin:/sbin:/usr/lib64/qt-3.3/bin:/usr/local/bin:/bin:/usr/bin

start on stopped rc RUNLEVEL=[2345]

respawn

exec java -Xmx512m -Djava.net.preferIPv4Stack=true -jar /usr/local/baragon/bin/baragon_agent.jar server /etc/baragon/baragon_agent.yaml >> /var/log/baragon/baragon_agent.log 2>&1
EOF
}

function install_nginx {
  apt-get -y install nginx
  mkdir -p /etc/nginx/conf.d/proxy
  mkdir -p /etc/nginx/conf.d/upstreams
  cat > /etc/nginx/nginx.conf <<EOF
user www-data;
worker_processes 4;
pid /run/nginx.pid;

events {
    worker_connections 768;
    # multi_accept on;
}

http {
    # Basic Settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    # server_tokens off;
    # server_names_hash_bucket_size 64;
    # server_name_in_redirect off;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging Settings
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    # Gzip Settings
    gzip on;
    gzip_disable "msie6";

    # Virtual Host Configs
    include /etc/nginx/conf.d/*.conf;
}
EOF
  touch /etc/nginx/conf.d/baragon.conf
  touch /etc/nginx/conf.d/vhost.conf
  cat > /etc/nginx/conf.d/baragon.conf <<EOF
include /etc/nginx/conf.d/upstreams/*.conf;
EOF
  cat > /etc/nginx/conf.d/vhost.conf <<EOF
server {
    listen 127.0.0.1:80;
    location /nginx_status {
        stub_status on;
        access_log off;
        allow 127.0.0.1;
        deny all;
    }
}

server {
    listen 80 backlog=4096;
    listen 443 ssl default_server backlog=4096;
    root /var/www/html/;
    location /error/ {
        alias /var/www/error/;
    }
    error_page 404 /error/404.html;
    error_page 500 /error/500.html;
    include conf.d/proxy/*.conf;
}
EOF
  service nginx reload
}

function stop_baragon {
  set +e  # okay if this fails (i.e. not installed)
  service baragon_agent stop
  set -e
}

function start_baragon {
  service baragon_agent start
}

stop_baragon
install_baragon_config $1
build_baragon
install_baragon
install_nginx
start_baragon

echo "Great Job!"
