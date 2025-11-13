#!/bin/bash

dir="/Users/ankurkothari/Documents/workspace/idlecampus/frontend/src/apps/system-design/builder/challenges/definitions/generated-all"

echo "Python Template Count by File"
echo "=============================="
echo ""

total=0
for file in "$dir"/*AllProblems.ts; do
    filename=$(basename "$file")
    if [ "$filename" != "tutorialAllProblems.ts" ]; then
        count=$(grep -c "pythonTemplate:" "$file" 2>/dev/null || echo "0")
        echo "$filename: $count"
        total=$((total + count))
    fi
done

echo ""
echo "=============================="
echo "Total templates added: $total"
