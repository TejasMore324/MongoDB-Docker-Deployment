#!/bin/bash
mkdir -p tls
cd tls

# Step 1: Generate CA Key and Cert
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -key ca.key -sha256 -days 365 \
  -out ca.crt -subj "/CN=MyMongoCA"

# Step 2: Generate and Sign Certificates for each MongoDB container including arbiter
for i in 1 2 3; do
  openssl req -newkey rsa:2048 -nodes -keyout mongo${i}.key -out mongo${i}.csr \
    -subj "/CN=mongo${i}"

  echo "subjectAltName=DNS:mongo${i}" > mongo${i}-extfile.cnf

  openssl x509 -req -in mongo${i}.csr -CA ca.crt -CAkey ca.key \
    -CAcreateserial -out mongo${i}.crt -days 365 -sha256 \
    -extfile mongo${i}-extfile.cnf

  cat mongo${i}.crt mongo${i}.key > mongo${i}.pem

  rm mongo${i}.csr mongo${i}-extfile.cnf
done

# Arbiter certificate
openssl req -newkey rsa:2048 -nodes -keyout mongo-arbiter.key -out mongo-arbiter.csr \
  -subj "/CN=mongo-arbiter"

echo "subjectAltName=DNS:mongo-arbiter" > mongo-arbiter-extfile.cnf

openssl x509 -req -in mongo-arbiter.csr -CA ca.crt -CAkey ca.key \
  -CAcreateserial -out mongo-arbiter.crt -days 365 -sha256 \
  -extfile mongo-arbiter-extfile.cnf

cat mongo-arbiter.crt mongo-arbiter.key > mongo-arbiter.pem

rm mongo-arbiter.csr mongo-arbiter-extfile.cnf

echo "TLS files generated in the tls/ folder."
