package parse

import (
    "fmt"
    "strings"
    "testing"
)

func BenchmarkExtractLinks(b *testing.B) {
    // Generate synthetic HTML with N links
    var sb strings.Builder
    for i := 0; i < 500; i++ {
        sb.WriteString(fmt.Sprintf(`<a href="https://example.com/%d">x</a>`, i))
    }
    html := sb.String()
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        _ = ExtractLinks(html)
    }
}

