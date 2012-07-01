test -f /etc/httpd/conf.d/fred-whois-apache.conf || ln -s /usr/share/doc/fred-whois/apache.conf /etc/httpd/conf.d/fred-whois-apache.conf
test -f /var/log/fred-whois.log || touch /var/log/fred-whois.log; chown apache.apache /var/log/fred-whois.log; chcon -t httpd_log_t /var/log/fred-whois.log
 