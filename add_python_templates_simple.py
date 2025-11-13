#!/usr/bin/env python3
"""
Script to add Python templates to ALL problem definitions in generated-all folder.
This version generates templates based on pattern matching of FRs.
"""

import re
import os
from typing import List, Dict, Tuple

# Directory containing the problem definition files
DEFINITIONS_DIR = "/Users/ankurkothari/Documents/workspace/idlecampus/frontend/src/apps/system-design/builder/challenges/definitions/generated-all"

def find_all_problem_definitions(content: str) -> List[Tuple[str, int, int]]:
    """
    Find all problem definitions in a file.
    Returns list of (problem_name, start_pos, end_pos) tuples.
    """
    problems = []
    pattern = r'export const (\w+ProblemDefinition): ProblemDefinition = \{'

    for match in re.finditer(pattern, content):
        problem_name = match.group(1)
        start_pos = match.start()

        # Find the closing brace for this definition
        brace_count = 0
        pos = match.end() - 1  # Start at the opening brace
        in_backtick = False
        in_string = False
        escape_next = False

        while pos < len(content):
            char = content[pos]

            if escape_next:
                escape_next = False
                pos += 1
                continue

            if char == '\\':
                escape_next = True
                pos += 1
                continue

            if char == '`':
                in_backtick = not in_backtick
                pos += 1
                continue

            if char == '"' or char == "'":
                if not in_backtick:
                    in_string = not in_string
                pos += 1
                continue

            if not in_backtick and not in_string:
                if char == '{':
                    brace_count += 1
                elif char == '}':
                    brace_count -= 1
                    if brace_count == 0:
                        semicolon_pos = content.find(';', pos)
                        if semicolon_pos != -1:
                            end_pos = semicolon_pos + 1
                            problems.append((problem_name, start_pos, end_pos))
                            break

            pos += 1

    return problems

def extract_frs_from_definition(definition_content: str) -> List[str]:
    """Extract userFacingFRs from a problem definition."""
    match = re.search(r'userFacingFRs:\s*\[(.*?)\]', definition_content, re.DOTALL)
    if match:
        frs_text = match.group(1)
        frs = re.findall(r"['\"]([^'\"]*)['\"]", frs_text)
        return [fr for fr in frs if fr.strip()]
    return []

def has_python_template(definition_content: str) -> bool:
    """Check if a problem definition already has pythonTemplate."""
    return 'pythonTemplate:' in definition_content or 'pythonTemplate :' in definition_content

def extract_problem_title(definition_content: str) -> str:
    """Extract the title from a problem definition."""
    match = re.search(r"title:\s*['\"]([^'\"]*)['\"]", definition_content)
    if match:
        return match.group(1)
    return "Unknown Problem"

