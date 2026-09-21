```markdown
# Organ Transport Translating Gateway (SOAP to gRPC)

Distributed systems translating gateway that bridges legacy hospital SOAP/XML clients to a modern gRPC backend.

---

## 1. Quick Setup & Run (Docker)

Run from the project root:

```bash
docker compose up --build -d

```

Verify both containers are running:

```bash
docker compose ps

```

---

## 2. Run Test Suite

Run the automated test script:

```bash
chmod +x test.sh
./test.sh

```
## 3. Stop Containers

```bash
docker compose down

```

```

```