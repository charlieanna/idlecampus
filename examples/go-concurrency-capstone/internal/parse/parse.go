package parse

import (
    "regexp"
)

var hrefRe = regexp.MustCompile(`(?i)href\s*=\s*"([^"]+)"`)

// ExtractLinks returns a slice of absolute http(s) links found in HTML.
// This is intentionally simple and dependency-free for course use.
func ExtractLinks(html string) []string {
    matches := hrefRe.FindAllStringSubmatch(html, -1)
    out := make([]string, 0, len(matches))
    for _, m := range matches {
        if len(m) < 2 {
            continue
        }
        href := m[1]
        if isHTTP(href) {
            out = append(out, href)
        }
    }
    return out
}

func isHTTP(s string) bool {
    return len(s) > 7 && (s[:7] == "http://" || (len(s) > 8 && s[:8] == "https://"))
}

