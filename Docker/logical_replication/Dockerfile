FROM postgres:latest

RUN apt-get update \
 && apt-get install -y net-tools vim sudo less  \
 && apt-get install -y emacs-nox procps sudo    \
 && apt-get install -y postgresql-plperl-17     \
 && apt-get install -y pgagroal                 \
 && apt install -y zsh

RUN mkdir -p /data/tablespaces                     \
 && mkdir -p /data/tablespaces/ts_a                \
 && mkdir -p /data/tablespaces/ts_b                \
 && mkdir -p /data/tablespaces/ts_c                \
 && chown -R postgres:postgres /data               \
 && mkdir -p /var/log/pgagroal                     \
 && chown -R postgres:postgres /var/log/pgagroal   \
 && mkdir -p /data/html                            \
 && chown postgres:postgres /data/html


RUN echo '[ ! -z "$TERM" -a -r /etc/motd ] && cat /etc/motd' >> /etc/bash.bashrc
RUN echo 'export PATH=$PATH:/usr/lib/postgresql/17/bin/' >> /etc/bash.bashrc
RUN echo 'export EDITOR=emacs' >> /etc/bash.bashrc
COPY ./motd /etc/motd
COPY ./sudoers.conf /etc/sudoers


RUN echo en_US.UTF-8 UTF-8 > /etc/locale.gen
RUN locale-gen en_US.UTF-8
