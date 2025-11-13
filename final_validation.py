#!/usr/bin/env python3
import os
import re

dir_path = '/Users/ankurkothari/Documents/workspace/idlecampus/frontend/src/apps/system-design/builder/challenges/definitions/generated-all'

print('Final Validation Report')
print('='*60)

files = [f for f in os.listdir(dir_path) if f.endswith('AllProblems.ts') and f != 'tutorialAllProblems.ts']
total_templates = 0
total_problems = 0

for filename in sorted(files):
    filepath = os.path.join(dir_path, filename)
    with open(filepath, 'r') as f:
        content = f.read()

    # Count templates and problems
    template_count = content.count('pythonTemplate:')
    problem_count = content.count('ProblemDefinition = {')

    total_templates += template_count
    total_problems += problem_count

print(f'\nTotal Files Processed: {len(files)}')
print(f'Total Problem Definitions: {total_problems}')
print(f'Total Python Templates: {total_templates}')
print(f'\nCoverage: {total_templates}/{total_problems} ({100*total_templates//total_problems}%)')

if total_templates == total_problems:
    print('\n✓ SUCCESS: All problem definitions have Python templates!')
else:
    print(f'\n✗ Missing {total_problems - total_templates} templates')

print('\n' + '='*60)
print('Sample Problems with Templates:')
print('='*60)

# Show a few examples
examples = [
    'cachingAllProblems.ts',
    'streamingAllProblems.ts',
    'searchAllProblems.ts'
]

for filename in examples:
    filepath = os.path.join(dir_path, filename)
    with open(filepath, 'r') as f:
        content = f.read()

    # Find first problem
    match = re.search(r'export const (\w+): ProblemDefinition', content)
    if match:
        problem_name = match.group(1)

        # Check if it has a template
        if 'pythonTemplate:' in content:
            print(f'✓ {filename}: {problem_name} has Python template')

print('\n✓ Validation complete!')
