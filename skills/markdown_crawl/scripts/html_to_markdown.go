package main

import (
	"fmt"
	"io"
	"os"

	"github.com/JohannesKaufmann/html-to-markdown/v2"
)

func main() {
	// Read HTML from stdin
	html, err := io.ReadAll(os.Stdin)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error reading stdin: %v\n", err)
		os.Exit(1)
	}

	// Convert HTML to Markdown
	markdown, err := htmltomarkdown.ConvertString(string(html))
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error converting HTML to Markdown: %v\n", err)
		os.Exit(1)
	}

	// Output markdown to stdout
	fmt.Print(markdown)
}
