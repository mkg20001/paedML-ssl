# some default config
server {
  listen 80 default_server;
  listen [::]:80 default_server;

  include _/silent-403.conf;
  include _/stub-status.conf;
  include _/letsencrypt.conf;

  location / {
    # Redirect all HTTP requests to HTTPS with a 301 Moved Permanently response.
    return 301 https://$host$request_uri;
  }
}

server {
  listen 443 default_server ssl http2;
  listen [::]:443 default_server ssl http2;

  include _/modern-ssl.conf;
  ssl_certificate /etc/ssl/letsencrypt/DOMAIN/fullchain.cer;
  ssl_certificate_key /etc/ssl/letsencrypt/DOMAIN/DOMAIN.key;

  location / {
    # Pass requests to paedML server
    proxy_pass       http://SERVER_IP$request_uri;
    proxy_set_header Host            $host;
    proxy_set_header X-Forwarded-For $remote_addr;
  }

  include _/letsencrypt.conf; # catch /.well_known/letsencrypt
}
