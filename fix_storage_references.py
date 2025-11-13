#!/usr/bin/env python3
"""
Fix script to ensure all storage references are properly declared.
Adds missing storage variables when functions reference them.
"""

import re
import os

DEFINITIONS_DIR = "/Users/ankurkothari/Documents/workspace/idlecampus/frontend/src/apps/system-design/builder/challenges/definitions/generated-all"

def fix_file(filepath):
    """Fix storage references in a file."""
    filename = os.path.basename(filepath)

    with open(filepath, 'r') as f:
        content = f.read()

    fixed_count = 0

    # Find all pythonTemplate blocks
    pattern = r'pythonTemplate: `(.*?)`,'

    def fix_template(match):
        nonlocal fixed_count
        template = match.group(1)

        # Extract storage section
        storage_match = re.search(r'# In-memory storage.*?\n(.*?)\n\ndef', template, re.DOTALL)
        if not storage_match:
            return match.group(0)

        storage_section = storage_match.group(1)

        # Find all storage variables referenced in functions
        referenced_vars = set()

        # Look for patterns like: items[...], items.get(...), item_id in items
        for var_match in re.finditer(r'\b(\w+)\[', template):
            var = var_match.group(1)
            if var not in ['datetime', 'kwargs', 'Dict', 'List', 'str', 'int', 'float', 'bool']:
                referenced_vars.add(var)

        for var_match in re.finditer(r'\b(\w+)\.get\(', template):
            var = var_match.group(1)
            if var not in ['datetime', 'kwargs', 'Dict', 'List', 'str', 'int', 'float', 'bool']:
                referenced_vars.add(var)

        for var_match in re.finditer(r'\bin (\w+)\b', template):
            var = var_match.group(1)
            if var not in ['datetime', 'kwargs', 'Dict', 'List', 'str', 'int', 'float', 'bool', 'range']:
                referenced_vars.add(var)

        # Find currently declared storage variables
        declared_vars = set()
        for var_match in re.finditer(r'^(\w+) = \{\}', storage_section, re.MULTILINE):
            declared_vars.add(var_match.group(1))

        # Find missing variables
        missing_vars = referenced_vars - declared_vars

        if missing_vars:
            # Add missing variables to storage section
            new_storage_lines = []
            for var in sorted(declared_vars):
                new_storage_lines.append(f'{var} = {{}}')
            for var in sorted(missing_vars):
                new_storage_lines.append(f'{var} = {{}}')

            new_storage = '\\n'.join(new_storage_lines)

            # Replace storage section
            new_template = re.sub(
                r'(# In-memory storage.*?\n)(.*?)(\n\ndef)',
                r'\1' + new_storage + r'\3',
                template,
                count=1,
                flags=re.DOTALL
            )

            fixed_count += 1
            return f'pythonTemplate: `{new_template}`,'

        return match.group(0)

    new_content = re.sub(pattern, fix_template, content, flags=re.DOTALL)

    if new_content != content:
        with open(filepath, 'w') as f:
            f.write(new_content)
        print(f"✓ {filename}: Fixed {fixed_count} templates")
        return True
    else:
        print(f"- {filename}: No fixes needed")
        return False

def main():
    print("Storage Reference Fix Script")
    print("=" * 60)

    files = []
    for filename in os.listdir(DEFINITIONS_DIR):
        if filename.endswith('AllProblems.ts') and filename != 'tutorialAllProblems.ts':
            files.append(os.path.join(DEFINITIONS_DIR, filename))

    files.sort()

    fixed_files = 0
    for filepath in files:
        if fix_file(filepath):
            fixed_files += 1

    print("=" * 60)
    print(f"Fixed {fixed_files} files")

if __name__ == '__main__':
    main()
