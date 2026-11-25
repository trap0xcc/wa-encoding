IMAGE ?= wa-encoding

.PHONY: help build encode decode decode-json
help:
	@printf '%s\n' 'Available targets:' '  help    List available targets' '  build   Build the container image' '  encode  Encode Lua table source from standard input' '  decode  Decode a WeakAuras export to Lua' '  decode-json  Decode a WeakAuras export to JSON'

build:
	@podman build -t $(IMAGE) . </dev/null >&2

encode decode: build
	@podman run --rm -i --network=none --entrypoint lua5.4 $(IMAGE) /app/$@.lua

decode-json: build
	@podman run --rm -i --network=none --entrypoint lua5.4 $(IMAGE) /app/decode.lua --json
