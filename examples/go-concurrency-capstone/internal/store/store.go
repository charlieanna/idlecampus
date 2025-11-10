package store

// Page represents a minimal page summary stored by the pipeline.
type Page struct {
    URL   string
    Bytes int
    Links int
}

// Store is an interface that persists page summaries.
type Store interface {
    Save(p Page) error
    Count() int
}

