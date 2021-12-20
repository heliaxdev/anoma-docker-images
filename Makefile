ANOMA_REV ?= v0.2.0
ANOMA_CHAIN_ID ?= anoma-feigenbaum-0.ebb9e9f9013

OUTPUT = stream-anoma-$(ANOMA_REV)
CARGO_NIX = Cargo-$(ANOMA_REV).nix
ANOMA_SRC = anoma-src.$(ANOMA_REV).json
ANOMA_FEATURES = default

$(OUTPUT): $(CARGO_NIX)
	nix-build -j auto \
	  --argstr ANOMA_REV "$(ANOMA_REV)" \
	  --argstr ANOMA_CHAIN_ID "$(ANOMA_CHAIN_ID)" \
	  --argstr ANOMA_FEATURES "$(ANOMA_FEATURES)" \
	  -o "$@"

$(CARGO_NIX): $(ANOMA_SRC)
	crate2nix generate \
	  -f "$$(nix-store -r "$$(nix-instantiate --argstr ANOMA_REV $(ANOMA_REV) ./anoma-src.nix)")/Cargo.toml" \
	  --no-default-features --features '$(ANOMA_FEATURES)' \
	  -o $@

$(ANOMA_SRC):
	nix-prefetch-github anoma anoma --rev '$(ANOMA_REV)' >$@
