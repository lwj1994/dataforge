
import os
import re

directory = 'generator/test/src/examples'

# Regex to find any 'get copyWith =>' that might still be missing pragma
# We look for the keyword sequence on a line
pattern = re.compile(r'^(\s+)(.+ get copyWith =>)(.*)$', re.MULTILINE)

pragma_check = "@pragma('vm:prefer-inline')"

for filename in os.listdir(directory):
    if filename.endswith(".dart"):
        filepath = os.path.join(directory, filename)
        with open(filepath, 'r') as f:
            lines = f.readlines()
        
        new_lines = []
        
        for i, line in enumerate(lines):
            match = pattern.match(line)
            if match:
                # Found a copyWith getter line
                # Check if previous line has pragma
                has_pragma = False
                prev_idx = i - 1
                while prev_idx >= 0 and lines[prev_idx].strip() == '':
                    prev_idx -= 1
                if prev_idx >= 0 and pragma_check in lines[prev_idx]:
                    has_pragma = True
                
                if not has_pragma:
                    indent = match.group(1)
                    # Insert pragma
                    new_lines.append(f"{indent}{pragma_check}\n")
            
            new_lines.append(line)
            
        new_content = "".join(new_lines)
        
        if new_content != "".join(lines):
            print(f"Final patch for {filename}")
            with open(filepath, 'w') as f:
                f.write(new_content)
