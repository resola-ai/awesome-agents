#!/bin/bash

# markdown_crawl.sh - Fetch web content in markdown format using Cloudflare's Markdown for Agents
# Version: 1.0.0

set -e

# Constants
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
METRICS_FILE="${SCRIPT_DIR}/metrics.json"
USER_AGENT="Claude-Agent/1.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
error() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

info() {
    echo -e "${BLUE}ℹ ${NC}$1" >&2
}

success() {
    echo -e "${GREEN}✓${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1" >&2
}

# Initialize metrics file if it doesn't exist
init_metrics() {
    if [[ ! -f "$METRICS_FILE" ]]; then
        cat > "$METRICS_FILE" <<'EOF'
{
  "total_requests": 0,
  "successful_markdown_requests": 0,
  "failed_requests": 0,
  "total_markdown_tokens": 0,
  "total_html_tokens": 0,
  "total_tokens_saved": 0,
  "html_conversions": 0,
  "converted_markdown_tokens": 0,
  "requests_history": []
}
EOF
        info "Initialized metrics file: $METRICS_FILE"
    fi
}

# Load metrics from JSON file
load_metrics() {
    init_metrics
    cat "$METRICS_FILE"
}

# Save metrics to JSON file
save_metrics() {
    local metrics="$1"
    echo "$metrics" > "$METRICS_FILE"
}

# Extract domain from URL
extract_domain() {
    local url="$1"
    echo "$url" | sed -E 's|^https?://([^/]+).*|\1|'
}

