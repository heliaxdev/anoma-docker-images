# Anoma docker images (using Nix)

Reproducible and composable OCI images for Anoma using Nix.

## Creating images

Requires the Nix package manager with the `flakes nix-command` features
enabled.

```bash
# You must specify the revision of github.com:anoma/anoma
nix run . -- --no-upload --rev v0.2.0
```

It creates an output called `stream-anoma-${ANOMA_REV}` in the current directory,
which you can execute and pipe the output to the docker daemon, or even directly
to a docker registry.

To load the image into your local docker daemon, run:

```bash
./stream-anoma-v0.2.0 | docker load
```

You could also make an image archive, that can be loaded to a docker daemon or
registry later on:

```bash
./stream-anoma-v0.2.0 | gzip > anoma-v0.2.0.tgz
```

Following arguments are recognized by the build script:

- `--no-upload`: Don't upload the image to a registry.
- `--rev ANOMA_REV`: Anoma revision to build from.
- `-o FILE`: Output file. Default: `stream-anoma-ANOMA_REV`.

Following environment variables are recognized by the build script:

- `ANOMA_CHAIN_ID`: Set the default chain id that is joined to on container start (can also be set at runtime).
- `ANOMA_FEATURES`: Specify Cargo features. Default: `default`.
- `ANOMA_REV`: Alternative to `--rev`.
- `CI_REGISTRY_AUTH`: Credentials to the registry.
- `CI_REGISTRY`: Docker registry to upload to (only if not `--no-upload`). Default: `docker.io`.
- `IMAGE_REPO`: Repository in the registry to upload to. Default: `heliaxdev/anoma`.
- `IMAGE_TAG`: Tag for the uploaded image. Default: `YYYY-MM-DD.REV`.
- `OUTPUT`: Alternative to `-o`.

## Using the images

### Environment variables

Following environment variables can be used to configure the container at
creation time (`docker run -e VAR=VALUE`):

- `ANOMA_CHAIN_ID`: if not empty, performs `anoma client utils join-network
  --chain-id=$ANOMA_CHAIN_ID` before executing the user command.
- `ANOMA_BASE_DIR`: location of the ".anoma" directory inside the container.
  This is the location where you should mount a persistent volume. Default:
  `/data`.
- `ANOMA_WASM_DIR`: location where to store WASM files inside the container.
  Note that if you modify this, you need to take care that the the directory
  exists and that correct `checksums.json` file exists in it. This directory
  does not need to be persisted. Default: `/wasm`.

### Startup scripts

You can place any initialization scripts you want to run when the container
starts in `/docker-entrypoint.d/`. The default entrypoint executes all
executable files in `/docker-entrypoint.d/` in alphabetical order prior to
launching the container command (`anoman ledger run` by default). Each script
must succeed. The container exits immediately if an entrypoint script returns a
non-zero exit code. Following scripts are provided by default:

- `/docker-entrypoint.d/20-join-network.sh`: fetches the network configuration
  for the chain set by the `ANOMA_CHAIN_ID` environment variable.
- `/docker-entrypoint.d/25-patch-config.sh`: patches the config fetched by
  `20-join-network.sh` so that the RPC endpoints are bound to all interfaces
  instead of only localhost. This enables access to those endpoints from other
  containers in the same network, meaning you can run the ledger in one
  container, intent gossip in another and the client in yet another container.
  __Make sure you don't publish the RPC ports to the internet!__

### Container ports

Ports the ledger listens on:

- `26656/tcp`: Tendermint P2P
- `26657/tcp`: Tendermint RPC
- `26658/tcp`: Ledger RPC

Ports the intent gossip node listens on:

- `26659/tcp`: Intent gossip P2P
- `26660/tcp`: Intent gossip RPC

The P2P ports should be exposed to the internet on public nodes so that peers
can connect to them. RPC ports should __not__ be exposed.
