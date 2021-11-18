# Anoma docker images (using Nix)

Reproducible and composable OCI images for Anoma using Nix.

## Usage

Requires GNU Make and the Nix package manager:

```bash
make

# Use a specific revision of the github.com:anoma/anoma repo
make ANOMA_REV=v0.2.0

# Set different default chain id (can also be set at runtime)
make ANOMA_REV=v0.2.0 ANOMA_CHAIN_ID=anoma-feigenbaum-0.ebb9e9f9013
```

It creates an output called `stream-anoma-${ANOMA_REV}` in the current directory,
which you can execute and pipe the output to the docker daemon, or even directly
to a docker registry.

To load the image into your local docker daemon, run:

```bash
./anoma-v0.2.0 | docker load
```

You could also make an image archive, that can be loaded to a docker daemon or
registry later on:

```bash
./anoma-v0.2.0 | gzip > anoma-v0.2.0.tgz
```
