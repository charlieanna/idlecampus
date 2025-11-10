package frontier

import "testing"

func TestFrontier_Deduplicates(t *testing.T) {
    f := New(4)

    if !f.Enqueue("https://a.com") {
        t.Fatal("first enqueue should succeed")
    }
    if f.Enqueue("https://a.com") {
        t.Fatal("duplicate should not enqueue")
    }
    if !f.Enqueue("https://b.com") {
        t.Fatal("second distinct enqueue should succeed")
    }

    // Drain
    got := map[string]bool{}
    for i := 0; i < 2; i++ {
        u := <-f.Channel()
        got[u] = true
    }
    if !got["https://a.com"] || !got["https://b.com"] {
        t.Fatalf("unexpected content: %#v", got)
    }
}

