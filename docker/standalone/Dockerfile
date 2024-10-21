FROM postgres:17.0

RUN apt-get update \
 && apt-get install -y net-tools vim sudo less emacs-nox procps sudo \
 && apt-get install -y postgresql-plperl-17     \
 && apt-get install -y postgresql-plpython3-17  \
 && apt-get install -y postgresql-17-postgis-3  \
 && apt install -y perl pgbadger lighttpd nmap  cron \
 && apt install -y python3-venv python3-pip \
 && apt install -y zsh

RUN mkdir -p /data/tablespaces       \
 && mkdir -p /data/tablespaces/ts_a  \
 && mkdir -p /data/tablespaces/ts_b  \
 && mkdir -p /data/tablespaces/ts_c  \
 && chown -R postgres:postgres /data \
 && mkdir -p /data/html              \
 && chown postgres:postgres /data/html


RUN echo '[ ! -z "$TERM" -a -r /etc/motd ] && cat /etc/motd' >> /etc/bash.bashrc
RUN echo 'export PATH=$PATH:/usr/lib/postgresql/17/bin/' >> /etc/bash.bashrc
RUN echo 'export EDITOR=emacs' >> /etc/bash.bashrc
COPY ./motd /etc/motd
COPY ./sudoers.conf /etc/sudoers

RUN mkdir /var/lib/postgresql/alembic_demo
COPY ./alembic_demo /var/lib/postgresql/alembic_demo
RUN chown -Rf postgres:postgres /var/lib/postgresql/alembic_demo

RUN python3 -m venv /var/lib/postgresql/.alembic.venv.d
RUN chown -Rf postgres:postgres /var/lib/postgresql/.alembic.venv.d
RUN /var/lib/postgresql/.alembic.venv.d/bin/pip3 install sqlalchemy
RUN /var/lib/postgresql/.alembic.venv.d/bin/pip3 install alembic
RUN /var/lib/postgresql/.alembic.venv.d/bin/pip3 install psycopg2-binary
RUN echo 'source /var/lib/postgresql/.alembic.venv.d/bin/activate' >> /var/lib/postgresql/.bashrc

COPY ./crontab /tmp
RUN cat /tmp/crontab | crontab -u postgres -


COPY ./lighttpd.conf /etc/lighttpd/
COPY ./start_services.sh /usr/local/bin
RUN chmod 755 /usr/local/bin/start_services.sh
RUN echo '/usr/local/bin/start_services.sh'  >> /etc/bash.bashrc


RUN echo en_US.UTF-8 UTF-8 > /etc/locale.gen
RUN locale-gen en_US.UTF-8
