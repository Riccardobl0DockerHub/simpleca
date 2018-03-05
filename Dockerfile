FROM cfssl/cfssl

ENV EXPIRY=876600h \
C="IT" \
L="IT"  \
CA_O="SimpleCA" \
CA_OU="CA" \
ST="IT" \
CA_CN="SimpleCA" \
SIZE="2048" \
CA_KEY=""

ADD init.sh /init.sh

RUN chmod +x /init.sh &&\
apt-get update  &&\
apt-get -y upgrade &&\
    apt-get -y install webfs

ENTRYPOINT [ "/init.sh"]
CMD [ "start" ]