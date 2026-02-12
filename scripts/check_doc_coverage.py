#!/usr/bin/env python3
import sys
import re

def parse_coverage(content):
    # Regex to capture the percentages in the Abstract column
    # Line format: "Types           | 20 % (25/122)   | ..."
    # Note: Using non-breaking space potentially in output, or normal space.
    # Also decimal comma or point depending on locale? The output showed "0,0 %".
    
    lines = content.splitlines()
    coverage_data = {}
    
    # regex for line: Name | Abstract % | Curated % | Code Listing %
    # expecting: Name | percent % (n/m) | ...
    # We look for lines starting with Types, Members, Globals
    pattern = re.compile(r"^\s*(Types|Members|Globals)\s+\|\s+([\d,]+)\s*%\s+\(")
    
    for line in lines:
        match = pattern.search(line)
        if match:
            category = match.group(1)
            percent_str = match.group(2).replace(',', '.')
            percent = float(percent_str)
            coverage_data[category] = percent
            
    return coverage_data

def main():
    if len(sys.argv) < 2:
        print("Usage: check_doc_coverage.py <threshold_percent>")
        sys.exit(1)
        
    try:
        threshold = float(sys.argv[1])
    except ValueError:
        print("Error: Threshold must be a number.")
        sys.exit(1)
    
    # Read from stdin
    content = sys.stdin.read()
    
    # Print content for debugging/visibility
    print(content)
    
    coverage = parse_coverage(content)
    
    if not coverage:
        print("Error: Could not parse coverage data.")
        # If we can't parse, it might be that the command failed or output format changed.
        # But for now, fail.
        sys.exit(1)
        
    failed = False
    print(f"Checking documentation coverage (Threshold: {threshold}%)...")
    
    for category in ["Types", "Members", "Globals"]:
        if category in coverage:
            percent = coverage[category]
            if percent < threshold:
                print(f"❌ {category}: {percent}% < {threshold}%")
                failed = True
            else:
                print(f"✅ {category}: {percent}% >= {threshold}%")
        else:
             print(f"⚠️ {category}: No data found.")

            
    if failed:
        sys.exit(1)
    else:
        print("Coverage check passed!")
        sys.exit(0)

if __name__ == "__main__":
    main()
