FROM ubuntu:14.04.3
MAINTAINER Charlie Wang<272876047@qq.com>

#参数
ENV DOMAIN **None**
ENV MIRROR_NAME google

RUN apt-get update && \
apt-get clean  

RUN apt-get install -y openssh-server python3 python-pip python-m2crypto libnet1-dev libpcap0.8-dev git gcc && \
apt-get clean

RUN apt-get install -y nginx && \
apt-get clean

COPY nginx.conf /etc/nginx/nginx.conf


RUN echo "root:password"|chpasswd
RUN sed -ri 's/^PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
	sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config

RUN git clone https://github.com/aploium/zmirror-onekey.git --depth=1
RUN cd zmirror-onekey
RUN python3 deploy.py


# Configure container to run as an executable
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
