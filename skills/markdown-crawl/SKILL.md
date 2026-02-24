---
name: markdown-crawl
description: Fetch web content in markdown format using Cloudflare's Markdown for Agents feature. Use when fetching web pages, documentation sites, or converting HTML to markdown. Tracks metrics like token savings and usage statistics.
disable-model-invocation: false
metadata:
  version: "2.0.0"
  author: ""
  tags: ["web", "markdown", "fetch", "cloudflare", "metrics", "crawl", "auto-convert"]
  license: ""
compatibility: "Requires curl, jq, and Go (for html_to_markdown binary)"
---

# Markdown Crawl

## When to Use

- Use this skill when you need to fetch web content in markdown format
- When comparing markdown vs HTML token efficiency
- When tracking web fetch metrics and token savings
- For research, documentation fetching, or content analysis
- When working with Cloudflare-backed websites that support Markdown for Agents

## Background

Cloudflare announced "Markdown for Agents" in February 2026, allowing AI agents to request web content in markdown format instead of HTML. This provides:

- **Cleaner content**: No HTML tags, JavaScript, or styling to parse
- **Token efficiency**: Markdown uses significantly fewer tokens than HTML
- **Better AI processing**: Structured content that's easier for agents to understand
- **Standardized format**: Consistent markdown output across different websites

