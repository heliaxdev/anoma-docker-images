# Docker Compose for Anoma

Setup a local testnet using Docker Compose.

Requirements: `docker`, `docker-compose`, `jq`.

Tested on Linux. Might work on Mac.

## Usage

Choose docker image (optional, defaults to `v0.2.0` from Docker Hub):

```bash
# Option 1 (use: heliaxdev/anoma:$ANOMA_TAG)
export ANOMA_TAG=v0.2.0
# Option 2 (use: $ANOMA_IMAGE)
export ANOMA_IMAGE=my-custom-image:latest
```

Create the genesis configuration:

```bash
./tasks init
```

Start the network:

```bash
./tasks compose up --build
```

Start shell in node which is _not_ a validator:

```bash
./tasks compose exec ledger sh
anomac epoch # etc. etc.
```

All `docker-compose` commands can be invoked through `./tasks compose ...`

Configure nftables for the docker network:

```bash
./tasks setup-nftables
```
