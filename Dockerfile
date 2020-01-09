FROM debian:jessie
MAINTAINER Tomas Jasek<tomsik68 (at) gmail (dot) com>

ENV DEBIAN_FRONTEND noninteractive

# curl is needed to download the xampp installer, net-tools provides netstat command for xampp
RUN apt-get update --fix-missing && \
    apt-get -y install curl net-tools supervisor openssh-server && \
    apt-get autoremove -y && \
    apt-get clean && \
    curl -o xampp-linux-installer.run -L "https://downloadsapachefriends.global.ssl.fastly.net/7.4.1/xampp-linux-x64-7.4.1-0-installer.run?from_af=true" && \
    chmod +x xampp-linux-installer.run && \
    bash -c './xampp-linux-installer.run' && \
    ln -sf /opt/lampp/lampp /usr/bin/lampp && \
    # Enable XAMPP web interface(remove security checks)
    sed -i.bak s'/Require local/Require all granted/g' /opt/lampp/etc/extra/httpd-xampp.conf

# Enable includes of several configuration files
RUN mkdir /opt/lampp/apache2/conf.d && \
    echo "IncludeOptional /opt/lampp/apache2/conf.d/*.conf" >> /opt/lampp/etc/httpd.conf

# Create a /www folder and a symbolic link to it in /opt/lampp/htdocs. It'll be accessible via http://localhost:[port]/www/
# This is convenient because it doesn't interfere with xampp, phpmyadmin or other tools in /opt/lampp/htdocs
RUN mkdir /www \
    && chmod -R 755 /opt/lampp/htdocs \
    && ln -s /www /opt/lampp/htdocs/

# SSH server
# Output supervisor config file to start openssh-server
RUN mkdir -p /var/run/sshd && \
    echo "[program:openssh-server]" >> /etc/supervisor/conf.d/supervisord-openssh-server.conf && \
    echo "command=/usr/sbin/sshd -D" >> /etc/supervisor/conf.d/supervisord-openssh-server.conf && \
    echo "numprocs=1" >> /etc/supervisor/conf.d/supervisord-openssh-server.conf && \
    echo "autostart=true" >> /etc/supervisor/conf.d/supervisord-openssh-server.conf && \
    echo "autorestart=true" >> /etc/supervisor/conf.d/supervisord-openssh-server.conf && \
# Allow root login via password
# root password is: root
    sed -ri 's/PermitRootLogin without-password/PermitRootLogin yes/g' /etc/ssh/sshd_config

# Set root password
# password hash generated using this command: openssl passwd -1 -salt xampp root
RUN sed -ri 's/root\:\*/root\:\$1\$xampp\$5\/7SXMYAMmS68bAy94B5f\./g' /etc/shadow

VOLUME [ "/var/log/mysql/", "/var/log/apache2/" ]

# mysql
EXPOSE 3306
# ssh
EXPOSE 22
# web
EXPOSE 80

# write a startup script
RUN echo '/opt/lampp/lampp start' >> /startup.sh
RUN echo '/usr/bin/supervisord -n' >> /startup.sh

CMD ["sh", "/startup.sh"]