def generate_function_from_fr(fr: str, fr_index: int) -> str:
    """Generate a Python function based on an FR."""
    fr_lower = fr.lower()

    # Detect common patterns and generate appropriate functions
    function_code = ""

    # Pattern: Store/Save/Create/Add
    if any(word in fr_lower for word in ['store', 'save', 'create', 'add', 'register', 'upload', 'insert', 'write']):
        if 'user' in fr_lower or 'profile' in fr_lower or 'account' in fr_lower:
            function_code = f'''def create_user(user_id: str, **kwargs) -> Dict:
    """
    FR-{fr_index+1}: {fr}
    Naive implementation - stores user in memory
    """
    users[user_id] = {{
        'id': user_id,
        'created_at': datetime.now(),
        **kwargs
    }}
    return users[user_id]'''
        elif 'post' in fr_lower or 'content' in fr_lower or 'message' in fr_lower:
            function_code = f'''def create_post(post_id: str, user_id: str, content: str, **kwargs) -> Dict:
    """
    FR-{fr_index+1}: {fr}
    Naive implementation - stores post in memory
    """
    posts[post_id] = {{
        'id': post_id,
        'user_id': user_id,
        'content': content,
        'created_at': datetime.now(),
        **kwargs
    }}
    return posts[post_id]'''
        else:
            function_code = f'''def create_item(item_id: str, **kwargs) -> Dict:
    """
    FR-{fr_index+1}: {fr}
    Naive implementation - stores item in memory
    """
    items[item_id] = {{
        'id': item_id,
        'created_at': datetime.now(),
        **kwargs
    }}
    return items[item_id]'''

    # Pattern: Get/Retrieve/Fetch/Read/Query
    elif any(word in fr_lower for word in ['get', 'retrieve', 'fetch', 'read', 'query', 'search', 'find', 'serve', 'return']):
        if 'feed' in fr_lower or 'timeline' in fr_lower:
            function_code = f'''def get_feed(user_id: str, limit: int = 20) -> List[Dict]:
    """
    FR-{fr_index+1}: {fr}
    Naive implementation - returns recent posts
    """
    feed_items = sorted(posts.values(), key=lambda x: x['created_at'], reverse=True)
    return feed_items[:limit]'''
        elif 'search' in fr_lower:
            function_code = f'''def search(query: str, limit: int = 20) -> List[Dict]:
    """
    FR-{fr_index+1}: {fr}
    Naive implementation - simple string matching
    """
    results = []
    for item in items.values():
        if query.lower() in str(item).lower():
            results.append(item)
    return results[:limit]'''
        else:
            function_code = f'''def get_item(item_id: str) -> Dict:
    """
    FR-{fr_index+1}: {fr}
    Naive implementation - retrieves from memory
    """
    return items.get(item_id)'''

    # Pattern: Update/Modify/Edit
    elif any(word in fr_lower for word in ['update', 'modify', 'edit', 'change']):
        function_code = f'''def update_item(item_id: str, **kwargs) -> Dict:
    """
    FR-{fr_index+1}: {fr}
    Naive implementation - updates item in memory
    """
    if item_id in items:
        items[item_id].update(kwargs)
        items[item_id]['updated_at'] = datetime.now()
        return items[item_id]
    return None'''

    # Pattern: Delete/Remove
    elif any(word in fr_lower for word in ['delete', 'remove']):
        function_code = f'''def delete_item(item_id: str) -> bool:
    """
    FR-{fr_index+1}: {fr}
    Naive implementation - removes from memory
    """
    if item_id in items:
        del items[item_id]
        return True
    return False'''

    # Pattern: Like/Vote/React
    elif any(word in fr_lower for word in ['like', 'vote', 'react', 'upvote', 'downvote']):
        function_code = f'''def add_reaction(item_id: str, user_id: str, reaction_type: str = 'like') -> Dict:
    """
    FR-{fr_index+1}: {fr}
    Naive implementation - stores reaction in memory
    """
    reaction_id = f"{{item_id}}_{{user_id}}"
    reactions[reaction_id] = {{
        'item_id': item_id,
        'user_id': user_id,
        'type': reaction_type,
        'created_at': datetime.now()
    }}
    return reactions[reaction_id]'''

    # Pattern: Follow/Friend/Subscribe
    elif any(word in fr_lower for word in ['follow', 'friend', 'subscribe']):
        function_code = f'''def follow_user(follower_id: str, followee_id: str) -> Dict:
    """
    FR-{fr_index+1}: {fr}
    Naive implementation - stores relationship in memory
    """
    relationship_id = f"{{follower_id}}_{{followee_id}}"
    relationships[relationship_id] = {{
        'follower_id': follower_id,
        'followee_id': followee_id,
        'created_at': datetime.now()
    }}
    return relationships[relationship_id]'''

    # Pattern: Cache/CDN/Serve
    elif any(word in fr_lower for word in ['cache', 'cdn', 'edge']):
        function_code = f'''def cache_item(key: str, value: any, ttl: int = 3600) -> bool:
    """
    FR-{fr_index+1}: {fr}
    Naive implementation - simple in-memory cache with TTL
    """
    cache[key] = {{
        'value': value,
        'expires_at': datetime.now().timestamp() + ttl
    }}
    return True

def get_from_cache(key: str) -> any:
    """
    FR-{fr_index+1}: {fr}
    Naive implementation - retrieves from cache if not expired
    """
    if key in cache:
        item = cache[key]
        if datetime.now().timestamp() < item['expires_at']:
            return item['value']
        del cache[key]
    return None'''

    # Pattern: Analytics/Track/Monitor
    elif any(word in fr_lower for word in ['analytic', 'track', 'monitor', 'metric', 'count']):
        function_code = f'''def track_event(event_type: str, item_id: str, metadata: Dict = None) -> Dict:
    """
    FR-{fr_index+1}: {fr}
    Naive implementation - stores event in memory
    """
    event_id = f"{{event_type}}_{{item_id}}_{{datetime.now().timestamp()}}"
    events[event_id] = {{
        'id': event_id,
        'type': event_type,
        'item_id': item_id,
        'metadata': metadata or {{}},
        'created_at': datetime.now()
    }}
    return events[event_id]'''

    # Default: generic function
    else:
        func_name = re.sub(r'[^a-z0-9_]', '_', fr_lower[:40])
        func_name = re.sub(r'_+', '_', func_name).strip('_')
        if not func_name:
            func_name = f'handle_fr_{fr_index+1}'
        function_code = f'''def {func_name}(**kwargs) -> Dict:
    """
    FR-{fr_index+1}: {fr}
    Naive implementation - placeholder function
    """
    return {{'status': 'success', 'data': kwargs}}'''

    return function_code

