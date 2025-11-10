package errorsx

import (
    "errors"
    "fmt"
)

// Sentinel error used to classify not found conditions.
var ErrNotFound = errors.New("not found")

// User represents a tiny domain entity.
type User struct {
    ID   string
    Name string
}

// Repository demonstrates error handling; initially returns plain errors.
type Repository interface {
    FindUser(id string) (*User, error)
}

type memRepo struct{ data map[string]*User }

func NewMemRepo() Repository { return &memRepo{data: map[string]*User{"1": {ID: "1", Name: "Ada"}}} }

// FindUser returns an error without wrapping sentinel (to be refactored by students).
func (r *memRepo) FindUser(id string) (*User, error) {
    if u, ok := r.data[id]; ok {
        return u, nil
    }
    // Exercise: refactor to wrap with ErrNotFound (use: fmt.Errorf("...: %w", ErrNotFound))
    return nil, fmt.Errorf("user %s not found", id)
}

