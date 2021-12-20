# Anoma docker images (using Nix)

Reproducible and composable OCI images for Anoma using Nix.

## Usage

Requires the Nix package manager with the `flakes nix-command` features
enabled.

```bash
# Use a specific revision of the github.com:anoma/anoma repo
export ANOMA_REV=v0.2.0

# Set different default chain id (can also be set at runtime)
export ANOMA_CHAIN_ID=anoma-feigenbaum-0.ebb9e9f9013

# Specify Cargo features
export ANOMA_FEATURES='default feat1 feat2'

nix develop -c ./ci.sh
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
