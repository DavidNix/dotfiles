# AGENTS.md - Rust

Guidance for AI coding agents and contributors working in Rust repositories.

---

## Core Principles

All code you write MUST be fully optimized. "Fully optimized" means:

- maximize algorithmic efficiency for memory and runtime
- use parallelization and SIMD where appropriate
- follow idiomatic Rust style
- add no code beyond what the user's problem requires
- avoid technical debt
- use a small, low-overhead crate when it significantly reduces new code while
  preserving optimal performance; see Dependencies for selection rules

You may take another pass if the code is not fully optimized. Prioritize clarity
and maintainability over cleverness.

---

## Commands

Use these exact commands. Do not invent flags.

- Build: `cargo build`
- Run tests: `cargo test --all-features`
- Lint: `cargo clippy --all-targets --all-features -- -D warnings`
- Format: `cargo fmt --all`
- Check formatting only: `cargo fmt --all -- --check`
- Fast type-check: `cargo check --all-targets`

**NEVER** read `Cargo.lock` unless it is directly relevant. It is large and
usually irrelevant.

## Definition of Done - Before Committing

All of these must pass before you consider a task complete:

- [ ] All tests pass, including doc tests: `cargo test --all-features`
- [ ] The project builds with no compiler warnings: `cargo build`
- [ ] Clippy passes: `cargo clippy --all-targets --all-features -- -D warnings`.
      Fix the cause; do not silence lints with blanket `#[allow(...)]`. Use a
      targeted `allow` with a one-line justification only for a genuine false
      positive. Use `-D warnings` in CI, not `#![deny(warnings)]` in source.
- [ ] Code is formatted with default rustfmt style: `cargo fmt --all -- --check`.
      Never hand-format.
- [ ] New or changed public behavior has tests.
- [ ] All public items have doc comments.
- [ ] Committed code contains no commented-out code, debug `println!` statements,
      `dbg!` macros, or `todo!()` calls.
- [ ] Code contains no hardcoded credentials or sensitive data.
- [ ] If the project creates a Python package and Rust code changed, rebuild it:
      `source .venv/bin/activate && maturin develop --release --features python`.
- [ ] If the project creates a WASM package and Rust code changed, rebuild it:
      `wasm-pack build --target web --out-dir web/pkg`.

If a check cannot pass, stop and report why. Do not work around it.

---

## Dependencies

