#!/usr/bin/env bash
# Revalidates dotnet/aspnetcore#40433 (HTTP/3 ~10x slower than HTTP/2) with the issue's own programs and command.
# Linux only (HTTP/3 needs libmsquic). Usage: ./run.sh [requests] [tfm ...]   e.g. ./run.sh 3000 net8.0 net10.0
set -euo pipefail
cd "$(dirname "$0")"
N=${1:-3000}
shift || true
TFMS=${*:-net8.0 net10.0}
OUT=results
mkdir -p "$OUT"

for tfm in $TFMS; do
  for proto in http2 http3; do
    dir="publish/$tfm-$proto"
    # The issue's build command: self-contained, single file (ReadyToRun from the csproj).
    dotnet publish src/app.csproj -c Release -r linux-x64 --self-contained true -p:PublishSingleFile=true \
      -p:Tfm="$tfm" -p:Protocol="$proto" -o "$dir" -v quiet -nologo
    echo "== $tfm $proto: sanity run (expect $((N * (N + 1) / 2)))"
    "./$dir/app" "$N"
    hyperfine --warmup 1 --runs 10 -N --export-json "$OUT/$tfm-$proto.json" --export-markdown "$OUT/$tfm-$proto.md" \
      --command-name "$tfm $proto" "./$dir/app $N"
  done
done
