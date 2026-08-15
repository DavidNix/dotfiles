# AGENTS.md - Rust

Guidance for AI coding agents and Rust contributors.

## Core Principles

Code **MUST** be fully optimized and idiomatic. It:

- maximizes runtime and memory efficiency
- uses parallelism and SIMD where appropriate
- solves only the requested problem
- avoids technical debt
- uses small, low-overhead crates when they significantly reduce code without
  reducing performance

Take another optimization pass when needed. Prefer clarity and maintainability to
cleverness.

## Commands

Use these commands exactly:

- Build: `cargo build`
- Test: `cargo test --all-features`
- Lint: `cargo clippy --all-targets --all-features -- -D warnings`
- Format: `cargo fmt --all`
- Check formatting: `cargo fmt --all -- --check`
- Type-check: `cargo check --all-targets`

Read `Cargo.lock` only when directly relevant.

## Definition of Done

Complete every applicable item:

- [ ] `cargo test --all-features` passes, including doc tests.
- [ ] `cargo build` emits no warnings.
- [ ] `cargo clippy --all-targets --all-features -- -D warnings` passes. Fix causes;
      reserve targeted `#[allow(...)]` with a one-line justification for false
      positives. Set `-D warnings` in CI rather than `#![deny(warnings)]` in source.
- [ ] `cargo fmt --all -- --check` passes using default rustfmt formatting.
- [ ] Tests cover new or changed public behavior.
- [ ] Doc comments cover all public items.
- [ ] Committed code excludes commented-out code, `println!`, `dbg!`, and `todo!`.
- [ ] Committed code excludes credentials and sensitive data.
- [ ] Rust changes to Python packages are rebuilt with
      `source .venv/bin/activate && maturin develop --release --features python`.
- [ ] Rust changes to WASM packages are rebuilt with
      `wasm-pack build --target web --out-dir web/pkg`.

Report blocked checks and stop.

## Dependencies

