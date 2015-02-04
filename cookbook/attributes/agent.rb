default[:baragon][:agent_log] = '/var/log/baragon/baragon_agent.log'

default[:baragon][:agent_yaml] = {
  'server' => {
    'type' => 'simple',
    'applicationContextPath' => '/baragon-agent/v2',
    'connector' => {
      'type' => 'http',
      'port' => 8882
    }
  },
  'zookeeper' => {
    'sessionTimeoutMillis' => 60_000,
    'connectTimeoutMillis' => 5000,
    'retryBaseSleepTimeMilliseconds' => 1_000,
    'retryMaxTries' => 3
  },
  'loadBalancerConfig' => {
    'name' => 'default',
    'domain' => 'vagrant.baragon.biz',
    'rootPath' => '/tmp'
  }
}

# rubocop:disable Metrics/LineLength

default[:baragon][:proxy_template][:filename] = 'proxy/%s.conf'
default[:baragon][:proxy_template][:template] = %q(      # This configuration is automatically generated by Baragon, local changes may be lost!
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
          proxy_set_header Host $http_host;
          proxy_redirect off;
          proxy_set_header X-RealIP $remote_addr;
          proxy_set_header X-Scheme $scheme;
          proxy_set_header X-Request-Start "${msec}";
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
)

default[:baragon][:upstream_template][:filename] = 'upstreams/%s.conf'
default[:baragon][:upstream_template][:template] = "      # This configuration is automatically generated by Baragon, local changes may be lost!
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
"
# rubocop:enable Metrics/LineLength