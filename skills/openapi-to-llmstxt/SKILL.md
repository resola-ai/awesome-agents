---
name: openapi-to-llmstxt
description: "Convert OpenAPI JSON specifications to llms.txt format. Use for: generating LLM-friendly documentation from API specs, filtering API documentation by tags, or extracting schema-only documentation for LLM context."
---

# OpenAPI to llms.txt Converter

This skill provides a streamlined workflow for converting complex OpenAPI (Swagger) JSON specifications into the `llms.txt` format, which is optimized for consumption by Large Language Models.

## Workflow

1.  **Obtain OpenAPI JSON**: Ensure you have the local path to the OpenAPI JSON file.
2.  **Identify Requirements**: Determine if the user wants the full API, specific tags, or only the schemas.
3.  **Run Conversion**: Use the provided script to generate the `llms.txt` file.

## Usage

### Full Conversion
To convert the entire OpenAPI spec:
```bash
python3 ./scripts/convert.py input.json llms.txt
```

### Filter by Tags
To include only specific tags (e.g., "Actions", "Users"):
```bash
python3 ./scripts/convert.py input.json llms.txt --tags Actions Users
```

### Schemas Only
To generate a file containing only the data models (schemas) related to specific tags:
```bash
python3 ./scripts/convert.py input.json llms.txt --tags Actions --schemas-only
```

## Script Details
The `convert.py` script handles:
-   **Recursive Schema Resolution**: When `--schemas-only` is used, it automatically finds all nested schemas referenced by the selected endpoints.
-   **llms.txt Compliance**: Generates H1 titles, blockquote summaries, and H2 sections as per the standard.
-   **Optional Section**: Places detailed parameters or full schema definitions in the `## Optional` section to allow for context window management.