- Consult [blessed.rs](https://blessed.rs) before adding a dependency. Use its
  recommendation unless a missing feature, incompatibility, or maintenance issue
  requires another crate; state the reason.
- Prefer `std` and existing dependencies. Justify additions and choose maintained,
  widely used crates.
- Keep unrelated dependencies and versions unchanged.
- Declare version constraints in `Cargo.toml`. Use `cargo` for project, build, and
  dependency management.

### Preferred Tools

Use these defaults when they fit:

- `serde` and `serde_json` for JSON
- `clap` for CLIs and commands
- `indicatif` for context-sensitive progress on long tasks
- `tracing::error!` or `log::error!` for errors

## Error Handling

- **MUST** return `Result<T, E>` from fallible operations and propagate with `?`.
- **MUST** handle production and library errors without `.unwrap()`. Reserve
  `.expect("invariant")` for invariant violations and explain the invariant.
- **MUST** use `thiserror` for concrete library errors and `anyhow` for application
  errors. Public library APIs must expose concrete errors.
- **MUST** preserve each cause with `#[source]` or `#[from]`; add boundary context
  with `.context("what we were doing")`.
- **MUST** log an error once where handled, including the callee's safe error text
  and full source chain. Return sanitized UI or API messages.
- **MUST** propagate, handle, or log every `Result`, including best-effort failures.
  Explicit handling must replace `let _ = ...`, empty branches, and catch-all arms
  that hide errors. Match known benign errors explicitly.
- **MUST** redact passwords, credentials, tokens, PII, and other sensitive values.
  Sanitize source messages that may contain them.

## Type System

- **MUST** make illegal states unrepresentable with types and enums.
- Use newtypes, such as `struct UserId(u64)`, for distinct meanings. Use enums or
  newtypes instead of strings when possible.
- Use `Option<T>` instead of sentinel values.
- Use `From` and `TryFrom` instead of ad hoc conversions and `Display` for
  user-facing types.
- Add `#[must_use]` when callers must use a return value. Consider
  `#[non_exhaustive]` for extensible public types.

## Function Design

- **MUST** give each function one responsibility.
- **MUST** borrow (`&T`, `&mut T`) when ownership is unnecessary.
- Accept broad inputs: `&str` over `&String`, `&[T]` over `&Vec<T>`, and
  `impl AsRef<Path>` over `&Path` for public helpers. Return owned values; returned
  references must originate from inputs.
- Limit functions to five parameters; use a config struct for more.
- Return early to reduce nesting.
- Use iterators and combinators when clearer than loops.

## Struct and Enum Design

- **MUST** give each type one responsibility.
- **MUST** derive `Debug` broadly; derive `Clone`, `PartialEq`, `Eq`, `Hash`, and
  `Default` where appropriate.
- Prefer composition to inheritance-like patterns.
- Use builders for complex construction or many optional fields.
- Keep fields private and visibility minimal. Add accessors when needed; use
  `pub(crate)` for internal sharing.

## Rust Practices

- **MUST** default to safe Rust. Keep necessary `unsafe` code minimal, wrap it in a
  safe API, and document each block's invariants with `// SAFETY:`.
- **MUST** call `.clone()` explicitly on non-`Copy` types and only when ownership
  requires it. Restructure code instead of cloning around the borrow checker.
- **MUST** match exhaustively; use catch-all arms only when necessary.
- **MUST** use `format!` for string formatting.
- Prefer iterators, adapters, and `enumerate()` to manual loops and counters. Iterate
  directly instead of collecting a one-use `Vec`.
- Prefer `if let`, `while let`, `let ... else`, `matches!`, and concise combinators
  to verbose matches.
- Use `TryFrom` or `.try_into()?` for potentially lossy conversions. Reserve `as`
  for infallible casts.

## Memory and Performance

- **MUST** avoid unnecessary allocations; prefer `&str` to `String`.
- **MUST** use `Cow<'_, str>` when ownership is conditional.
- Preallocate known sizes with `Vec::with_capacity()`.
- Prefer stack allocation and borrowing where appropriate.
- Use `Arc` and `Rc` only when shared ownership is necessary.

## Concurrency

- **MUST** apply `Send` and `Sync` bounds appropriately.
- **MUST** prefer `tokio` for async work and `rayon` for CPU parallelism.
- Async functions must use async sleep and I/O or `spawn_blocking` for blocking and
  CPU-heavy work.
- Release `std::sync::Mutex` and `RwLock` guards before `.await`; otherwise use an
  async lock.
- Prefer `RwLock` or lock-free designs to `Mutex` when they fit.
- Use channels such as `mpsc` or `crossbeam` for message passing.

## Style

- **MUST** follow idiomatic Rust and the Rust API Guidelines with descriptive names.
- Use `snake_case` for functions, variables, and modules; `PascalCase` for types and
  traits; and `SCREAMING_SNAKE_CASE` for constants. Omit `get_` from simple accessors.
- Reserve emoji and emoji-like Unicode for multibyte-character tests.
- Prefer `foo.rs` plus `foo/` to `foo/mod.rs`.
- Use explicit imports except in preludes and test modules (`use super::*`). Order
  imports by standard library, external crates, then local modules.
- Comments must explain why, stay current, and omit repetition, prompts, and agent
  instructions.

## Documentation

- **MUST** document all public functions, structs, enums, and methods with `///` and
  each module's purpose with `//!`.
- **MUST** document parameters, returns, and errors. Add examples for complex public
  APIs and keep doc tests passing.
- Keep documentation current and generate it with `cargo doc`.

## Testing

- **MUST** unit-test only public functions and types in same-file
  `#[cfg(test)] mod tests` modules using `#[test]` and `cargo test`.
- Put integration tests in `tests/` and public examples in `///` doc tests.
- **MUST** mock external APIs, file systems, and databases except SQLite, Postgres,
  and MySQL. Test those databases through application code.
- Follow Arrange-Act-Assert. Prefer focused, table-driven tests with clear assertion
  messages; use property tests such as `proptest` for broad input spaces.
- Every bug fix must include a regression test that fails before the fix.
- Commit active tests only.

## Benchmarking

- Run benchmarks serially and without `RUSTFLAGS` such as `target-cpu=native`.
- Measure honestly; improve the code instead of manipulating benchmarks.
- Compare crates under equivalent conditions.
- Keep benchmarks independent; disable features such as caching that couple them.

## Security

- **MUST** keep secrets, API keys, and passwords out of source and logs. Store them
  in `.env`, list `.env` in `.gitignore`, and load them through `dotenvy` or
  `std::env`.
- **MUST** keep tokens and PII out of logs.
- Use `secrecy` for sensitive values.

## When Unsure

Follow repository patterns. Ask about ambiguous decisions. Report blocked checks
and stop.
