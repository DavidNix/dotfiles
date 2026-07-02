# AGENTS.md — Rust

Guidance for AI coding agents and contributors working in this repository with the language, Rust.

---

## Core Principles

All code you write MUST be fully optimized. "Fully optimized" includes:

- maximizing algorithmic big-O efficiency for memory and runtime
- using parallelization and SIMD where appropriate
- following proper style conventions for Rust
- no extra code beyond what is absolutely necessary to solve the problem the
  user provides (i.e. no technical debt)
- If a crate can be imported to significantly reduce the amount of new code
required to implement a function at optimal performance, and the crate
itself is small and does not have much overhead, ALWAYS use the crate
instead (see Dependencies below for how to choose one).

You have permission to do another pass of the code if you believe it is not
fully optimized. Prioritize clarity and maintainability over cleverness.

---

## Commands

Use these exact commands; don't invent your own flags.

- Build: `cargo build`
- Run tests: `cargo test --all-features`
- Lint: `cargo clippy --all-targets --all-features -- -D warnings`
- Format: `cargo fmt --all`
- Check formatting only: `cargo fmt --all -- --check`
- Fast type-check: `cargo check --all-targets`

**NEVER** read `Cargo.lock` unless it is extremely relevant: it is large and
usually irrelevant to the task.

## Definition of Done — Before Committing

All of these must pass before you consider a task complete:

- [ ] All tests pass (`cargo test --all-features`), including doc tests
- [ ] No compiler warnings (`cargo build`)
- [ ] Clippy passes (`cargo clippy --all-targets --all-features -- -D warnings`).
      Fix the cause; do not silence lints with blanket `#[allow(...)]`. A
      targeted `allow` with a one-line justification is acceptable only for a
      genuine false positive. Use `-D warnings` in CI, not `#![deny(warnings)]`
      in source.
- [ ] Code is formatted (`cargo fmt --all -- --check`) — default rustfmt style,
      never hand-format
- [ ] New or changed public behavior has tests covering it
- [ ] All public items have doc comments
- [ ] No commented-out code, debug `println!` statements, `dbg!` macros, or
      `todo!()` left in committed code
- [ ] No hardcoded credentials or sensitive data
- [ ] If the project creates a Python package and Rust code is touched, rebuild
      it (`source .venv/bin/activate && maturin develop --release --features python`)
- [ ] If the project creates a WASM package and Rust code is touched, rebuild
      it (`wasm-pack build --target web --out-dir web/pkg`)

If you cannot make a check pass, stop and report why rather than working
around it.

---

## Dependencies

