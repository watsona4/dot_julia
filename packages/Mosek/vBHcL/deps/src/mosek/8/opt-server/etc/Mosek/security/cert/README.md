## Selfsigned demo certificates

Do not use these for production. Please!

Generated with 
```
openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days XXX -nodes
```
