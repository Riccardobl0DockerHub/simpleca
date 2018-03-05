#!/bin/bash

mkdir -p /data/priv
mkdir -p /data/public
mkdir -p /data/priv/CA
mkdir -p /data/public/CA
mkdir -p /data/public/certs


if [ ! -f /data/priv/ca-config.json ];
then
    echo "
{
    \"signing\": {
        \"default\": {
            \"expiry\": \"${EXPIRY}\"
        },
        \"profiles\": {
              \"client\": {
                \"expiry\": \"${EXPIRY}\",
                \"usages\": [
                    \"signing\",
                    \"key encipherment\",
                    \"client auth\"
                ]
            },
            \"server\": {
                \"expiry\": \"${EXPIRY}\",
                \"usages\": [
                    \"signing\",
                    \"key encipherment\",
                    \"server auth\"
                ]
            },
            \"peer\": {
                \"expiry\": \"876600h\",
                \"usages\": [
                    \"signing\",
                    \"key encipherment\",
                    \"server auth\",
                    \"client auth\"
                ]
            }
        }
    }
}
" > /data/priv/ca-config.json 
fi


if [ ! -f /data/priv/ca-csr.json ];
then
echo "
{
    \"CN\": \"${CA_CN}\",
    \"key\": {
      \"algo\": \"rsa\",
      \"size\": ${SIZE}
    },
    \"names\": [
      {
        \"C\": \"${C}\",
        \"L\": \"${L}\",
        \"O\": \"${CA_O}\",
        \"OU\": \"${CA_OU}\",
        \"ST\": \"${ST}\"
      }
    ]
  }">/data/priv/ca-csr.json
fi


if [ ! -f /data/priv/CA/ca.csr -o ! -f /data/public/CA/ca.crt.aes256 -o ! -f /data/priv/CA/ca-key.pem ];
then

    if [ "$CA_KEY" = "auto" ];
    then
        CA_KEY=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 4 | head -n 1`
    fi
    
    cd /data/priv/CA
    echo "Generate CA certs"
    echo "Use config"
    cat /data/priv/ca-config.json
    cfssl gencert --config=../ca-config.json -initca ../ca-csr.json | cfssljson -bare ca -
    if [ "$CA_KEY" != "" ];
    then
        openssl aes-256-cbc  -md sha256 -in ca.pem -out ca.crt.aes256 -k $CA_KEY
        echo "curl -L http://192.168.2.20:8889/CA/ca.crt.aes256 | openssl aes-256-cbc -md sha256 -d -out ca.crt -k $CA_KEY"
        cp -f ca.crt.aes256 /data/public/CA/ca.crt.aes256
        rm ca.crt.aes256 
    else
         echo "curl -L http://192.168.2.20:8889/CA/ca.crt -o ca.crt"
        cp -f ca.pem /data/public/CA/ca.crt
    fi
fi




function gen {
    rnd=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
    mkdir -p /tmp/$rnd
    cd /tmp/$rnd
    HOST=$1
    PASSWORD=$2
    CSR="{
        \"hosts\": [
            \"${HOST}\"
        ],
        \"CN\": \"${HOST}\",
        \"key\": {
            \"algo\": \"rsa\",
            \"size\": ${SIZE}
        },
        \"names\": [
            {
                \"C\": \"${C}\",
                \"L\": \"${L}\",
                \"O\": \"${HOST}\",
                \"OU\": \"${HOST}\",
                \"ST\": \"${ST}\"
             }
        ]
    }
    "
    echo "$CSR" > csr.json
    if [ ! -f  "/data/public/certs/${HOST}.tar.gz"  -o "$3" = "regen" ];
    then
        echo "Generate cert for ${HOST}"

        echo "Use config"
        cat /data/priv/ca-config.json
        echo "Request"
        cat csr.json 
        cfssl gencert -profile server  --config=/data/priv/ca-config.json -ca /data/priv/CA/ca.pem -ca-key /data/priv/CA/ca-key.pem csr.json  | cfssljson -bare cert -


        # openssl aes-256-cbc  -md sha256 -in selfsigned.pem -out selfsigned.crt.aes256 -k $PASSWORD
        # rm selfsigned.pem

        # openssl aes-256-cbc  -md sha256 -in selfsigned.csr -out selfsigned.csr.aes256 -k $PASSWORD
        # rm selfsigned.csr

        # openssl aes-256-cbc  -md sha256 -in selfsigned-key.pem -out selfsigned-key.pem.aes256 -k $PASSWORD
        # rm selfsigned-key.pem    

        tar -czf "${HOST}.tar.gz" cert*
        openssl aes-256-cbc  -md sha256 -in "${HOST}.tar.gz" -out  "${HOST}.tar.gz.aes256" -k $PASSWORD
        
        if [ -f "/data/public/certs/${HOST}.tar.gz.aes256" ];
        then
            rm "/data/public/certs/${HOST}.tar.gz.aes256"  
        fi

        mv "${HOST}.tar.gz.aes256"  /data/public/certs/
        
        echo "curl -L http://192.168.2.20:8889/certs/${HOST}.tar.gz.aes256 | openssl aes-256-cbc -md sha256 -d -out ${HOST}.tar.gz -k $PASSWORD"
 
    fi
    rm -Rf  /tmp/$rnd
}

function start {
    cd /data/public/
    webfsd -c 1    -F -p 8080
}

function shell {
    bash
}

$@