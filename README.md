# wa-encoding

Convert WeakAuras and ForeverAuras `!WA:2!` exports to and from Lua table
source:

```sh
make decode < aura.txt > aura.lua
make decode-json < aura.txt > aura.json
make encode < aura.lua > aura.txt
```

Run `make` to list all targets. The conversion targets build the image before
running, reusing cached layers when the source has not changed. `make build`
builds the image without running a conversion. Set `IMAGE` to choose a different
image tag, for example:

```sh
make encode IMAGE=my-wa-image < aura.lua > aura.txt
```

Build output and errors go to standard error; standard output contains only the
result.

## Running the image directly

```sh
podman build -t wa-encoding .
podman run --rm -i --network=none wa-encoding < aura.txt > aura.lua
podman run --rm -i --network=none --entrypoint lua5.4 wa-encoding \
    /app/encode.lua < aura.lua > aura.txt
```

The image downloads its dependencies during the build and runs as a non-root
user without runtime network access, mounts, or a terminal.

## Format

Only the `!WA:2!` format is supported. Decoding removes the prefix, decodes the
printable representation with `DecodeForPrint`, decompresses raw DEFLATE with
`DecompressDeflate`, and deserializes with `Deserialize`. Encoding applies
`Serialize`, `CompressDeflate`, and `EncodeForPrint` in reverse. The data must
be a single table.

The encoder accepts a Lua chunk that returns one table, including the output of
the decoder. It evaluates the chunk in an empty environment, so library globals
are unavailable; input should still be trusted, since Lua code can consume
runtime resources. Embedded source stored in table strings is treated as data.

The decoder sorts keys by type (boolean, number, string) and then by value.
Shared or cyclic table references and table keys are rejected explicitly: a
plain table literal cannot preserve reference identity, and table keys cannot
be ordered reliably by value. Other unsupported types are also rejected.
Multiline strings use long brackets when doing so preserves their exact bytes;
other strings use escapes.

## JSON output

`make decode-json` produces JSON for inspection. Nonempty contiguous Lua
sequences become arrays; other tables become objects, with numeric keys
converted to strings. Empty tables become `{}` because Lua does not distinguish
empty arrays from empty objects. Invalid UTF-8, non-finite numbers, unsupported
keys, and key collisions cause an error. JSON cannot preserve every Lua table
distinction, so use Lua output for round trips.

## Dependencies

Both libraries are downloaded at image build time from their upstream
repositories:

- LibDeflate: https://github.com/SafeteeWoW/LibDeflate
  Commit: `afc3b78d12fb3bcfa6b21e5332031ad3d7572e19`
- LibSerialize: https://github.com/rossnichols/LibSerialize
  Commit: `31948db085e95807abf4dde4725b14e971df1dcb` (v1.0.0)
