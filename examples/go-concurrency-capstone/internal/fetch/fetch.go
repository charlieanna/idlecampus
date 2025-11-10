package fetch

import (
    "context"
    "errors"
    "io"
    "net/http"
    "time"
)

// Result represents a fetch outcome.
type Result struct {
    URL         string
    StatusCode  int
    Body        []byte
    ContentType string
}

// Fetcher defines an interface for retrievers.
type Fetcher interface {
    Fetch(ctx context.Context, url string) (Result, error)
}

// HTTPFetcher is a simple HTTP client based Fetcher.
type HTTPFetcher struct {
    Client *http.Client
}

// NewHTTP returns an HTTPFetcher with a sane timeout if none provided.
func NewHTTP() *HTTPFetcher {
    return &HTTPFetcher{Client: &http.Client{Timeout: 10 * time.Second}}
}

// Fetch fetches the given URL with context.
func (h *HTTPFetcher) Fetch(ctx context.Context, url string) (Result, error) {
    req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
    if err != nil {
        return Result{}, err
    }
    resp, err := h.Client.Do(req)
    if err != nil {
        return Result{}, err
    }
    defer resp.Body.Close()
    b, err := io.ReadAll(resp.Body)
    if err != nil {
        return Result{}, err
    }
    if resp.StatusCode < 200 || resp.StatusCode >= 300 {
        return Result{}, errors.New(resp.Status)
    }
    ct := resp.Header.Get("Content-Type")
    return Result{URL: url, StatusCode: resp.StatusCode, Body: b, ContentType: ct}, nil
}

