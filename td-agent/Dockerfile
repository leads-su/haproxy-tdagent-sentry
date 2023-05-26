FROM debian:bullseye

RUN apt update && apt install -y sudo mc nano htop curl

RUN curl -fsSL https://toolbelt.treasuredata.com/sh/install-debian-bullseye-td-agent4.sh | sh

CMD /opt/td-agent/bin/fluentd -d /var/run/td-agent.pid -c /etc/td-agent/td-agent.conf --log /var/log/td-agent/td-agent.log \
    && tail -f /var/log/td-agent/td-agent.log
