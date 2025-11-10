# Go Concurrency Capstone (Examples)

A small, self-contained workspace used by the Go course units and labs.

What’s inside
- internal/frontier: URL frontier with deduplication and buffering
- internal/fetch: Fetcher interface + HTTP implementation (ctx-aware)
- internal/parse: Lightweight link extraction (no external deps)
- internal/store: In-memory store implementing a Store interface
- internal/pipeline: Fan-out/fan-in pipeline with bounded workers

Quick start
- Run tests: `go test ./... -count=1`
- Run with race detector: `go test ./... -race -count=1`
- Run specific tests: `go test ./internal/pipeline -run TestPipeline_ProcessesURLs -race`
- Run benchmarks: `go test -bench=. -benchmem ./...`

Notes
- The code favors clarity and testability over cleverness.
- You’ll extend this in the course: add context cancellation, backpressure, retries, error-wrapping, and benchmarks.

