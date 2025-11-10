package pipeline

import (
    "context"
    "testing"
    "time"

    "examples/go-concurrency-capstone/internal/fetch"
    "examples/go-concurrency-capstone/internal/store"
)

type fakeFetcher struct{}

func (f fakeFetcher) Fetch(ctx context.Context, url string) (fetch.Result, error) {
    // Simulate small work and be context-aware for future cancellation tests.
    select {
    case <-time.After(5 * time.Millisecond):
    case <-ctx.Done():
        return fetch.Result{}, ctx.Err()
    }
    body := "<html><a href=\"https://example.com\">x</a></html>"
    return fetch.Result{URL: url, StatusCode: 200, Body: []byte(body), ContentType: "text/html"}, nil
}

func TestPipeline_ProcessesURLs(t *testing.T) {
    p := &Pipeline{
        Workers: 2,
        Fetcher: fakeFetcher{},
        Store:   store.NewMem(),
    }
    ctx, cancel := context.WithTimeout(context.Background(), time.Second)
    defer cancel()

    seeds := []string{"https://a.com", "https://b.com", "https://c.com"}
    if err := p.Run(ctx, seeds); err != nil {
        t.Fatalf("run error: %v", err)
    }
    if got := p.Store.Count(); got != len(seeds) {
        t.Fatalf("want %d stored pages, got %d", len(seeds), got)
    }
}

