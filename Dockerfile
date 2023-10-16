FROM ubuntu:22.04 as builder

RUN apt-get update && apt-get install -y \
    build-essential \
    debhelper \
    devscripts \
    rpm \
    ruby-dev \
    wget \
    xalan && \
    gem install fpm

WORKDIR /src
COPY . .

RUN ./create_packages


FROM zabbix/zabbix-agent:ubuntu-6.0.22
MAINTAINER operations@flipapp.de

USER 0
ADD /docker-scripts /tmp/setup
RUN chmod 755 /tmp/setup/*.sh
RUN /tmp/setup/01_phase_base.sh

COPY --from=builder /src/zabbix-agent-extensions_*_all.deb /tmp/setup
RUN /tmp/setup/04_install_agent_extensions.sh
RUN /tmp/setup/05_perform_upgrade.sh

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/bin/docker-entrypoint.sh"]

USER 1997

CMD ["/usr/sbin/zabbix_agentd", "--foreground", "-c", "/etc/zabbix/zabbix_agentd.conf"]
