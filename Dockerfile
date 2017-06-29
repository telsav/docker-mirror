FROM ubuntu:14.04.3
MAINTAINER Charlie Wang<272876047@qq.com>

#参数
ENV DOMAIN **None**
ENV MIRROR_NAME google

RUN apt-get update && \
apt-get clean  

#cron可选安装。
RUN apt-get update && \cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    apt-get install -y openssh-server build-essential patch binutils make devscripts nano libtool libssl-dev libxml2 \
                       libxml2-dev software-properties-common python-software-properties dnsutils \
                       git wget curl python3 python3-dev iftop cron && \
    wget --no-check-certificate https://bootstrap.pypa.io/get-pip.py -O - | python3

#推荐安装的cChardet fastcache需要安装python3-dev和build-essential
RUN pip3 install -r https://raw.githubusercontent.com/aploium/zmirror/master/requirements.txt

#Apache2 installation。 "LC_ALL=C.UTF-8"必须添加，要不然apt-key获取失败会导致后续很多错误。
RUN LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/apache2 && \
    apt-key update && apt-get update && apt-get upgrade -y && \
    apt-get install -y apache2 && \
    a2enmod rewrite mime include headers filter expires deflate autoindex setenvif ssl http2 && \
    apt-get install -y libapache2-mod-wsgi-py3

#Zmirror installation,如果要安装另外的例如YouTube镜像，请修改此段。
RUN cd /var/www && \
    git clone https://github.com/aploium/zmirror ${MIRROR_NAME} && chown -R www-data.www-data ${MIRROR_NAME} && \
    cp /var/www/${MIRROR_NAME}/more_configs/config_google_and_zhwikipedia.py /var/www/${MIRROR_NAME}/config.py && \
    sed -i "s/^my_host_scheme.*$/my_host_scheme = \'https:\/\/\'/g" /var/www/${MIRROR_NAME}/config.py && \
    echo "verbose_level = 2" >> /var/www/${MIRROR_NAME}/config.py

#Apache2 conf cleaning according to https://github.com/aploium/zmirror-onekey/blob/master/deploy.py
RUN rm -rf /etc/apache2/sites-enabled/000-default.conf && \
    rm -rf /etc/apache2/conf-enabled/apache2-doc.conf && \
    rm -rf /etc/apache2/conf-enabled/security.conf

#zmirror-apache-boilerplate.conf is the h5.conf
ADD zmirror-apache-boilerplate.conf /etc/apache2/conf-enabled/zmirror-apache-boilerplate.conf

//set password
RUN echo "root:password"|chpasswd
RUN sed -ri 's/^PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
	sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config

ADD apache2-https.conf /etc/apache2/sites-enabled/apache2-https.conf.sample
ADD apache2-http.conf /etc/apache2/sites-enabled/zmirror-http-redirection.conf

ADD ENTRY.sh /
RUN chmod a+x /ENTRY.sh

# PORTS
EXPOSE 80
EXPOSE 443

# Configure container to run as an executable
ENTRYPOINT ["/ENTRY.sh"]

CMD ["start"]