# Estimate token count from text
estimate_tokens() {
    local text="$1"
    local char_count=${#text}
    echo $(( char_count / 4 ))
}

# Extract header value from HTTP response
extract_header() {
    local headers="$1"
    local header_name="$2"
    echo "$headers" | grep -i "^${header_name}:" | head -1 | sed -E "s/^${header_name}: ?//i" | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# Validate URL
validate_url() {
    local url="$1"

    # Add https:// if no protocol specified
    if [[ ! "$url" =~ ^https?:// ]]; then
        url="https://$url"
    fi

    # Basic URL validation
    if [[ ! "$url" =~ ^https?://[a-zA-Z0-9][-a-zA-Z0-9.]*[a-zA-Z0-9] ]]; then
        error "Invalid URL: $url"
    fi

    echo "$url"
}

# Fetch URL with markdown format
fetch_markdown() {
    local url="$1"
    local temp_file=$(mktemp)

    info "Fetching: $url"

    # Make HTTP request
    if ! curl -L -s -i \
        -H "Accept: text/markdown" \
        -H "User-Agent: $USER_AGENT" \
        "$url" > "$temp_file" 2>/dev/null; then
        rm -f "$temp_file"
        error "Failed to fetch URL"
    fi

    echo "$temp_file"
}

# Fetch URL with HTML format
fetch_html() {
    local url="$1"
    local temp_file=$(mktemp)

    info "Fetching HTML version: $url"

    # Make HTTP request
    if ! curl -L -s -i \
        -H "Accept: text/html" \
        -H "User-Agent: $USER_AGENT" \
        "$url" > "$temp_file" 2>/dev/null; then
        rm -f "$temp_file"
        error "Failed to fetch URL"
    fi

    echo "$temp_file"
}

# Parse HTTP response into headers and body
parse_response() {
    local file="$1"
    local output_prefix="$2"

    # Find the blank line separating headers from body
    local blank_line=$(grep -n "^[[:space:]]*$" "$file" 2>/dev/null | head -1 | cut -d: -f1)

    if [[ -z "$blank_line" ]]; then
        blank_line=$(wc -l < "$file")
    fi

    # Extract headers (everything before blank line)
    head -n $((blank_line - 1)) "$file" > "${output_prefix}_headers.txt" 2>/dev/null

    # Extract body (everything after blank line)
    tail -n +$((blank_line + 1)) "$file" > "${output_prefix}_body.txt" 2>/dev/null
}

# Convert HTML to Markdown using Go binary
convert_html_to_markdown() {
    local html_file="$1"
    local converter="${SCRIPT_DIR}/html_to_markdown"

    # Check if converter exists
    if [[ ! -x "$converter" ]]; then
        warning "html_to_markdown binary not found or not executable"
        info "Building converter..."
        if [[ -f "${SCRIPT_DIR}/build.sh" ]]; then
            cd "$SCRIPT_DIR" && bash build.sh
        else
            error "Build script not found. Please install html-to-markdown converter manually."
        fi
    fi

    # Check again after build attempt
    if [[ ! -x "$converter" ]]; then
        error "Failed to build or find html_to_markdown binary"
    fi

    # Convert HTML to Markdown
    local md_file=$(mktemp)
    if cat "$html_file" | "$converter" > "$md_file" 2>/dev/null; then
        echo "$md_file"
    else
        rm -f "$md_file"
        error "Failed to convert HTML to Markdown"
    fi
}

# Update metrics with new request
update_metrics() {
    local url="$1"
    local markdown_tokens="$2"
    local html_tokens="$3"
    local success="$4"
    local content_type="$5"
    local was_converted="${6:-false}"
    local converted_tokens="${7:-0}"

    local metrics=$(load_metrics)
    local domain=$(extract_domain "$url")
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local tokens_saved=0

    if [[ -n "$html_tokens" && "$html_tokens" != "0" ]]; then
        tokens_saved=$((html_tokens - markdown_tokens))
    fi

    # Update counters
    local total_requests=$(echo "$metrics" | jq '.total_requests + 1')
    local failed_requests=$(echo "$metrics" | jq '.failed_requests')
    local successful_requests=$(echo "$metrics" | jq '.successful_markdown_requests')
    local total_md_tokens=$(echo "$metrics" | jq '.total_markdown_tokens')
    local total_html=$(echo "$metrics" | jq '.total_html_tokens')
    local total_saved=$(echo "$metrics" | jq '.total_tokens_saved')
    local html_conversions=$(echo "$metrics" | jq '.html_conversions')
    local converted_md_tokens=$(echo "$metrics" | jq '.converted_markdown_tokens')

    if [[ "$success" == "true" ]]; then
        successful_requests=$((successful_requests + 1))
        total_md_tokens=$((total_md_tokens + markdown_tokens))
    else
        failed_requests=$((failed_requests + 1))
    fi

    if [[ -n "$html_tokens" && "$html_tokens" != "0" ]]; then
        total_html=$((total_html + html_tokens))
        total_saved=$((total_saved + tokens_saved))
    fi

    # Track HTML conversions
    if [[ "$was_converted" == "true" ]]; then
        html_conversions=$((html_conversions + 1))
        converted_md_tokens=$((converted_md_tokens + converted_tokens))
    fi

    # Create new request entry
    local new_entry=$(cat <<EOF
{
  "url": "$url",
  "timestamp": "$timestamp",
  "markdown_tokens": $markdown_tokens,
  "html_tokens": ${html_tokens:-0},
  "tokens_saved": $tokens_saved,
  "success": $success,
  "content_type": "$content_type",
  "domain": "$domain",
  "was_converted": $was_converted,
  "converted_tokens": $converted_tokens
}
EOF
)

    # Update metrics (keep only last 50 requests)
    metrics=$(echo "$metrics" | jq --argjson entry "$new_entry" \
        --arg total "$total_requests" \
        --arg success_count "$successful_requests" \
        --arg failed "$failed_requests" \
        --arg md_tokens "$total_md_tokens" \
        --arg html "$total_html" \
        --arg saved "$total_saved" \
        --arg conversions "$html_conversions" \
        --arg converted "$converted_md_tokens" \
        '.total_requests = ($total | tonumber) |
         .successful_markdown_requests = ($success_count | tonumber) |
         .failed_requests = ($failed | tonumber) |
         .total_markdown_tokens = ($md_tokens | tonumber) |
         .total_html_tokens = ($html | tonumber) |
         .total_tokens_saved = ($saved | tonumber) |
         .html_conversions = ($conversions | tonumber) |
         .converted_markdown_tokens = ($converted | tonumber) |
         .requests_history = ([$entry] + .requests_history)[0:50]')

    save_metrics "$metrics"
    success "Metrics updated"
}

# Command: fetch
cmd_fetch() {
    local url=$(validate_url "$1")
    local temp_file=$(fetch_markdown "$url")

    # Parse response
    parse_response "$temp_file" "/tmp/md"

    local headers=$(cat /tmp/md_headers.txt)
    local body=$(cat /tmp/md_body.txt)
    local content_type=$(extract_header "$headers" "content-type")
    local md_tokens=$(extract_header "$headers" "x-markdown-tokens")

    local was_converted="false"
    local converted_tokens=0
    local final_body="$body"
    local final_tokens=0

    # Display content
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}Content from: ${NC}$url"
    echo -e "${CYAN}Content-Type: ${NC}$content_type"

    # Check if we got markdown or need to convert
    if [[ "$content_type" == *"markdown"* ]]; then
        # Native markdown support
        echo -e "${GREEN}✓ Native Markdown support detected${NC}"
        if [[ -n "$md_tokens" ]]; then
            echo -e "${CYAN}Tokens: ${NC}$md_tokens (from header)"
        fi
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        cat /tmp/md_body.txt
        echo ""

        final_tokens=${md_tokens:-$(estimate_tokens "$body")}
        if [[ -z "$md_tokens" ]]; then
            info "Estimated token count: $final_tokens"
        fi
    else
        # Need to convert HTML to Markdown
        warning "Content not in markdown format (got: $content_type)"
        info "Attempting auto-conversion to markdown..."

        # Fetch HTML and convert
        local html_file=$(fetch_html "$url")
        local md_converted_file=$(convert_html_to_markdown "$html_file")

        if [[ -f "$md_converted_file" ]]; then
            final_body=$(cat "$md_converted_file")
            converted_tokens=$(estimate_tokens "$final_body")

            echo -e "${GREEN}✓ Auto-converted HTML to Markdown${NC}"
            echo -e "${CYAN}Tokens (estimated): ${NC}$converted_tokens"
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo ""
            echo "$final_body"
            echo ""

            was_converted="true"
            final_tokens=$converted_tokens

            rm -f "$html_file" "$md_converted_file"
        else
            error "Failed to convert HTML to Markdown"
        fi
    fi

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Update metrics (pass conversion info)
    local success="true"
    if [[ "$content_type" != *"markdown"* ]]; then
        success="false"
    fi
    update_metrics "$url" "$final_tokens" 0 "$success" "$content_type" "$was_converted" "$converted_tokens"

    # Cleanup
    rm -f "$temp_file" /tmp/md_headers.txt /tmp/md_body.txt
}

# Command: compare
cmd_compare() {
    local url=$(validate_url "$1")

    # Fetch both versions
    local md_file=$(fetch_markdown "$url")
    local html_file=$(fetch_html "$url")

    # Parse responses
    parse_response "$md_file" "/tmp/md"
    parse_response "$html_file" "/tmp/html"

    local md_headers=$(cat /tmp/md_headers.txt)
    local md_body=$(cat /tmp/md_body.txt)
    local html_body=$(cat /tmp/html_body.txt)

    local md_content_type=$(extract_header "$md_headers" "content-type")
    local md_tokens_header=$(extract_header "$md_headers" "x-markdown-tokens")

    # Calculate token counts
    local md_tokens
    if [[ -n "$md_tokens_header" ]]; then
        md_tokens=$md_tokens_header
    else
        md_tokens=$(estimate_tokens "$md_body")
    fi

    local html_tokens=$(estimate_tokens "$html_body")
    local tokens_saved=$((html_tokens - md_tokens))
    local percentage_saved=0

    if [[ $html_tokens -gt 0 ]]; then
        percentage_saved=$(awk "BEGIN {printf \"%.1f\", ($tokens_saved / $html_tokens) * 100}")
    fi

    # Display comparison
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}📊 Markdown vs HTML Comparison${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}URL: ${NC}$url"
    echo ""
    echo -e "${GREEN}Markdown Format:${NC}"
    echo -e "  Tokens: ${GREEN}$md_tokens${NC}"
    echo -e "  Content-Type: $md_content_type"
    echo ""
    echo -e "${YELLOW}HTML Format:${NC}"
    echo -e "  Tokens: ${YELLOW}$html_tokens${NC}"
    echo ""
    echo -e "${BLUE}Token Savings:${NC}"
    echo -e "  Saved: ${GREEN}$tokens_saved tokens${NC}"
    echo -e "  Reduction: ${GREEN}${percentage_saved}%${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${CYAN}Markdown Content:${NC}"
    echo ""
    head -n 50 /tmp/md_body.txt
    if [[ $(wc -l < /tmp/md_body.txt) -gt 50 ]]; then
        echo ""
        echo -e "${YELLOW}... (truncated, showing first 50 lines)${NC}"
    fi
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Update metrics
    local success="true"
    if [[ "$md_content_type" != *"markdown"* ]]; then
        success="false"
    fi

    update_metrics "$url" "$md_tokens" "$html_tokens" "$success" "$md_content_type"

    # Cleanup
    rm -f "$md_file" "$html_file" /tmp/md_headers.txt /tmp/md_body.txt /tmp/html_body.txt
}

# Command: stats
cmd_stats() {
    local metrics=$(load_metrics)

    local total=$(echo "$metrics" | jq -r '.total_requests')
    local successful=$(echo "$metrics" | jq -r '.successful_markdown_requests')
    local failed=$(echo "$metrics" | jq -r '.failed_requests')
    local md_tokens=$(echo "$metrics" | jq -r '.total_markdown_tokens')
    local html_tokens=$(echo "$metrics" | jq -r '.total_html_tokens')
    local saved_tokens=$(echo "$metrics" | jq -r '.total_tokens_saved')
    local html_conversions=$(echo "$metrics" | jq -r '.html_conversions')
    local converted_md_tokens=$(echo "$metrics" | jq -r '.converted_markdown_tokens')

    local success_rate=0
    local avg_tokens=0
    local avg_savings=0

    if [[ $total -gt 0 ]]; then
        success_rate=$(awk "BEGIN {printf \"%.1f\", ($successful / $total) * 100}")
    fi

    if [[ $successful -gt 0 ]]; then
        avg_tokens=$((md_tokens / successful))
    fi

    # Count comparisons (requests with html_tokens > 0)
    local comparison_count=$(echo "$metrics" | jq '[.requests_history[] | select(.html_tokens > 0)] | length')

    if [[ $comparison_count -gt 0 ]]; then
        avg_savings=$((saved_tokens / comparison_count))
    fi

    # Display stats
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}📊 Markdown Crawl Statistics${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${BLUE}Total Requests:${NC} $total"
    echo -e "${GREEN}Successful:${NC} $successful"
    echo -e "${RED}Failed:${NC} $failed"
    echo -e "${BLUE}Success Rate:${NC} ${success_rate}%"
    echo ""
    echo -e "${CYAN}Token Metrics:${NC}"
    echo -e "  Total Markdown Tokens Fetched: ${GREEN}$(printf "%'d" $md_tokens)${NC}"
    echo -e "  Total HTML Tokens (from comparisons): ${YELLOW}$(printf "%'d" $html_tokens)${NC}"
    echo -e "  Total Tokens Saved: ${GREEN}$(printf "%'d" $saved_tokens)${NC}"
    echo -e "  Average Tokens per Request: ${BLUE}$(printf "%'d" $avg_tokens)${NC}"
    echo -e "  Average Savings per Comparison: ${GREEN}$(printf "%'d" $avg_savings)${NC}"
    echo ""
    echo -e "${CYAN}HTML Conversion Metrics:${NC}"
    echo -e "  Total HTML Conversions: ${YELLOW}$html_conversions${NC}"
    echo -e "  Total Tokens (converted): ${GREEN}$(printf "%'d" $converted_md_tokens)${NC}"
    echo ""

    # Recent requests
    echo -e "${CYAN}Recent Requests (last 10):${NC}"
    echo "$metrics" | jq -r '.requests_history[0:10] | to_entries[] |
        "\(.key + 1). \(.value.url) - \(.value.markdown_tokens) tokens" +
        (if .value.tokens_saved > 0 then " (saved \(.value.tokens_saved) tokens)" else "" end) +
        (if .value.was_converted == true then " [converted]" else "" end) +
        " - \(.value.timestamp)"' | while read -r line; do
        echo -e "  ${BLUE}$line${NC}"
    done

    echo ""

    # Top domains
    echo -e "${CYAN}Top Domains:${NC}"
    echo "$metrics" | jq -r '.requests_history | group_by(.domain) |
        map({domain: .[0].domain, count: length}) |
        sort_by(-.count) | .[0:5] |
        to_entries[] | "\(.key + 1). \(.value.domain) - \(.value.count) requests"' | while read -r line; do
        echo -e "  ${GREEN}$line${NC}"
    done

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Command: reset
cmd_reset() {
    echo ""
    echo -e "${YELLOW}⚠  Warning: This will delete all metrics data!${NC}"
    echo -e "Are you sure you want to reset all metrics? ${RED}This cannot be undone.${NC}"
    echo ""
    read -p "Type 'yes' to confirm: " confirm

    if [[ "$confirm" == "yes" ]]; then
        cat > "$METRICS_FILE" <<'EOF'
{
  "total_requests": 0,
  "successful_markdown_requests": 0,
  "failed_requests": 0,
  "total_markdown_tokens": 0,
  "total_html_tokens": 0,
  "total_tokens_saved": 0,
  "html_conversions": 0,
  "converted_markdown_tokens": 0,
  "requests_history": []
}
EOF
        success "Metrics have been reset"
    else
        info "Reset cancelled"
    fi
    echo ""
}

# Show usage
usage() {
    cat <<EOF
Markdown Crawl - Fetch web content in markdown format

Usage:
  $0 fetch <url>              Fetch URL in markdown format
  $0 compare <url>            Compare markdown vs HTML versions
  $0 stats                    Display usage statistics
  $0 reset                    Reset all metrics
  $0 help                     Show this help message

Examples:
  $0 fetch https://blog.cloudflare.com/markdown-for-agents/
  $0 compare https://example.com
  $0 stats
  $0 reset

EOF
}

# Main entry point
main() {
    # Check for jq dependency
    if ! command -v jq &> /dev/null; then
        error "jq is required but not installed. Please install jq first."
    fi

    # Parse command
    local command="${1:-help}"

    case "$command" in
        fetch)
            [[ -z "$2" ]] && error "URL required for fetch command"
            cmd_fetch "$2"
            ;;
        compare)
            [[ -z "$2" ]] && error "URL required for compare command"
            cmd_compare "$2"
            ;;
        stats)
            cmd_stats
            ;;
        reset)
            cmd_reset
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            error "Unknown command: $command\n\nUse '$0 help' for usage information"
            ;;
    esac
}

# Run main function
main "$@"
