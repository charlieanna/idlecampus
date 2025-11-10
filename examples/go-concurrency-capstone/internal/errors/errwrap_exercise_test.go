//go:build exercise

package errorsx

import (
    "errors"
    "testing"
)

// Enable with: go test -tags exercise ./examples/go-concurrency-capstone/internal/errors -run .
func TestErrors_WrappingAndIs(t *testing.T) {
    repo := NewMemRepo()
    if _, err := repo.FindUser("nope"); err == nil {
        t.Fatal("expected error")
    } else {
        // After refactor, this should be true
        if !errors.Is(err, ErrNotFound) {
            t.Fatalf("expected errors.Is(err, ErrNotFound) to be true, got false: %v", err)
        }
    }
}

