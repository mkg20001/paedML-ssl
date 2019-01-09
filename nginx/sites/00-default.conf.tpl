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
    # Redirect all HTTPS requests for unknown domains to the main site.
    return 302 https://MAINSITE;
  }

  include _/letsencrypt.conf;
}
