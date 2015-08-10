FROM phusion/baseimage:0.9.17
MAINTAINER Nathan Hopkins <natehop@gmail.com>

#RUN echo deb http://archive.ubuntu.com/ubuntu $(lsb_release -cs) main universe > /etc/apt/sources.list.d/universe.list
RUN apt-get -y update\
 && apt-get -y upgrade

# dependencies
RUN apt-get -y --force-yes install vim\
 python-dev\
 python-flup\
 python-pip\
 expect\
 git\
 memcached\
 sqlite3\
 libcairo2\
 libcairo2-dev\
 python-cairo\
 pkg-config

# nginx
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ABF5BD827BD9BF62
RUN echo 'deb http://nginx.org/packages/ubuntu/ trusty nginx' | tee /etc/apt/sources.list.d/nginx.list
RUN apt-get -y update && apt-get -y install nginx

# nodejs
RUN curl --silent --location https://deb.nodesource.com/setup_0.12 | bash -
RUN apt-get -y install nodejs

# python dependencies
RUN pip install django==1.8\
 python-memcached==1.57\
 django-tagging==0.4\
 twisted==15.3.0\
 txAMQP==0.6.2

# install graphite & whisper & carbon
RUN pip install graphite-web==0.9.13\
 whisper==0.9.13\
 carbon==0.9.13

# config graphite
ADD scripts/local_settings.py /opt/graphite/webapp/graphite/local_settings.py
ADD conf/graphite/ /opt/graphite/conf/

# install statsd
RUN git clone -b v0.7.2 https://github.com/etsy/statsd.git /opt/statsd
ADD conf/statsd/config.js /opt/statsd/config.js

# config nginx
RUN rm /etc/nginx/conf.d/*
ADD conf/nginx/nginx.conf /etc/nginx/nginx.conf
ADD conf/nginx/graphite.conf /etc/nginx/conf.d/graphite.conf

# init django admin
ADD scripts/django_admin_init.exp /usr/local/bin/django_admin_init.exp
RUN /usr/local/bin/django_admin_init.exp

# logging support
RUN mkdir -p /var/log/carbon /var/log/graphite /var/log/nginx
ADD conf/logrotate /etc/logrotate.d/graphite
RUN chmod 644 /etc/logrotate.d/graphite

# daemons
ADD daemons/carbon.sh /etc/service/carbon/run
ADD daemons/carbon-aggregator.sh /etc/service/carbon-aggregator/run
ADD daemons/graphite.sh /etc/service/graphite/run
ADD daemons/statsd.sh /etc/service/statsd/run
ADD daemons/nginx.sh /etc/service/nginx/run

# cleanup
RUN apt-get clean\
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# defaults
# EXPOSE 80:80 2003:2003 8125:8125/udp
VOLUME ["/opt/graphite", "/etc/nginx", "/opt/statsd", "/etc/logrotate.d", "/var/log"]
ENV HOME /root
CMD ["/sbin/my_init"]