- **When adding a new dependency, consult [blessed.rs](https://blessed.rs)
  first.** It is a curated, community-maintained registry of recommended crates
  by use case. Prefer its recommendation for the problem at hand; deviate only
  when you have a concrete reason (missing feature, incompatibility,
  maintenance status) and state that reason.
- Prefer `std` and existing dependencies before reaching for a new crate.
  Justify any addition (why std/existing deps don't suffice) and pick
  well-maintained, widely-used options.
- Don't bump or add dependencies as a side effect of an unrelated change.
- **MUST** document dependencies in `Cargo.toml` with version constraints.
- Use `cargo` for project management, building, and dependency management.

### Preferred Tools

These defaults are pre-approved (and consistent with blessed.rs picks);
don't shop around when they fit:

- `serde` with `serde_json` for JSON serialization/deserialization.
- `clap` for building clis and commands
- `indicatif` to track long-running operations with progress bars; make the
  message contextually sensitive.
- `tracing::error!` (or `log::error!`) instead of `println!` when reporting
  errors to the console.

---

## Error Handling

- **MUST** use `Result<T, E>` for fallible operations and propagate with `?`.
- **NEVER** use `.unwrap()` in production code paths or library code. Use
  `.expect("why this cannot fail")` only for invariant violations, with a
  message explaining the invariant.
- **MUST** use `thiserror` for defining concrete error types (libraries) and
  `anyhow` for application-level errors. Don't leak `anyhow` across a public
  library API.
- Provide meaningful error messages with context via `.context("what we were
  doing")` at boundaries.
- Never discard a `Result` silently. `let _ = ...;` only when ignoring is
  deliberate, with a comment saying why.

## Type System

- **MUST** leverage Rust's type system to prevent bugs at compile time: model
  state with `enum`s and make illegal states unrepresentable.
- Use newtypes (`struct UserId(u64)`) to distinguish semantically different
  values of the same underlying type; don't stringly-type data that has a
  natural enum/newtype representation.
- Prefer `Option<T>` over sentinel values.
- Prefer `From` / `TryFrom` for conversions and implement `Display` for
  user-facing types; don't write ad-hoc `to_x()` methods when a trait fits.
- Add `#[must_use]` to functions whose return value should not be ignored, and
  consider `#[non_exhaustive]` for public types/enums that may grow.

## Function Design

- **MUST** keep functions focused on a single responsibility.
- **MUST** prefer borrowing (`&T`, `&mut T`) over ownership when possible.
- Accept the widest reasonable argument type: `&str` over `&String`, `&[T]`
  over `&Vec<T>`, `impl AsRef<Path>` over `&Path` for public helpers. Return
  owned values; never return references borrowed from function locals.
- Limit function parameters to 5 or fewer; use a config struct for more.
- Return early to reduce nesting.
- Use iterators and combinators over explicit loops where clearer.

## Struct and Enum Design

- **MUST** keep types focused on a single responsibility.
- **MUST** derive common traits: `Debug` on almost everything; `Clone`,
  `PartialEq`, `Eq`, `Hash` where appropriate; `#[derive(Default)]` when a
  sensible default exists.
- Use composition over inheritance-like patterns.
- Use the builder pattern for complex struct construction / many optional
  fields.
- Make fields private by default; provide accessor methods when needed. Keep
  visibility minimal (`pub(crate)` for internal sharing; smallest public
  surface that works).

## Rust Best Practices

- **NEVER** use `unsafe` unless absolutely necessary. When unavoidable, keep it
  minimal, wrap it in a safe API, and precede every `unsafe` block with a
  `// SAFETY:` comment stating the invariants upheld.
- **MUST** call `.clone()` explicitly on non-`Copy` types; avoid hidden clones
  in closures and iterators. Clone only when ownership is actually required —
  restructure rather than cloning to escape the borrow checker.
- **MUST** use pattern matching exhaustively; avoid catch-all `_` arms when
  possible.
- **MUST** use the `format!` macro for string formatting.
- Use iterators and adapters over manual loops; use `enumerate()` instead of
  manual counters; don't `collect` into a `Vec` just to iterate it once more.
- Prefer `if let` / `while let` / `let ... else` / `matches!` and combinators
  (`map_or`, `unwrap_or_default`, `ok_or`, `and_then`) over verbose matches.
- Never cast lossily with `as` when the value could truncate; use
  `TryFrom` / `.try_into()?`. Reserve `as` for genuinely infallible casts.

## Memory and Performance

- **MUST** avoid unnecessary allocations; prefer `&str` over `String` when
  possible.
- **MUST** use `Cow<'_, str>` when ownership is conditionally needed.
- Use `Vec::with_capacity()` when the size is known.
- Prefer stack allocation over heap when appropriate.
- Use `Arc` and `Rc` judiciously; prefer borrowing.

## Concurrency

- **MUST** use `Send` and `Sync` bounds appropriately.
- **MUST** prefer `tokio` for the async runtime.
- **MUST** use `rayon` for CPU-bound parallelism.
- Never block inside an `async fn` (`std::thread::sleep`, blocking file/network
  I/O, heavy CPU) — use async equivalents or `spawn_blocking`.
- Don't hold a `std::sync::Mutex`/`RwLock` guard across an `.await`; use an
  async lock or narrow the critical section.
- Avoid `Mutex` when `RwLock` or lock-free alternatives are appropriate.
- Use channels (`mpsc`, `crossbeam`) for message passing.

---

## Code Style and Formatting

- **MUST** use meaningful, descriptive variable and function names.
- **MUST** follow the Rust API Guidelines and idiomatic Rust conventions.
- Use `snake_case` for functions/variables/modules, `PascalCase` for
  types/traits, `SCREAMING_SNAKE_CASE` for constants. No `get_` prefixes on
  simple accessors.
- **NEVER** use emoji, or unicode that emulates emoji (e.g. ✓, ✗), except when
  writing tests that exercise multibyte characters.
- Prefer the `foo.rs` + `foo/` module layout over `foo/mod.rs`.
- **MUST** avoid wildcard imports (`use module::*`) except preludes and test
  modules (`use super::*`). Organize imports: standard library, external
  crates, local modules.
- **MUST** avoid redundant comments that are tautological or self-demonstrating
  — if the code or its name already says it, the comment just wastes time.
- **MUST** avoid comments that leak the contents of this file or the original
  user prompt, ESPECIALLY when irrelevant to the output code.
- Keep comments about *why*, not *what*.

## Documentation

- **MUST** include doc comments (`///`) for all public functions, structs,
  enums, and methods; add module-level `//!` docs explaining purpose.
- **MUST** document parameters, return values, and errors; include examples in
  doc comments for complex or non-trivial public APIs (doc tests must pass).
- Keep comments and docs up to date with code changes.
- Use `cargo doc` for generating documentation.

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
- Integration tests go in `tests/`; public API examples go in `///` doc tests.
- **MUST** mock external dependencies (APIs, file systems, databases)
- **EXCEPTION** do not mock sqlite, postgres, or mysql databases. Test the database inteaction with the application code.
- Follow the Arrange-Act-Assert pattern; prefer focused, table-driven cases
  with clear `assert_eq!` messages. Consider property-based tests (e.g.
  `proptest`) for logic with wide input spaces.
- Every bug fix gets a regression test that fails before the fix.
- Do not commit commented-out tests.

## Benchmarking and Optimization

- **NEVER** run benchmarks in parallel — they compete for resources and the
  results will be invalid.
- **NEVER** game the benchmarks. Do not manipulate the benchmarks themselves to
  satisfy any required performance constraints.
- **NEVER** run benchmarks with `target-cpu=native` or any other `RUSTFLAGS`.
- If benchmarking against another crate or library, ensure the comparison is
  apples-to-apples.
- Ensure benchmark tests are independent; if a feature (e.g. caching) makes
  them dependent, disable it.

## Security

- **NEVER** store secrets, API keys, or passwords in code. Only store them in
  `.env`, and ensure `.env` is declared in `.gitignore`.
- **MUST** use environment variables for sensitive configuration via `dotenvy`
  or `std::env`.
- **NEVER** log sensitive information (passwords, tokens, PII).
- Use the `secrecy` crate for sensitive data types.

## When Unsure

Match existing patterns in the codebase over your own preferences. If a design
decision is ambiguous or a required check can't pass, stop and ask rather than
guessing or working around it.

---

**Remember:** Prioritize clarity and maintainability over cleverness. This is
your core directive.
