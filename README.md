 
# Deploy MongoDB Replica Set on Docker

This guide provides a complete walkthrough for deploying a **secure MongoDB Replica Set** using **Docker Compose** on a single host. The setup includes TLS encryption for secure communication between replica set members.

---

## 🧰 Prerequisites


- AWS 
- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/)
- [OpenSSL](https://www.openssl.org/) (for generating TLS certificates)
- Git (optional)

---



---

## 🔐 TLS Certificate Setup

To enable secure communication, we use self-signed TLS certificates. Use the following script to generate them:

### 1. Create TLS Script

Create a file named `generate_tls.sh`:

```bash
#!/bin/bash
mkdir -p tls
cd tls

# Step 1: Generate CA Key and Cert
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -key ca.key -sha256 -days 365 \
  -out ca.crt -subj "/CN=MyMongoCA"

# Step 2: Generate and Sign Certificates for each MongoDB container
for i in 1 2 3; do
  openssl req -newkey rsa:2048 -nodes -keyout mongo${i}.key -out mongo${i}.csr \
    -subj "/CN=mongo${i}"

  echo "subjectAltName=DNS:mongo${i}" > mongo${i}-extfile.cnf

  openssl x509 -req -in mongo${i}.csr -CA ca.crt -CAkey ca.key \
    -CAcreateserial -out mongo${i}.crt -days 365 -sha256 \
    -extfile mongo${i}-extfile.cnf

  cat mongo${i}.crt mongo${i}.key > mongo${i}.pem

  # Clean up temporary files
  rm mongo${i}.csr mongo${i}-extfile.cnf
done

echo "TLS files generated in the tls/ folder."

```

### 2. Run the Script

```bash
chmod +x generate_tls.sh
./generate_tls.sh
```

---

## 🐳 Docker Compose Setup

###  Install Docker

```bash
apt install docker-compose
```

Here's the `docker-compose.yml` to run 3 MongoDB containers configured as a replica set using TLS:

```yaml
version: '3.8'

services:
  mongo1:
    image: mongo:6.0
    container_name: mongo1
    hostname: mongo1
    ports:
      - 27017:27017
    volumes:
      - mongo1-data:/data/db
      - ./tls:/etc/ssl/mongo:ro
    networks:
      - mongo-cluster
    command:
      [
        "mongod",
        "--replSet=rs0",
        "--bind_ip_all",
        "--tlsMode=requireTLS",
        "--tlsCertificateKeyFile=/etc/ssl/mongo/mongo1.pem",
        "--tlsCAFile=/etc/ssl/mongo/ca.crt"
      ]

  mongo2:
    image: mongo:6.0
    container_name: mongo2
    hostname: mongo2
    ports:
      - 27018:27017
    volumes:
      - mongo2-data:/data/db
      - ./tls:/etc/ssl/mongo:ro
    networks:
      - mongo-cluster
    command:
      [
        "mongod",
        "--replSet=rs0",
        "--bind_ip_all",
        "--tlsMode=requireTLS",
        "--tlsCertificateKeyFile=/etc/ssl/mongo/mongo2.pem",
        "--tlsCAFile=/etc/ssl/mongo/ca.crt"
      ]

  mongo3:
    image: mongo:6.0
    container_name: mongo3
    hostname: mongo3
    ports:
      - 27019:27017
    volumes:
      - mongo3-data:/data/db
      - ./tls:/etc/ssl/mongo:ro
    networks:
      - mongo-cluster
    command:
      [
        "mongod",
        "--replSet=rs0",
        "--bind_ip_all",
        "--tlsMode=requireTLS",
        "--tlsCertificateKeyFile=/etc/ssl/mongo/mongo3.pem",
        "--tlsCAFile=/etc/ssl/mongo/ca.crt"
      ]

volumes:
  mongo1-data:
  mongo2-data:
  mongo3-data:

networks:
  mongo-cluster:
    driver: bridge

```

---

## 🚀 Launch Replica Set

### 1. Start MongoDB containers

```bash
docker-compose up -d
```

Verify containers are running:

```bash
docker ps
```

### 2. Connect to Primary Node

```bash
docker exec -it mongo1 mongosh \
  --host mongo1 \
  --tls \
  --tlsCAFile /etc/ssl/mongo/ca.crt \
  --tlsCertificateKeyFile /etc/ssl/mongo/mongo1.pem

```

### 3. Initiate the Replica Set

Inside the Mongo shell:

```js
rs.initiate({
  _id: "rs0",
  members: [
    { _id: 0, host: "mongo1:27017" },
    { _id: 1, host: "mongo2:27017" },
    { _id: 2, host: "mongo3:27017" }
  ]
})
```

Check status:

```js
rs.status()
```

---

## 🧼 Cleanup

To stop and remove the containers:

```bash
docker-compose down -v
```

---

## 📌 Notes

- This setup runs MongoDB on a single Docker host with a replica set for testing/demo purposes.
- In production, each MongoDB node should ideally be hosted on a different machine or VM.
- Always secure your TLS certificates and rotate them periodically.

---

## 📖 References

- [MongoDB Replica Set Docs](https://www.mongodb.com/docs/manual/replication/)
- [MongoDB TLS/SSL Configuration](https://www.mongodb.com/docs/manual/tutorial/configure-ssl/)




