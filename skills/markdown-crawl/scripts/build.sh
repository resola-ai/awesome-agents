#!/bin/bash

# Build script for html_to_markdown Go binary

cd "$(dirname "$0")"

# Initialize Go module if it doesn't exist
if [[ ! -f "go.mod" ]]; then
    go mod init html-to-markdown-cli
fi

# Get the required dependency
echo "Installing html-to-markdown dependency..."
go get github.com/JohannesKaufmann/html-to-markdown/v2@latest

# Build the binary
echo "Building html_to_markdown binary..."
go build -o html_to_markdown html_to_markdown.go

# Make it executable
chmod +x html_to_markdown

echo "html_to_markdown binary built successfully"
