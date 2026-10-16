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
