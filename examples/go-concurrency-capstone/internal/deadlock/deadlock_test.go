package deadlock

import (
    "testing"
    "time"
)

// TestDeadlock_Reproduce expects TwoMutexDeadlock to NOT complete within the timeout,
// indicating a deadlock scenario.
// Run: go test ./examples/go-concurrency-capstone/internal/deadlock -run TestDeadlock_Reproduce -timeout 2s
func TestDeadlock_Reproduce(t *testing.T) {
    done := make(chan struct{})
    start := make(chan struct{})
    go func() {
        TwoMutexDeadlock(start)
        close(done)
    }()

    select {
    case <-done:
        t.Fatal("expected deadlock; function returned unexpectedly")
    case <-time.After(200 * time.Millisecond):
        // Success: deadlock reproduced (did not finish within timeout)
    }
}

