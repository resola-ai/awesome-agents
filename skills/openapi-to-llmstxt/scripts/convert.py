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


def resolve_ref(ref, spec):
    parts = ref.lstrip('#/').split('/')
    node = spec
    for p in parts:
        node = node.get(p, {})
    return node


def schema_type_str(s, spec, depth=0):
    if depth > 3:
        return '...'
    if '$ref' in s:
        name = s['$ref'].split('/')[-1]
        return f'${name}'
    t = s.get('type', '')
    if t == 'array':
        items = s.get('items', {})
        return f'array[{schema_type_str(items, spec, depth + 1)}]'
    if t == 'object' or 'properties' in s:
        return 'object'
    if 'allOf' in s:
        return ' & '.join(schema_type_str(x, spec, depth + 1) for x in s['allOf'])
    if 'oneOf' in s:
        return ' | '.join(schema_type_str(x, spec, depth + 1) for x in s['oneOf'])
    if 'anyOf' in s:
        return ' | '.join(schema_type_str(x, spec, depth + 1) for x in s['anyOf'])
    return t or 'any'


def format_schema_inline(s, spec, depth=0):
    if depth > 2:
        return '  ' * depth + '...\n'
    if '$ref' in s:
        resolved = resolve_ref(s['$ref'], spec)
        return format_schema_inline(resolved, spec, depth)
    lines = []
    indent = '  ' * depth
    if 'allOf' in s:
        for sub in s['allOf']:
            lines.append(format_schema_inline(sub, spec, depth))
        return ''.join(lines)
    if 'oneOf' in s or 'anyOf' in s:
        variants = s.get('oneOf', s.get('anyOf', []))
        for i, sub in enumerate(variants):
            lines.append(f"{indent}variant {i + 1}:\n")
            lines.append(format_schema_inline(sub, spec, depth + 1))
        return ''.join(lines)
    props = s.get('properties', {})
    required = s.get('required', [])
    for pname, pschema in props.items():
        req_mark = '*' if pname in required else ''
        ptype = schema_type_str(pschema, spec)
        pdesc = pschema.get('description', '').replace('\n', ' ')
        lines.append(f"{indent}- `{pname}`{req_mark} ({ptype}){': ' + pdesc if pdesc else ''}\n")
    return ''.join(lines)