def generate_python_template(title: str, frs: List[str]) -> str:
    """Generate a naive Python implementation based on FRs."""

    # Determine what storage structures we need
    storage_vars = set()

    for fr in frs:
        fr_lower = fr.lower()
        if any(word in fr_lower for word in ['user', 'profile', 'account']):
            storage_vars.add('users = {}')
        if any(word in fr_lower for word in ['post', 'content', 'article', 'status']):
            storage_vars.add('posts = {}')
        if any(word in fr_lower for word in ['message', 'chat', 'comment']):
            storage_vars.add('messages = {}')
        if any(word in fr_lower for word in ['like', 'vote', 'react', 'upvote']):
            storage_vars.add('reactions = {}')
        if any(word in fr_lower for word in ['follow', 'friend', 'subscribe']):
            storage_vars.add('relationships = {}')
        if any(word in fr_lower for word in ['cache', 'cdn']):
            storage_vars.add('cache = {}')
        if any(word in fr_lower for word in ['event', 'analytic', 'track', 'metric']):
            storage_vars.add('events = {}')

    # Default storage if nothing specific detected
    if not storage_vars:
        storage_vars.add('items = {}')
        storage_vars.add('data = {}')

    # Build the template
    template_parts = [
        "from datetime import datetime",
        "from typing import List, Dict, Optional, Any",
        "",
        "# In-memory storage (naive implementation)"
    ]

    # Add storage variables
    template_parts.extend(sorted(storage_vars))
    template_parts.append("")

    # Generate functions for each FR
    for i, fr in enumerate(frs):
        function_code = generate_function_from_fr(fr, i)
        template_parts.append(function_code)
        template_parts.append("")

    return "\n".join(template_parts).strip()

def add_python_template_to_definition(definition_content: str, python_code: str) -> str:
    """Add pythonTemplate to a problem definition."""
    if has_python_template(definition_content):
        return definition_content

    # Escape backticks and template literals in Python code
    escaped_code = python_code.replace('\\', '\\\\').replace('`', '\\`').replace('${', '\\${')

    # Find the closing }; of the definition
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
    """Process a single file, adding Python templates to all problem definitions."""
    filename = os.path.basename(filepath)
    print(f"\n{'='*60}")
    print(f"Processing: {filename}")
    print(f"{'='*60}")

    with open(filepath, 'r') as f:
        content = f.read()

    problems = find_all_problem_definitions(content)
    print(f"Found {len(problems)} problem definitions")

    stats = {
        'filename': filename,
        'total_problems': len(problems),
        'already_had_template': 0,
        'added_template': 0,
        'failed': 0
    }

    # Process in reverse order so positions don't shift
    problems.reverse()

    for problem_name, start_pos, end_pos in problems:
        definition_content = content[start_pos:end_pos]

        if has_python_template(definition_content):
            print(f"  ✓ {problem_name}: Already has template")
            stats['already_had_template'] += 1
            continue

        frs = extract_frs_from_definition(definition_content)
        if not frs:
            print(f"  ✗ {problem_name}: No FRs found")
            stats['failed'] += 1
            continue

        title = extract_problem_title(definition_content)
        print(f"  → {problem_name}: Generating template for {len(frs)} FRs...")

        try:
            python_code = generate_python_template(title, frs)
            new_definition = add_python_template_to_definition(definition_content, python_code)
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
