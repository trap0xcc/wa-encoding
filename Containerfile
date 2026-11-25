FROM alpine:3.21 AS dependencies
RUN apk add --no-cache ca-certificates curl \
    && curl -fsSL https://raw.githubusercontent.com/SafeteeWoW/LibDeflate/afc3b78d12fb3bcfa6b21e5332031ad3d7572e19/LibDeflate.lua -o /LibDeflate.lua \
    && curl -fsSL https://raw.githubusercontent.com/rossnichols/LibSerialize/31948db085e95807abf4dde4725b14e971df1dcb/LibSerialize.lua -o /LibSerialize.lua

FROM alpine:3.21
RUN apk add --no-cache lua5.4 && adduser -D -H -u 10001 wa-encoding
WORKDIR /app
COPY --from=dependencies /LibDeflate.lua /LibSerialize.lua /app/
COPY decode.lua encode.lua json.lua /app/
USER wa-encoding
ENTRYPOINT ["lua5.4", "/app/decode.lua"]
