ANOMA_REV ?= v0.2.0
ANOMA_CHAIN_ID ?= anoma-feigenbaum-0.ebb9e9f9013

OUTPUT = stream-anoma-$(ANOMA_REV)
CARGO_NIX = generated/Cargo-$(ANOMA_REV).nix
ANOMA_SRC = generated/anoma-src.$(ANOMA_REV).json

$(OUTPUT): $(CARGO_NIX)
	nix-build -j auto \
	  --argstr ANOMA_REV "$(ANOMA_REV)" \
	  --argstr ANOMA_CHAIN_ID "$(ANOMA_CHAIN_ID)" \
	  -o "$@"

$(CARGO_NIX): $(ANOMA_SRC)
	nix-shell -p crate2nix --command "crate2nix generate \
	  -f "$$(nix-store -r "$$(nix-instantiate --argstr ANOMA_REV $(ANOMA_REV) ./anoma-src.nix)")/Cargo.toml" \
	  -o $@ \
	  "

$(ANOMA_SRC):
	nix-shell -p nix-prefetch-github --command "nix-prefetch-github anoma anoma --rev '$(ANOMA_REV)'" >$@
