# simpleCA

Docker image based on cloudflare's cfssl used to deploy a simple CA for development/testing purposes. 


Run

```
docker run -v /srv/simpleca/priv:/data/priv -v /srv/simpleca/public:/data/public  -p8889:8080 --name=simpleca -d riccardoblb/simpleca:amd64
```

Get CA public cert
``` 
curl -L http://192.168.2.20:8889/CA/ca.crt -o ca.crt
```

Generate new cert
```
docker exec simpleca gen 192.168.2.20 <PASSWORD>
```

Regen

```
docker exec simpleca gen 192.168.2.20 <PASSWORD> regen
```

Get generated cert
```
curl -L http://192.168.2.20:8889/certs/192.168.2.20.tar.gz.aes256 | openssl aes-256-cbc -md sha256 -d -out 192.168.2.20.tar.gz -k <PASSWORD>

```

