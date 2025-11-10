package frontier

import (
    "sync"
)

// Frontier provides a deduplicating queue of URLs.
// It is safe for concurrent use by multiple goroutines.
type Frontier struct {
    mu    sync.Mutex
    seen  map[string]struct{}
    ch    chan string
    closed bool
}

// New creates a new Frontier with a buffered channel.
func New(buffer int) *Frontier {
    if buffer <= 0 {
        buffer = 1
    }
    return &Frontier{
        seen: make(map[string]struct{}),
        ch:   make(chan string, buffer),
    }
}

// Enqueue adds a URL if not seen before. Returns true if enqueued.
func (f *Frontier) Enqueue(url string) bool {
    f.mu.Lock()
    defer f.mu.Unlock()
    if f.closed {
        return false
    }
    if _, ok := f.seen[url]; ok {
        return false
    }
    f.seen[url] = struct{}{}
    f.ch <- url
    return true
}

// Channel exposes a receive-only channel for consumers.
func (f *Frontier) Channel() <-chan string { return f.ch }

// Close stops further enqueueing and closes the channel once drained.
func (f *Frontier) Close() {
    f.mu.Lock()
    if f.closed {
        f.mu.Unlock()
        return
    }
    f.closed = true
    f.mu.Unlock()
    close(f.ch)
}

