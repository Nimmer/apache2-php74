#!/usr/bin/env bash
/bin/chown www-data:www-data -R /var/www/web/storage /var/www/web/bootstrap/cache
/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
