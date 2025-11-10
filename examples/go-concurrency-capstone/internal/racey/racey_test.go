package racey

import (
    "sync"
    "testing"

    "examples/go-concurrency-capstone/internal/store"
)

// TestRace_Reproduce triggers concurrent writes to UnsafeStore.
// Run with: go test -race ./examples/go-concurrency-capstone/internal/racey -run TestRace_Reproduce
func TestRace_Reproduce(t *testing.T) {
    s := NewUnsafeStore()
    var wg sync.WaitGroup
    n := 200
    wg.Add(n)
    for i := 0; i < n; i++ {
        go func(i int) {
            defer wg.Done()
            _ = s.Save(store.Page{URL: "u", Bytes: i, Links: 0})
        }(i)
    }
    wg.Wait()

    // No assertion needed; the race detector will fail the test if a race is detected.
    if s.Count() == 0 {
        t.Fatal("unexpected empty store")
    }
}

