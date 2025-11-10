# Go Course Teaching Upgrade Plan

Status: In Progress
Owner: Curriculum/Engineering
Last Updated: 2025-11-06

## Objectives
- Anchor concurrency learning in a single capstone built across modules.
- Add purposeful race/deadlock hunts with -race and guided fixes.
- Introduce refactor-to-interfaces + idiomatic Go units with table-driven tests and benchmarks.
- Teach error-handling patterns (sentinel, wrapping, errors.Is/As) with guided refactors.

## Scope (Phase 1)
- Course: `golang-fundamentals`
- Affects: seeds, interactive units, mini-labs, and example code repo (new) used by lessons/tests.

## Deliverables
- Capstone project (crawler/pipeline/worker-pool) with staged milestones and tests.
- 6–8 InteractiveLearningUnits (ILUs) + 2 mini-labs + 1 capstone lab.
- Table-driven tests, race/deadlock reproductions, and benchmarks.
- Error-handling refactor exercises with passing tests.

## Repository Changes
- New example code workspace for students:
  - `examples/go-concurrency-capstone/` (standalone Go module with code, tests, benches)
- Seeds linking new ILUs/labs to course:
  - `backend/db/seeds/golang_concurrency_units.rb`
  - Wire into `backend/db/seeds/golang_course_enhanced.rb`

## Capstone Design
- Theme: Web crawler pipeline with bounded worker pool and backpressure.
- Stages:
  1) Frontier (URL queue with dedupe + rate limit)
  2) Fetch (HTTP client with context cancellation)
  3) Parse (extract links + content stats)
  4) Persist (store summaries in memory; interface for swap-out)
- Concurrency features: fan-out/fan-in, bounded workers, contexts, timeouts, cancellation, backpressure.
- Testing targets: deterministic seeds, fakes, table-driven tests, -race clean, benchmarks for fetch/parse.

## Teaching Units (ILUs) & Labs
- Unit 1: Goroutines & Channels — build a bounded worker pool (intro). [ILU]
- Unit 2: Fan-out/Fan-in Pipeline — build fetch→parse pipeline with channels. [ILU]
- Unit 3: Contexts & Cancellation — graceful shutdown and timeouts. [ILU]
- Lab A: Assemble MVP crawler (N pages with max concurrency & deadline). [Lab]
- Unit 4: Race Hunt — introduce a data race; detect with `go test -race`; fix via mutex/ch pattern. [ILU]
- Unit 5: Deadlock Hunt — create/diagnose deadlock; fix ordering/select timeouts. [ILU]
- Unit 6: Interfaces & Testability — refactor Fetcher/Parser/Store to interfaces + DI; stub/fake in tests. [ILU]
- Unit 7: Table-Driven Tests & Benchmarks — subtests, -run filters, benchmarks. [ILU]
- Unit 8: Error Handling — sentinel vs wrapped errors; errors.Is/As; custom types; refactor exercises. [ILU]
- Lab B: Capstone hardening — run -race clean; add retries, backoff, and structured errors. [Lab]

## Assessment & Acceptance Criteria
- All ILU tasks have unit tests students must pass.
- Race/deadlock hunts reproducible on command; fixes verified by CI (`go test ./... -race`).
- Capstone hits targets (pages crawled, concurrency bound, deterministic shutdown) and is -race clean.
- Error-handling refactor passes tests using `errors.Is/As` and preserves error semantics.
- Benchmarks present, non-flaky locally, and demonstrate performance impact of changes.

## Implementation Checklist
- [ ] Create example module: `examples/go-concurrency-capstone` (go.mod, packages, README)
- [ ] Implement baseline worker pool and pipeline skeleton with tests
- [ ] Add ILU 1–3 seeds and link to course
- [ ] Add Lab A seed (MVP crawler)
- [ ] Add race hunt scenario + test that fails under `-race`; add fixed variant
- [ ] Add deadlock scenario + diagnosis guide; add fixed variant
- [ ] Refactor to interfaces; add DI-friendly constructors; update tests
- [ ] Add table-driven tests across packages; add benchmarks
- [ ] Add error-handling unit (wrapping, sentinel, Is/As) + guided refactor tasks
- [ ] Add Lab B (capstone hardening) + acceptance tests; ensure `-race` passes
- [ ] Wire units/labs into `golang-fundamentals` course modules (sequences, objectives)

## Testing & Tooling
- Commands:
  - `go test ./... -race -count=1`
  - `go test ./... -run TestRace -race` (race hunt)
  - `go test ./... -run TestDeadlock -timeout 5s` (deadlock hunt)
  - `go test -bench=. -benchmem ./...`
- CI (future): add a lightweight job to run -race and benches (optional warmup).

## Mapping to Course Modules (proposed)
- Module: Go Concurrency Fundamentals → Units 1–3 + Lab A
- Module: Concurrency Safety & Testing → Units 4–7
- Module: Robust Go in Production → Unit 8 + Lab B

## Next Actions (Phase 1 Sprint)
1) Scaffold `examples/go-concurrency-capstone` with packages: frontier, fetch, parse, store, pipeline.
2) Ship ILUs 1–3 with runnable tasks and tests; add Lab A.
3) Add race and deadlock hunts + fixes with clear guidance.

## Notes
- Keep code idiomatic (Effective Go); prefer channels over shared state unless justified.
- Ensure examples are small, runnable, and directly connected to ILU prompts.

