package racey

import "examples/go-concurrency-capstone/internal/store"

// UnsafeStore intentionally lacks synchronization to demonstrate data races.
type UnsafeStore struct {
    pages []store.Page
}

func NewUnsafeStore() *UnsafeStore { return &UnsafeStore{} }

func (m *UnsafeStore) Save(p store.Page) error {
    // Intentional race point: no locking.
    m.pages = append(m.pages, p)
    return nil
}

func (m *UnsafeStore) Count() int {
    // Intentional race point: no locking.
    return len(m.pages)
}

