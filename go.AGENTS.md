# Go Standards

## Code Standards

- Complete implementations without placeholders or TODOs.
- Minimal comments unless code is complex.
- `context.Context` as first parameter, variable name `ctx`.
- Wrap errors with context: `fmt.Errorf("<context>: %w", err)`.
- Use package-level `slog.Info`, `slog.Error`, `slog.Warn`, `slog.Debug` instead of `slog.Default()`.
- Use `any` instead of `interface{}`.
- Never use naked returns.
- Use `switch` with no condition instead of `if/else` chains; avoid `else`.
- For non-cryptographic randomness, use `math/rand/v2`.
- Bubble up errors. Never swallow or ignore them. If continuing is safe and intentional, log the error with structured context before continuing.
- Add short doc comments to exported methods and functions except constructors and initializers.
- Define interfaces at the call site that needs them; keep shared packages focused on concrete types and structs.
- Assume constructors and initializers fully initialize their values. Avoid nil-guarding those fields unless a caller can omit them.
- Never use `http.DefaultClient` in production code. It's unsafe.
- Use `time.Now().UTC()` for wall-clock timestamps. Use plain `time.Now()` only for monotonic duration/deadline measurement.
- Log messages: proper casing, no interpolation. Use structured fields for dynamic values, for example `slog.Error("Failed to capture pageview", "error", err)` instead of `slog.Error(fmt.Sprintf("failed: %v", err))`.
- Public methods and functions should never accept private types or interfaces.
- Go 1.26+ allows `new(<literal>)` to get a pointer from a literal, for example `new(42)`.
- Nest the error path, not the happy path. Avoid `err == nil`; prefer `err != nil`.

## Test Standards

- Always use testify's `require`; never use `assert` or `t.Error`.
- Always use `t.Parallel()` in top-level tests, never in subtests.
- Naming: `Test<FunctionName>` for functions, `Test<Type>_<FunctionName>` for methods.
- Always use subtests with "happy path" and error condition cases under the public function or method. Do not create new top-level tests.
- Use `t.Context()`; never use `context.Background()` or `context.TODO()`.
- Use `synctest`, channels, or `errgroup.Group` for concurrency; never use `time.Sleep` unless in a `synctest` bubble.
- Prefer `require.EqualError` over `require.Contains` for error assertions.
- Never test unexported functions; test through public interface only.
- Ignore return values when testing error cases: `_, err := FunctionToTest()`.
- Do not test `New` constructor or initializer functions.

## Test Helper Pattern

When exporting test helpers from a package, define a `TestingT` interface within that package rather than relying on a shared `testutil` package or importing `testing.T` directly. This keeps the interface minimal and co-located with the code that uses it.