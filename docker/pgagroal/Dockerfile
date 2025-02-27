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

#
# pgagroal setup files
#
COPY ./conf/pgagroal.conf /etc/pgagroal
COPY ./conf/pgagroal_databases.conf /etc/pgagroal
COPY ./conf/pgagroal_users.conf /etc/pgagroal
RUN mkdir /var/lib/postgresql/.pgagroal/
COPY ./conf/master.key /var/lib/postgresql/.pgagroal/
RUN chown -R postgres:postgres /etc/pgagroal
RUN chown -R postgres:postgres /var/lib/postgresql/.pgagroal
RUN chmod 700 /var/lib/postgresql/.pgagroal/
RUN chmod 600 /var/lib/postgresql/.pgagroal/master.key


#COPY ./crontab /tmp
#RUN cat /tmp/crontab | crontab -u postgres -



COPY ./start_services.sh /usr/local/bin
RUN chmod 755 /usr/local/bin/start_services.sh
RUN echo '/usr/local/bin/start_services.sh'  >> /etc/bash.bashrc


RUN echo en_US.UTF-8 UTF-8 > /etc/locale.gen
RUN locale-gen en_US.UTF-8
