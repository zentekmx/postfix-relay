FROM alpine:latest
MAINTAINER Marco A Rojas <marco.rojas@zentek.com.mx>

RUN apk -U add postfix ca-certificates libsasl py-pip supervisor rsyslog openssl
RUN pip install j2cli

ADD ./bootstrap /bootstrap
RUN mkfifo /var/spool/postfix/public/pickup \
    && ln -s /etc/postfix/aliases /etc/aliases

ADD dfg.sh /usr/local/bin/
ADD supervisor-all.ini /etc/supervisor.d/

ADD run.sh /run.sh
RUN chmod +x /run.sh

EXPOSE 25

CMD ["/run.sh"]
