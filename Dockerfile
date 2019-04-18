FROM centos:7

LABEL maintainer="groge <groge.choi@gmail.com>"
#ENV container docker
## Install Suricata as describe here https://redmine.openinfosecfoundation.org/projects/suricata/wiki/CentOS_Installation
RUN yum install -y epel-release \
 && yum update -y \
 && yum install -y gcc libpcap-devel pcre-devel libyaml-devel file-devel \
    zlib-devel jansson-devel nss-devel libcap-ng-devel libnet-devel \
    libnetfilter_queue-devel lua-devel wget tar make git cmake ragel \
    which libtool gcc-c++ bzip2-devel readline-devel python-devel hiredis-devel

## Upgrade pcre
RUN cd /opt/ \
 && wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.43.tar.gz \
 && tar zxf pcre-8.43.tar.gz \
 && cd pcre-8.43 \
 && ./configure --libdir=/usr/lib64 \
                --docdir=/usr/share/doc/pcre-8.43 \
                --enable-unicode-properties \
                --enable-pcre16 \
                --enable-pcre32 \
                --enable-pcregrep-libz \
                --enable-pcregrep-libbz2 \
                --enable-pcretest-libreadline \
                --disable-static \
                --enable-utf8 \
                --enable-unicode-properties \
 && make && make install 
# RUN ls /usr/lib64/libpcre.so.*
# RUN ls /lib64/libpcre.so.*
# RUN    cp -Ruv /usr/lib64/libpcre.so.* /lib64 
# RUN    ln -s /usr/lib64/libpcre.so.1.2.11 /usr/lib64/libpcre.so
## && ln -sfv ../../lib64/$(readlink /usr/lib/libpcre.so) /usr/lib64/libpcre.so

## Install boost
RUN cd /opt/ \
 && curl -L -o boost_1_70_0.tar.gz https://dl.bintray.com/boostorg/release/1.70.0/source/boost_1_70_0.tar.gz \
 && tar xzf boost_1_70_0.tar.gz \
 && cd boost_1_70_0 \
 && ./bootstrap.sh \
 && ./b2

## Install HyperScan
RUN cd /opt/ \
 && git clone https://github.com/01org/hyperscan \
 && mkdir -p ./hyperscan/build \
 && cd /opt/hyperscan/build \
 && cmake -DCMAKE_INSTALL_PREFIX:PATH=/opt/hyperscan -DBUILD_STATIC_AND_SHARED=1 -DBOOST_ROOT=/opt/boost_1_70_0/ ../ \
 && make \
 && make install \
 && echo "/opt/hyperscan/lib64" >> /etc/ld.so.conf.d/hs.conf \
 && ldconfig \
 && echo "LD_LIBRARY_PATH=/opt/hyperscan/lib64:\$LD_LIBRARY_PATH" >> /etc/profile \
 && echo "export LD_LIBRARY_PATH" >> /etc/profile \
 && source /etc/profile
    
RUN cd /opt/ \
 && wget https://www.openinfosecfoundation.org/download/suricata-4.1.3.tar.gz \
 && tar -xvzf /opt/suricata-4.1.3.tar.gz \
 && cd /opt/suricata-4.1.3/ \
 && ./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --enable-nfqueue --enable-lua --with-libhs-libraries=/opt/hyperscan/lib64/ --with-libhs-includes=/opt/hyperscan/include/hs/ --enable-hiredis \
 && make \
 && make install \
 && ldconfig

# Remove library
RUN yum -y erase automake autoconf git make gcc gcc-c++ libpcap-devel pcre-devel libyaml-devel \
   file-devel zlib-devel jansson-devel nss-devel libcap-ng-devel libnet-devel \
   libnetfilter_queue-devel lua-devel gcc-c++ bzip2-devel readline-devel python-devel hiredis-devel

#RUN rm -rf /opt/{hyperscan,suricata-4.1.3,pcre-8.43,boost_1_70_0}
RUN yum -y clean all

# COPY file needed for the Suricata efficiency
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
COPY suricata.yaml /etc/suricata/suricata.yaml

# RUN useradd -s /sbin/nologin suri \
# && chown -R suri:suri /var/run/suricata/ \
# && chown -R suri:suri /var/log/suricata/
# ENV CHART_PREFIX=suricata

ENTRYPOINT ["/docker-entrypoint.sh"]

