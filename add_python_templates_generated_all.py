#!/usr/bin/env python3
"""
Script to add Python templates to ALL problem definitions in generated-all folder.
This script reads each file, finds all problem definitions, extracts their userFacingFRs,
and generates a naive Python implementation for each one.
"""

import re
import os
from typing import List, Dict, Tuple
import anthropic

# Directory containing the problem definition files
DEFINITIONS_DIR = "/Users/ankurkothari/Documents/workspace/idlecampus/frontend/src/apps/system-design/builder/challenges/definitions/generated-all"

# Anthropic API client
client = anthropic.Anthropic()

def find_all_problem_definitions(content: str) -> List[Tuple[str, int, int]]:
    """
    Find all problem definitions in a file.
    Returns list of (problem_name, start_pos, end_pos) tuples.
    """
    problems = []
    # Match: export const xxxProblemDefinition: ProblemDefinition = {
    pattern = r'export const (\w+ProblemDefinition): ProblemDefinition = \{'

    for match in re.finditer(pattern, content):
        problem_name = match.group(1)
        start_pos = match.start()

        # Find the closing brace for this definition
        # We need to count braces to find the matching closing brace
        brace_count = 0
        pos = match.end() - 1  # Start at the opening brace
        in_backtick = False
        in_string = False
        escape_next = False

        while pos < len(content):
            char = content[pos]

            # Handle escape sequences
            if escape_next:
                escape_next = False
                pos += 1
                continue

            if char == '\\':
                escape_next = True
                pos += 1
                continue

            # Handle backtick strings (template literals)
            if char == '`':
                in_backtick = not in_backtick
                pos += 1
                continue

            # Handle regular strings
            if char == '"' or char == "'":
                if not in_backtick:
                    in_string = not in_string
                pos += 1
                continue

            # Only count braces outside of strings
            if not in_backtick and not in_string:
                if char == '{':
                    brace_count += 1
                elif char == '}':
                    brace_count -= 1
                    if brace_count == 0:
                        # Found the closing brace
                        # Now look for the semicolon
                        semicolon_pos = content.find(';', pos)
                        if semicolon_pos != -1:
                            end_pos = semicolon_pos + 1
                            problems.append((problem_name, start_pos, end_pos))
                            break

            pos += 1

    return problems

def extract_frs_from_definition(definition_content: str) -> List[str]:
    """Extract userFacingFRs from a problem definition."""
    # Find userFacingFRs array
    match = re.search(r'userFacingFRs:\s*\[(.*?)\]', definition_content, re.DOTALL)
    if match:
        frs_text = match.group(1)
        # Extract individual FRs (handle both single and double quotes)
        frs = re.findall(r"['\"]([^'\"]*)['\"]", frs_text)
        return [fr for fr in frs if fr.strip()]
    return []

def has_python_template(definition_content: str) -> bool:
    """Check if a problem definition already has pythonTemplate."""
    return 'pythonTemplate:' in definition_content or 'pythonTemplate :' in definition_content

def generate_python_template_with_claude(problem_name: str, problem_title: str, frs: List[str]) -> str:
    """
    Use Claude API to generate a naive Python implementation based on FRs.
    """
    fr_list = "\n".join([f"{i+1}. {fr}" for i, fr in enumerate(frs)])

    prompt = f"""Generate a naive Python implementation for a system design problem.

Problem: {problem_title}

Functional Requirements (FRs):
{fr_list}

Generate Python code with:
- One function per FR (or combine related FRs into logical functions)
- In-memory storage using dicts and lists
- Clear docstring comments explaining which FR each function implements
- Simple, unoptimized code suitable for demonstrating basic functionality
- Appropriate function signatures based on the FR description
- Type hints where appropriate

For technical/infrastructure FRs (like caching, database design, CDN configuration), create functions that simulate the behavior in a naive way.

Return ONLY the Python code, no explanation. Start with imports and storage initialization.

Example format:
```python
from datetime import datetime
from typing import List, Dict

# In-memory storage (naive implementation)
storage = {{}}

def function_name(params) -> return_type:
    \"\"\"
    FR-1: Description
    Naive implementation - explanation
    \"\"\"
    # implementation
    pass
```"""

    message = client.messages.create(
        model="claude-sonnet-4-5-20250929",
        max_tokens=2000,
        messages=[{
            "role": "user",
            "content": prompt
        }]
    )

    # Extract code from response
    response_text = message.content[0].text

    # Remove markdown code fences if present
    code = response_text.strip()
    if code.startswith('```python'):
        code = code[len('```python'):].strip()
    elif code.startswith('```'):
        code = code[3:].strip()
    if code.endswith('```'):
        code = code[:-3].strip()

    return code

