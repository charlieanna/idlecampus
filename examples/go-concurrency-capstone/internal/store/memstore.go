package store

import "sync"

// MemStore is a thread-safe in-memory store for Page summaries.
type MemStore struct {
    mu    sync.Mutex
    pages []Page
}

func NewMem() *MemStore { return &MemStore{} }

func (m *MemStore) Save(p Page) error {
    m.mu.Lock()
    m.pages = append(m.pages, p)
    m.mu.Unlock()
    return nil
}

func (m *MemStore) Count() int {
    m.mu.Lock()
    n := len(m.pages)
    m.mu.Unlock()
    return n
}

