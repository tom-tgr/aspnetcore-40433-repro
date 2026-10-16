# Revalidation of dotnet/aspnetcore#40433

[dotnet/aspnetcore#40433](https://github.com/dotnet/aspnetcore/issues/40433) (2022, .NET 7 preview 1, msquic 1.9)
reported HTTP/3 ~10x slower than HTTP/2: 3,000 concurrent POSTs to an in-process Kestrel, timed with
`hyperfine "./app 3000"`.

This reruns the issue's two programs **verbatim** (`src/http2.cs`, `src/http3.cs`, extracted from the issue) with its
csproj and build command, on current .NET versions on Linux. The only changes are making the target framework a
parameter and choosing which program to compile.

```bash
./run.sh 3000 net8.0 net10.0 net11.0   # Linux with libmsquic and hyperfine; or run the revalidate-40433 workflow
```

Note: the client in the issue has a 1-second timeout and retries any failed request forever, so timeouts under load
turn directly into extra work. Results are in the workflow summary and the `results` artifact.

## Results (2026-10-16, [run 38890307751](../../actions/runs/38890307751))

GitHub Actions ubuntu-24.04, 2 vCPU, libmsquic 2.6.3, `hyperfine --warmup 1 --runs 10 "./app 3000"`:

| .NET | HTTP/2 | HTTP/3 | HTTP/3 vs HTTP/2 |
|---|---:|---:|---:|
| 8.0 | 275.7 ± 5.5 ms | 412.0 ± 13.9 ms | 1.49× |
| 10.0 | 262.5 ± 12.1 ms | 413.3 ± 14.6 ms | 1.57× |
| 11.0 RC 2 | 259.9 ± 19.8 ms | 426.7 ± 33.6 ms | 1.64× |

- Every run printed the expected sum (4501500).
- The HTTP/3 client requests `Version30` with `RequestVersionOrHigher`, so it cannot fall back to HTTP/2. It also
  retries failures forever, so a completed run with the right sum was served over HTTP/3.
- The original ~10× gap (.NET 7 preview 1, msquic 1.9) is gone. HTTP/3 is ~1.5× slower here, in a CPU-bound loopback
  test on 2 cores. Not profiled.
- Raw hyperfine output is in `results-2026-10-16/`.