def extract_problem_title(definition_content: str) -> str:
    """Extract the title from a problem definition."""
    match = re.search(r"title:\s*['\"]([^'\"]*)['\"]", definition_content)
    if match:
        return match.group(1)
    return "Unknown Problem"

def add_python_template_to_definition(definition_content: str, python_code: str) -> str:
    """
    Add pythonTemplate to a problem definition.
    Inserts before the closing brace and semicolon.
    """
    # Find the validators section - insert after it
    # Pattern: validators: [...],
    # We want to add after the validators closing bracket and comma

    # First, check if there's already a pythonTemplate
    if has_python_template(definition_content):
        return definition_content

    # Escape backticks in the Python code
    escaped_code = python_code.replace('`', '\\`').replace('${', '\\${')

    # Find the last closing bracket before the final };
    # We want to insert before the final };\n
    match = re.search(r'(\n\};)\s*$', definition_content)
    if match:
        insertion_point = match.start()
        new_content = (
            definition_content[:insertion_point] +
            ',\n\n  pythonTemplate: `' + escaped_code + '`,\n};'
        )
        return new_content

    return definition_content

def process_file(filepath: str) -> Dict[str, any]:
    """
    Process a single file, adding Python templates to all problem definitions.
    Returns statistics about the processing.
    """
    filename = os.path.basename(filepath)
    print(f"\n{'='*60}")
    print(f"Processing: {filename}")
    print(f"{'='*60}")

    with open(filepath, 'r') as f:
        content = f.read()

    # Find all problem definitions
    problems = find_all_problem_definitions(content)
    print(f"Found {len(problems)} problem definitions")

    stats = {
        'filename': filename,
        'total_problems': len(problems),
        'already_had_template': 0,
        'added_template': 0,
        'failed': 0
    }

    # Process each problem definition in reverse order (so positions don't shift)
    problems.reverse()

    for problem_name, start_pos, end_pos in problems:
        definition_content = content[start_pos:end_pos]

        # Check if already has template
        if has_python_template(definition_content):
            print(f"  ✓ {problem_name}: Already has template")
            stats['already_had_template'] += 1
            continue

        # Extract FRs
        frs = extract_frs_from_definition(definition_content)
        if not frs:
            print(f"  ✗ {problem_name}: No FRs found")
            stats['failed'] += 1
            continue

        # Extract title
        title = extract_problem_title(definition_content)

        print(f"  → {problem_name}: Generating template for {len(frs)} FRs...")

        try:
            # Generate Python template
            python_code = generate_python_template_with_claude(problem_name, title, frs)

            # Add template to definition
            new_definition = add_python_template_to_definition(definition_content, python_code)

            # Replace in content
            content = content[:start_pos] + new_definition + content[end_pos:]

            print(f"  ✓ {problem_name}: Template added")
            stats['added_template'] += 1

        except Exception as e:
            print(f"  ✗ {problem_name}: Failed - {str(e)}")
            stats['failed'] += 1

    # Write updated content back to file
    if stats['added_template'] > 0:
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"\n✓ File updated: {stats['added_template']} templates added")
    else:
        print(f"\n- No changes needed")

    return stats

def main():
    """Main execution."""
    print("Python Template Generator for generated-all folder")
    print("=" * 60)

    # Get all TypeScript files except tutorialAllProblems.ts
    files = []
    for filename in os.listdir(DEFINITIONS_DIR):
        if filename.endswith('AllProblems.ts') and filename != 'tutorialAllProblems.ts':
            files.append(os.path.join(DEFINITIONS_DIR, filename))

    files.sort()

    print(f"Found {len(files)} files to process")
    print(f"Directory: {DEFINITIONS_DIR}")

    # Start with cachingAllProblems.ts as requested
    caching_file = os.path.join(DEFINITIONS_DIR, 'cachingAllProblems.ts')
    if caching_file in files:
        files.remove(caching_file)
        files.insert(0, caching_file)

    all_stats = []

    for filepath in files:
        stats = process_file(filepath)
        all_stats.append(stats)

    # Print summary
    print("\n" + "=" * 60)
    print("SUMMARY")
    print("=" * 60)

    total_problems = sum(s['total_problems'] for s in all_stats)
    total_already_had = sum(s['already_had_template'] for s in all_stats)
    total_added = sum(s['added_template'] for s in all_stats)
    total_failed = sum(s['failed'] for s in all_stats)

    print(f"\nFiles processed: {len(all_stats)}")
    print(f"Total problems: {total_problems}")
    print(f"Already had templates: {total_already_had}")
    print(f"Templates added: {total_added}")
    print(f"Failed: {total_failed}")

    print("\nPer-file breakdown:")
    for stats in all_stats:
        if stats['added_template'] > 0 or stats['failed'] > 0:
            print(f"  {stats['filename']}: +{stats['added_template']} added, {stats['failed']} failed")

if __name__ == '__main__':
    main()
