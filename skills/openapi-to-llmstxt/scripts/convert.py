import json
import argparse
from pathlib import Path

def extract_refs(obj, refs_set):
    if isinstance(obj, dict):
        for k, v in obj.items():
            if k == '$ref':
                name = v.split('/')[-1]
                refs_set.add(name)
            else:
                extract_refs(v, refs_set)
    elif isinstance(obj, list):
        for item in obj:
            extract_refs(item, refs_set)

def convert(json_path, output_path, tag_filter=None, schemas_only=False):
    with open(json_path, 'r') as f:
        spec = json.load(f)

    info = spec.get('info', {})
    title = info.get('title', 'API Documentation')
    version = info.get('version', '')
    description = info.get('description', '')
    paths = spec.get('paths', {})
    components = spec.get('components', {})
    schemas = components.get('schemas', {})

    lines = []
    lines.append(f"# {title} {version}".strip())
    lines.append("")
    lines.append(f"> {description or f'OpenAPI specification for {title}'}")
    lines.append("")

    if schemas_only:
        # Identify relevant schemas
        relevant_schemas = set()
        for path, methods in paths.items():
            for method, details in methods.items():
                if not tag_filter or any(tag in details.get('tags', []) for tag in tag_filter):
                    extract_refs(details, relevant_schemas)
        
        # Recursive expansion
        checked = set()
        to_check = list(relevant_schemas)
        while to_check:
            current = to_check.pop()
            if current in checked: continue
            checked.add(current)
            if current in schemas:
                extract_refs(schemas[current], relevant_schemas)
                for r in relevant_schemas:
                    if r not in checked: to_check.append(r)

        lines.append("## Schemas")
        lines.append("")
        sorted_names = sorted(list(relevant_schemas))
        for name in sorted_names:
            if name in schemas:
                lines.append(f"- [{name}](#{name.lower()}): {schemas[name].get('description', 'No description available.')}")
        
        lines.append("")
        lines.append("## Optional")
        lines.append("")
        for name in sorted_names:
            if name in schemas:
                s = schemas[name]
                lines.append(f"### {name}")
                if 'description' in s: lines.append(f"**Description**: {s['description']}")
                lines.append(f"**Type**: {s.get('type', 'object')}")
                props = s.get('properties', {})
                if props:
                    lines.append("**Properties**:")
                    for p_name, p_details in props.items():
                        p_type = p_details.get('type', 'unknown')
                        lines.append(f"- `{p_name}` ({p_type}): {p_details.get('description', '').replace('\\n', ' ')}")
                lines.append("")
    else:
        # Standard conversion with tag filtering
        tags_map = {}
        for path, methods in paths.items():
            for method, details in methods.items():
                tags = details.get('tags', ['General'])
                if tag_filter and not any(tag in tags for tag in tag_filter):
                    continue
                for tag in tags:
                    if tag not in tags_map: tags_map[tag] = []
                    tags_map[tag].append({'path': path, 'method': method.upper(), 'details': details})

        for tag, endpoints in tags_map.items():
            lines.append(f"## {tag}")
            lines.append("")
            for ep in endpoints:
                summary = ep['details'].get('summary', f"{ep['method']} {ep['path']}")
                desc = ep['details'].get('description', '').replace('\n', ' ')
                lines.append(f"- [{summary}](#{ep['method'].lower()}-{ep['path'].replace('/', '').replace('{', '').replace('}', '')}): {desc}")
            lines.append("")

    with open(output_path, 'w') as f:
        f.write("\n".join(lines))

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("input", help="Path to OpenAPI JSON")
    parser.add_argument("output", help="Path to output llms.txt")
    parser.add_argument("--tags", nargs="+", help="Filter by tags")
    parser.add_argument("--schemas-only", action="store_true", help="Only output schemas")
    args = parser.parse_args()
    convert(args.input, args.output, args.tags, args.schemas_only)
