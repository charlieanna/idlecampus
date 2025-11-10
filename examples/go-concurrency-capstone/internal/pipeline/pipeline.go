package pipeline

import (
    "context"
    "sync"

    "examples/go-concurrency-capstone/internal/fetch"
    "examples/go-concurrency-capstone/internal/frontier"
    "examples/go-concurrency-capstone/internal/parse"
    "examples/go-concurrency-capstone/internal/store"
)

// Pipeline wires together Frontier -> Fetcher -> Parser -> Store using a bounded worker pool.
type Pipeline struct {
    Workers int
    Fetcher fetch.Fetcher
    Store   store.Store
}

// Run processes the seed URLs and stops when the frontier is drained.
func (p *Pipeline) Run(ctx context.Context, seeds []string) error {
    if p.Workers <= 0 {
        p.Workers = 2
    }
    f := frontier.New(len(seeds))
    for _, s := range seeds {
        _ = f.Enqueue(s)
    }

    var wg sync.WaitGroup
    wg.Add(p.Workers)
    for i := 0; i < p.Workers; i++ {
        go func() {
            defer wg.Done()
            for u := range f.Channel() {
                // Respect context; in the starter we just pass it down.
                res, err := p.Fetcher.Fetch(ctx, u)
                if err != nil {
                    // In later units, you will introduce structured error wrapping/retries.
                    continue
                }
                links := parse.ExtractLinks(string(res.Body))
                _ = p.Store.Save(store.Page{URL: u, Bytes: len(res.Body), Links: len(links)})
            }
        }()
    }

    // Seeds only variant (no new URLs added yet): close after enqueueing and let workers drain.
    f.Close()
    wg.Wait()
    return nil
}