- **When adding a dependency, consult [blessed.rs](https://blessed.rs) first.** It
  is a curated, community-maintained registry of recommended crates by use case.
  Prefer its recommendation for the problem at hand. Deviate only for a concrete
  reason, such as a missing feature, incompatibility, or poor maintenance status,
  and state that reason.
- Prefer `std` and existing dependencies before adding a crate. Justify each
  addition, explain why `std` or existing dependencies do not suffice, and choose
  well-maintained, widely used crates.
- Do not bump or add dependencies as a side effect of an unrelated change.
- **MUST** document dependencies in `Cargo.toml` with version constraints.
- Use `cargo` for project management, builds, and dependency management.

### Preferred Tools

These defaults are pre-approved and consistent with blessed.rs picks. Do not shop
around when they fit.

- Use `serde` with `serde_json` for JSON serialization and deserialization.
- Use `clap` for CLIs and commands.
- Use `indicatif` for progress bars in long-running operations; keep messages
  context-sensitive.
- Use `tracing::error!` or `log::error!` instead of `println!` when reporting
  errors to the console.

---

## Error Handling

- **MUST** use `Result<T, E>` for fallible operations and propagate errors with
  `?`.
- **NEVER** use `.unwrap()` in production code paths or library code. Use
  `.expect("why this cannot fail")` only for invariant violations, and explain the
  invariant in the message.
- **MUST** use `thiserror` for concrete error types in libraries and `anyhow` for
  application-level errors. Do not leak `anyhow` through a public library API.
- Add meaningful context at boundaries with `.context("what we were doing")`.
- Never discard a `Result` silently. Use `let _ = ...;` only when ignoring the
  result is deliberate, and add a comment explaining why.

## Type System

- **MUST** use Rust's type system to prevent bugs at compile time. Model state
  with `enum`s and make illegal states unrepresentable.
- Use newtypes, such as `struct UserId(u64)`, to distinguish semantically
  different values with the same underlying type. Do not stringly-type data that
  has a natural enum or newtype representation.
- Prefer `Option<T>` over sentinel values.
- Prefer `From` and `TryFrom` for conversions, and implement `Display` for
  user-facing types. Do not write ad-hoc `to_x()` methods when a trait fits.
- Add `#[must_use]` to functions whose return value should not be ignored.
  Consider `#[non_exhaustive]` for public types and enums that may grow.

## Function Design

- **MUST** keep functions focused on one responsibility.
- **MUST** prefer borrowing (`&T`, `&mut T`) over ownership when possible.
- Accept the widest reasonable argument type: `&str` over `&String`, `&[T]` over
  `&Vec<T>`, and `impl AsRef<Path>` over `&Path` for public helpers. Return
  owned values. Never return references borrowed from function locals.
- Limit functions to five or fewer parameters. Use a config struct for more.
- Return early to reduce nesting.
- Use iterators and combinators when they are clearer than explicit loops.

## Struct and Enum Design

- **MUST** keep types focused on one responsibility.
- **MUST** derive common traits: `Debug` on almost everything; `Clone`,
  `PartialEq`, `Eq`, and `Hash` where appropriate; and `#[derive(Default)]` when
  a sensible default exists.
- Use composition over inheritance-like patterns.
- Use the builder pattern for complex struct construction or many optional fields.
- Make fields private by default, and provide accessor methods when needed. Keep
  visibility minimal: use `pub(crate)` for internal sharing and the smallest
  public surface that works.

## Rust Best Practices

- **NEVER** use `unsafe` unless absolutely necessary. When unavoidable, keep it
  minimal, wrap it in a safe API, and precede every `unsafe` block with a
  `// SAFETY:` comment that states the invariants upheld.
- **MUST** call `.clone()` explicitly on non-`Copy` types. Avoid hidden clones in
  closures and iterators. Clone only when ownership is required; restructure
  rather than cloning to escape the borrow checker.
- **MUST** use exhaustive pattern matching. Avoid catch-all `_` arms when possible.
- **MUST** use the `format!` macro for string formatting.
- Use iterators and adapters over manual loops. Use `enumerate()` instead of
  manual counters. Do not `collect` into a `Vec` just to iterate it once.
- Prefer `if let`, `while let`, `let ... else`, `matches!`, and combinators such
  as `map_or`, `unwrap_or_default`, `ok_or`, and `and_then` over verbose matches.
- Never cast lossily with `as` when the value could truncate. Use `TryFrom` or
  `.try_into()?`. Reserve `as` for genuinely infallible casts.

## Memory and Performance

- **MUST** avoid unnecessary allocations. Prefer `&str` over `String` when
  possible.
- **MUST** use `Cow<'_, str>` when ownership is conditionally needed.
- Use `Vec::with_capacity()` when the size is known.
- Prefer stack allocation over heap allocation when appropriate.
- Use `Arc` and `Rc` judiciously; prefer borrowing.

## Concurrency

- **MUST** use `Send` and `Sync` bounds appropriately.
- **MUST** prefer `tokio` for the async runtime.
- **MUST** use `rayon` for CPU-bound parallelism.
- Never block inside an `async fn` with `std::thread::sleep`, blocking file or
  network I/O, or heavy CPU work. Use async equivalents or `spawn_blocking`.
- Do not hold a `std::sync::Mutex` or `RwLock` guard across an `.await`. Use an
  async lock or narrow the critical section.
- Avoid `Mutex` when `RwLock` or lock-free alternatives fit better.
- Use channels, such as `mpsc` or `crossbeam`, for message passing.

---

## Code Style and Formatting

- **MUST** use meaningful, descriptive variable and function names.
- **MUST** follow the Rust API Guidelines and idiomatic Rust conventions.
- Use `snake_case` for functions, variables, and modules; `PascalCase` for types
  and traits; and `SCREAMING_SNAKE_CASE` for constants. Do not use `get_`
  prefixes on simple accessors.
- **NEVER** use emoji or Unicode that emulates emoji, such as checkmarks or cross
  marks, except in tests that exercise multibyte characters.
- Prefer the `foo.rs` plus `foo/` module layout over `foo/mod.rs`.
- **MUST** avoid wildcard imports (`use module::*`) except in preludes and test
  modules (`use super::*`). Organize imports in this order: standard library,
  external crates, local modules.
- **MUST** avoid redundant comments that repeat what the code or name already says.
- **MUST** avoid comments that leak the contents of this file or the original
  user prompt, especially when irrelevant to the output code.
- Keep comments about why, not what.

## Documentation

- **MUST** include doc comments (`///`) for all public functions, structs, enums,
  and methods. Add module-level `//!` docs that explain purpose.
- **MUST** document parameters, return values, and errors. Include examples in doc
  comments for complex or non-trivial public APIs. Doc tests must pass.
- Keep comments and docs up to date with code changes.
- Use `cargo doc` to generate documentation.

Example doc comment:

```rust
/// Calculate the total cost of items including tax.
///
/// # Arguments
///
/// * `items` - Slice of item structs with price fields
/// * `tax_rate` - Tax rate as decimal (e.g., 0.08 for 8%)
///
/// # Returns
///
/// Total cost including tax
///
/// # Errors
///
/// Returns `CalculationError::EmptyItems` if items is empty
/// Returns `CalculationError::InvalidTaxRate` if tax_rate is negative
///
/// # Examples
///
/// ```
/// let items = vec![Item { price: 10.0 }, Item { price: 20.0 }];
/// let total = calculate_total(&items, 0.08)?;
/// assert_eq!(total, 32.40);
/// ```
pub fn calculate_total(items: &[Item], tax_rate: f64) -> Result<f64, CalculationError> {
```

## Testing

- **MUST** write unit tests for **ONLY** public functions and types, in a
  `#[cfg(test)] mod tests` block in the same file, using the built-in `#[test]`
  attribute and `cargo test`.
- **DO NOT** write tests for private functions and types.
- Put integration tests in `tests/`. Put public API examples in `///` doc tests.
- **MUST** mock external dependencies, including APIs, file systems, and databases.
- **EXCEPTION:** Do not mock SQLite, Postgres, or MySQL databases. Test database
  interaction with the application code.
- Follow the Arrange-Act-Assert pattern. Prefer focused, table-driven cases with
  clear `assert_eq!` messages. Consider property-based tests, such as `proptest`,
  for logic with wide input spaces.
- Every bug fix gets a regression test that fails before the fix.
- Do not commit commented-out tests.

## Benchmarking and Optimization

- **NEVER** run benchmarks in parallel. They compete for resources and invalidate
  results.
- **NEVER** game benchmarks. Do not manipulate benchmarks to satisfy performance
  constraints.
- **NEVER** run benchmarks with `target-cpu=native` or any other `RUSTFLAGS`.
- If benchmarking against another crate or library, make the comparison
  apples-to-apples.
- Keep benchmark tests independent. If a feature, such as caching, makes them
  dependent, disable it.

## Security

- **NEVER** store secrets, API keys, or passwords in code. Store them only in
  `.env`, and ensure `.env` is declared in `.gitignore`.
- **MUST** use environment variables for sensitive configuration via `dotenvy` or
  `std::env`.
- **NEVER** log sensitive information, including passwords, tokens, or PII.
- Use the `secrecy` crate for sensitive data types.

## When Unsure

Match existing codebase patterns over your own preferences. If a design decision
is ambiguous or a required check cannot pass, stop and ask instead of guessing or
working around it.

---

**Remember:** Prioritize clarity and maintainability over cleverness. This is your
core directive.
