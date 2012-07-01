#!/bin/sh
/usr/local/bin/simple_stats.py > /var/www/enum.nic.cz/www/_data/statistics.txt.$$ && mv /var/www/enum.nic.cz/www/_data/statistics.txt.$$ /var/www/enum.nic.cz/www/_data/statistics.txt