Learn more: [Cloudflare - Markdown for Agents](https://blog.cloudflare.com/markdown-for-agents/)

## Instructions

This skill uses a standalone bash script located at `skills/markdown_crawl/scripts/markdown_crawl.sh` that handles all functionality.

### Command Modes

**1. Fetch Markdown (`/markdown_crawl <url>`)**
- Fetch content from the specified URL using markdown format
- Track metrics for each request

**2. Compare Mode (`/markdown_crawl <url> --compare`)**
- Fetch both markdown AND HTML versions
- Calculate and display token savings
- Track detailed comparison metrics

**3. Stats Mode (`/markdown_crawl stats`)**
- Display comprehensive usage statistics
- Show token savings and success rates
- List recent requests

**4. Reset Mode (`/markdown_crawl reset`)**
- Clear all metrics data
- Requires user confirmation

### Implementation

The skill uses a standalone bash script that handles all operations. Simply call the script with the appropriate command:

#### Fetch Mode

When the user provides a URL (e.g., `/markdown_crawl https://example.com`):

```bash
skills/markdown_crawl/scripts/markdown_crawl.sh fetch <url>
```

This will:
- Fetch the URL in markdown format
- Display the content with metadata
- Automatically track metrics

**Fallback Strategy (Auto-Conversion):**

If the website doesn't support the `Accept: text/markdown` header, the script will **automatically** fetch the HTML version and convert it to markdown using the Go binary (`html_to_markdown`):

1. The script detects non-markdown content (Content-Type != text/markdown)
2. Automatically fetches HTML version of the page
3. Uses the `html_to_markdown` binary to convert HTML → Markdown
4. Displays the converted content with "Auto-converted HTML to Markdown" indicator
5. Tracks conversion in metrics for later analysis

This ensures:
- ✅ Content is always available in markdown format
- ✅ Works with ALL websites (no manual fallback needed)
- ✅ Tracks conversion statistics for optimization
- ✅ No need for external MCP tools like WebFetch

#### Compare Mode

When the user provides a URL with `--compare` flag (e.g., `/markdown_crawl https://example.com --compare`):

```bash
skills/markdown_crawl/scripts/markdown_crawl.sh compare <url>
```

This will:
- Fetch both markdown and HTML versions
- Calculate token savings
- Display a comparison with statistics
- Track detailed metrics

#### Stats Mode

When the user requests stats (e.g., `/markdown_crawl stats`):

```bash
skills/markdown_crawl/scripts/markdown_crawl.sh stats
```

This will display comprehensive usage statistics including:
- Total requests and success rate
- Token metrics (markdown, HTML, savings)
- Recent request history
- Top domains by request count

#### Reset Mode

When the user requests reset (e.g., `/markdown_crawl reset`):

```bash
skills/markdown_crawl/scripts/markdown_crawl.sh reset
```

This will:
- Prompt for confirmation (the script handles this interactively)
- Reset all metrics if confirmed
- Display confirmation message

## Script Features

The bash script (`markdown_crawl.sh`) automatically handles:

✅ **URL Validation**: Adds https:// if missing, validates format
✅ **HTTP Requests**: Uses proper headers (`Accept: text/markdown`)
✅ **Response Parsing**: Extracts headers and body, handles `x-markdown-tokens`
✅ **Token Calculation**: Uses header values or estimates (char_count / 4)
✅ **Metrics Tracking**: Maintains persistent JSON metrics file
✅ **Error Handling**: Clear error messages, graceful failure handling
✅ **Colored Output**: User-friendly colored terminal output
✅ **History Management**: Keeps last 50 requests to prevent file bloat
✅ **Auto HTML-to-Markdown**: Automatically converts HTML to markdown when native support unavailable

## HTTP Headers

**Request:**
```
Accept: text/markdown
User-Agent: Claude-Agent/1.0
```

**Response (when supported):**
```
Content-Type: text/markdown; charset=utf-8
X-Markdown-Tokens: 725
Content-Signal: ai-train=yes, search=yes, ai-input=yes
```

## Dependencies

The script requires:
- `curl` - For HTTP requests
- `jq` - For JSON parsing and manipulation
- `go` (optional) - For building the html_to_markdown converter

**Optional**: The `html_to_markdown` binary is pre-built and included in `scripts/`. If missing, the script will attempt to build it automatically using the `build.sh` script.

If `jq` is not installed, the script will display an error message.

### Building the HTML to Markdown Converter

The `html_to_markdown` binary is pre-built for Linux AMD64. If you need to rebuild it or build for a different platform:

```bash
cd skills/markdown_crawl/scripts
bash build.sh
```

This will:
1. Initialize a Go module (if not present)
2. Download the html-to-markdown library
3. Build the binary

The converter uses the `github.com/JohannesKaufmann/html-to-markdown/v2` library.

## Error Handling

The script handles errors gracefully:
- Invalid URLs: Clear error message
- Network failures: Curl error reporting
- Missing dependencies: Helpful installation guidance
- Malformed metrics: Auto-recreates metrics file

## Examples

### Example 1: Fetch Documentation

```bash
/markdown_crawl https://blog.cloudflare.com/markdown-for-agents/
```

**Output:**
- Markdown content from the page
- Token count: 725 tokens
- Metrics updated confirmation

### Example 2: Compare Token Efficiency

```bash
/markdown_crawl https://docs.example.com/guide --compare
```

**Output:**
```
📊 Comparison Results
===================
Markdown Tokens: 450
HTML Tokens: 1,250
Tokens Saved: 800 (64% reduction)
```

### Example 3: View Usage Statistics

```bash
/markdown_crawl stats
```

**Output:**
```
📊 Markdown Crawl Statistics
============================

Total Requests: 42
Successful: 38
Failed: 4
Success Rate: 90.5%

Token Metrics:
- Total Markdown Tokens Fetched: 28,450
- Total HTML Tokens (from comparisons): 54,230
- Total Tokens Saved: 25,780
- Average Tokens per Request: 748
- Average Savings per Comparison: 1,289

HTML Conversion Metrics:
- Total HTML Conversions: 12
- Total Tokens (converted): 8,450

Recent Requests (last 10):
1. https://example.com - 725 tokens - 2026-02-15
2. https://example.com - 450 tokens [converted] - 2026-02-15
...
```

**Output:**
```
📊 Markdown Crawl Statistics
============================

Total Requests: 42
Successful: 38
Failed: 4
Success Rate: 90.5%

Token Metrics:
- Total Markdown Tokens Fetched: 28,450
- Total HTML Tokens (from comparisons): 54,230
- Total Tokens Saved: 25,780
- Average Tokens per Request: 748
- Average Savings per Comparison: 1,289
```

### Example 4: Reset Metrics

```bash
/markdown_crawl reset
```

The script will prompt for confirmation before clearing all data.

## Best Practices

1. **Use with supported sites**: Check if the site is behind Cloudflare for best results
2. **Compare mode**: Use `--compare` occasionally to measure actual savings
3. **Check stats**: Run `/markdown_crawl stats` to see your token efficiency
4. **Domain tracking**: Stats show which domains you fetch from most often
5. **Auto-conversion**: The script automatically handles non-markdown sites - no manual fallback needed

## Limitations

- Native markdown support requires websites to support Cloudflare's Markdown for Agents
- Non-supported sites are automatically converted (tracked in metrics)
- Request history is limited to last 50 requests to prevent file bloat
- Token estimates for HTML may not be exact (uses approximation)
- Conversion requires the `html_to_markdown` Go binary (included in scripts/)

## Metrics Storage

Metrics are stored in `skills/markdown_crawl/metrics.json`:

```json
{
  "total_requests": 42,
  "successful_markdown_requests": 38,
  "failed_requests": 4,
  "total_markdown_tokens": 28450,
  "total_html_tokens": 54230,
  "total_tokens_saved": 25780,
  "html_conversions": 12,
  "converted_markdown_tokens": 8450,
  "requests_history": [...]
}
```

Each request entry includes:
- URL and domain
- Timestamp
- Token counts (markdown and HTML if compared)
- Tokens saved
- Success status
- Content type received
- Was converted (boolean) - indicates if HTML was converted to markdown
- Converted tokens - token count for converted content

## Troubleshooting

**Problem:** html_to_markdown binary not found or not executable
- **Solution**: Run `bash build.sh` in the scripts directory to build the binary

**Problem:** Site doesn't return markdown
- **Solution**: Not all sites support this feature. The script will automatically convert HTML to markdown instead.

**Problem:** Token count not showing
- **Solution**: Server may not provide `X-Markdown-Tokens` header. This is optional.

**Problem:** Metrics file corrupted
- **Solution**: The skill will auto-recreate it on next request.

**Problem:** `jq` not found
- **Solution**: Install jq: `sudo apt install jq` (Ubuntu/Debian) or `brew install jq` (macOS)

**Problem:** Go build fails
- **Solution**: Ensure Go is installed: `go version`. Install via https://go.dev/doc/install

## References

- [Cloudflare: Markdown for Agents](https://blog.cloudflare.com/markdown-for-agents/)
- [Cloudflare Docs: Markdown for Agents](https://developers.cloudflare.com/fundamentals/reference/markdown-for-agents/)
- [Changelog: Introducing Markdown for Agents](https://developers.cloudflare.com/changelog/2026-02-12-markdown-for-agents/)
