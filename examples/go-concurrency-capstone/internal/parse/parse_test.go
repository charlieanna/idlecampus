package parse

import "testing"

func TestExtractLinks_Table(t *testing.T) {
    cases := []struct {
        name string
        html string
        want int
    }{
        {"none", "<p>No links</p>", 0},
        {"one", `<a href="https://example.com">x</a>`, 1},
        {"two", `<a href="https://a.com"></a><a href="http://b.com"></a>`, 2},
        {"ignore relative", `<a href="/about"></a>`, 0},
    }
    for _, tc := range cases {
        t.Run(tc.name, func(t *testing.T) {
            got := ExtractLinks(tc.html)
            if len(got) != tc.want {
                t.Fatalf("want %d links, got %d (%v)", tc.want, len(got), got)
            }
        })
    }
}

