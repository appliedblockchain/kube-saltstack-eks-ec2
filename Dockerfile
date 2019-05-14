FROM ubuntu:18.04
WORKDIR /srv

ENV DEBIAN_FRONTEND noninteractive
ENV LANG C.UTF-8  
ENV LC_ALL C.UTF-8  

RUN mkdir -p /etc/salt/master.d/ /srv/salt

RUN apt-get update && \
    apt-get install -y curl wget vim less apt-transport-https libsodium23

RUN apt-get update && \
  ACCEPT_EULA=Y apt-get install -y \
  python3 \
  python3-pip \
  && apt-get clean && \
  rm -rf /var/lib/apt/lists/*


RUN mkdir -p /etc/services.d/sshd
COPY ./templates/services/ubuntu/run-sshd /etc/services.d/sshd/run

RUN mkdir -p /var/run/sshd && \
    mkdir /root/.ssh && chmod 700 /root/.ssh && \
    touch /root/.ssh/authorized_keys

COPY ["./Pipfile*", "/tmp/"]

COPY salt /srv/salt

RUN pip3 install pipenv==2018.11.26 && \
  cd /tmp && \
  pipenv install --system --deploy

ENTRYPOINT ["salt-master"]