def format_body(content, spec):
    if not content:
        return ''
    lines = []
    for media_type, media_obj in content.items():
        s = media_obj.get('schema', {})
        if '$ref' in s:
            name = s['$ref'].split('/')[-1]
            lines.append(f"  Schema: `{name}`\n")
            resolved = resolve_ref(s['$ref'], spec)
            body = format_schema_inline(resolved, spec, depth=2)
            if body:
                lines.append(body)
        else:
            body = format_schema_inline(s, spec, depth=2)
            if body:
                lines.append(body)
    return ''.join(lines)


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
        # Identify relevant schemas via ref extraction
        relevant_schemas = set()
        for path, methods in paths.items():
            for method, details in methods.items():
                if not isinstance(details, dict):
                    continue
                if not tag_filter or any(tag in details.get('tags', []) for tag in tag_filter):
                    extract_refs(details, relevant_schemas)

        # Recursive expansion
        checked = set()
        to_check = list(relevant_schemas)
        while to_check:
            current = to_check.pop()
            if current in checked:
                continue
            checked.add(current)
            if current in schemas:
                extract_refs(schemas[current], relevant_schemas)
                for r in relevant_schemas:
                    if r not in checked:
                        to_check.append(r)

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
                if 'description' in s:
                    lines.append(f"**Description**: {s['description']}")
                lines.append(f"**Type**: {s.get('type', 'object')}")
                props = s.get('properties', {})
                if props:
                    lines.append("**Properties**:")
                    for p_name, p_details in props.items():
                        p_type = p_details.get('type', 'unknown')
                        lines.append(f"- `{p_name}` ({p_type}): {p_details.get('description', '').replace(chr(10), ' ')}")
                lines.append("")
    else:
        # Group endpoints by tag
        tags_map = {}
        for path, methods in paths.items():
            for method, details in methods.items():
                if not isinstance(details, dict):
                    continue
                tags = details.get('tags', ['General'])
                if tag_filter and not any(tag in tags for tag in tag_filter):
                    continue
                for tag in tags:
                    if tag not in tags_map:
                        tags_map[tag] = []
                    tags_map[tag].append({'path': path, 'method': method.upper(), 'details': details})

        for tag, endpoints in sorted(tags_map.items()):
            lines.append(f"## {tag}")
            lines.append("")
            for ep in sorted(endpoints, key=lambda e: e['path']):
                d = ep['details']
                summary = d.get('summary', f"{ep['method']} {ep['path']}")
                desc = d.get('description', '').replace('\n', ' ').strip()
                op_id = d.get('operationId', '')
                lines.append(f"### {ep['method']} {ep['path']}")
                lines.append(f"**Summary**: {summary}")
                if desc:
                    lines.append(f"**Description**: {desc}")
                if op_id:
                    lines.append(f"**Operation ID**: `{op_id}`")

                # Parameters
                params = d.get('parameters', [])
                if params:
                    lines.append("**Parameters**:")
                    for p in params:
                        loc = p.get('in', '')
                        pname = p.get('name', '')
                        req = ' (required)' if p.get('required') else ''
                        pdesc = p.get('description', '').replace('\n', ' ')
                        pschema = p.get('schema', {})
                        ptype = schema_type_str(pschema, spec)
                        lines.append(f"- `{pname}` [{loc}]{req} ({ptype}){': ' + pdesc if pdesc else ''}")

                # Request body
                req_body = d.get('requestBody', {})
                if req_body:
                    lines.append("**Request Body**:")
                    body_content = req_body.get('content', {})
                    body_str = format_body(body_content, spec)
                    if body_str:
                        lines.append(body_str.rstrip())

                # Responses
                responses = d.get('responses', {})
                if responses:
                    lines.append("**Responses**:")
                    for status, resp in responses.items():
                        rdesc = resp.get('description', '').replace('\n', ' ')
                        lines.append(f"- `{status}`: {rdesc}")
                        resp_content = resp.get('content', {})
                        for media_type, media_obj in resp_content.items():
                            rs = media_obj.get('schema', {})
                            if '$ref' in rs:
                                rname = rs['$ref'].split('/')[-1]
                                lines.append(f"  Returns: `{rname}`")

                lines.append("")

        # Full schemas in Optional section
        lines.append("## Optional")
        lines.append("")
        lines.append("> Full schema definitions for all data models.")
        lines.append("")

        # Determine which schemas to include
        if tag_filter:
            relevant_schemas = set()
            for path, methods in paths.items():
                for method, details in methods.items():
                    if not isinstance(details, dict):
                        continue
                    if any(tag in details.get('tags', []) for tag in tag_filter):
                        extract_refs(details, relevant_schemas)
            checked = set()
            to_check = list(relevant_schemas)
            while to_check:
                current = to_check.pop()
                if current in checked:
                    continue
                checked.add(current)
                if current in schemas:
                    extract_refs(schemas[current], relevant_schemas)
                    for r in relevant_schemas:
                        if r not in checked:
                            to_check.append(r)
            schema_names = sorted(n for n in relevant_schemas if n in schemas)
        else:
            schema_names = sorted(schemas.keys())

        for name in schema_names:
            s = schemas[name]
            lines.append(f"### Schema: {name}")
            sdesc = s.get('description', '')
            if sdesc:
                lines.append(f"**Description**: {sdesc.replace(chr(10), ' ')}")
            lines.append(f"**Type**: {s.get('type', 'object')}")
            props = s.get('properties', {})
            required = s.get('required', [])
            if props:
                lines.append("**Properties**:")
                for pname, pschema in props.items():
                    req_mark = ' (required)' if pname in required else ''
                    ptype = schema_type_str(pschema, spec)
                    pdesc = pschema.get('description', '').replace('\n', ' ')
                    enum_vals = pschema.get('enum', [])
                    enum_str = f" [enum: {', '.join(str(v) for v in enum_vals)}]" if enum_vals else ''
                    lines.append(f"- `{pname}`{req_mark} ({ptype}){enum_str}{': ' + pdesc if pdesc else ''}")
            if 'allOf' in s or 'oneOf' in s or 'anyOf' in s:
                body = format_schema_inline(s, spec, depth=0)
                if body:
                    lines.append("**Structure**:")
                    lines.append(body.rstrip())
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
