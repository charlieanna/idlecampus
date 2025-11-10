package deadlock

import "sync"

// TwoMutexDeadlock demonstrates classic lock-order inversion deadlock.
// DO NOT USE in production; for teaching only.
func TwoMutexDeadlock(start chan struct{}) {
    var a, b sync.Mutex
    var wg sync.WaitGroup
    wg.Add(2)

    go func() {
        defer wg.Done()
        <-start
        a.Lock()
        defer a.Unlock()
        // Simulate work then attempt to lock b (may deadlock)
        b.Lock()
        b.Unlock()
    }()

    go func() {
        defer wg.Done()
        <-start
        b.Lock()
        defer b.Unlock()
        a.Lock()
        a.Unlock()
    }()

    // Signal both goroutines to start competing for locks
    close(start)
    // If deadlocked, Wait never returns.
    wg.Wait()
}

