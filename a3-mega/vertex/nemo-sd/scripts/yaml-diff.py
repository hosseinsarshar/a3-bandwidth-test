import yaml
import sys
import os
from deepdiff import DeepDiff

def load_yaml(file_path):
    with open(file_path, 'r') as file:
        return yaml.safe_load(file)

def find_yaml_diff(file1, file2):
    yaml1 = load_yaml(file1)
    yaml2 = load_yaml(file2)

    diff = DeepDiff(yaml1, yaml2, ignore_order=True)
    return diff

def format_diff(diff, yaml1, yaml2, file1_name, file2_name):
    if not diff:
        return "No differences found."
    
    formatted_diff = []
    for key, changes in diff.items():
        formatted_diff.append(f"{key}:")
        for change in changes:
            if key == 'values_changed':
                formatted_diff.append(f"  Path: {change}")
                formatted_diff.append(f"    {file1_name}: {changes[change]['old_value']}")
                formatted_diff.append(f"    {file2_name}: {changes[change]['new_value']}")
            elif key in ('dictionary_item_added', 'dictionary_item_removed'):
                formatted_diff.append(f"  Path: {change}")
                if key == 'dictionary_item_added':
                    formatted_diff.append(f"    {file2_name}: {yaml2.get(change.split('[')[1].split(']')[0])}")
                else:
                    formatted_diff.append(f"    {file1_name}: {yaml1.get(change.split('[')[1].split(']')[0])}")
            elif key in ('iterable_item_added', 'iterable_item_removed'):
                formatted_diff.append(f"  Path: {change}")
                if key == 'iterable_item_added':
                    formatted_diff.append(f"    {file2_name}: {changes[change]}")
                else:
                    formatted_diff.append(f"    {file1_name}: {changes[change]}")
            else:
                formatted_diff.append(f"  {change}")
                
    return "\n".join(formatted_diff)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python yaml_diff.py <file1.yaml> <file2.yaml>")
        sys.exit(1)

    file1 = sys.argv[1]
    file2 = sys.argv[2]

    file1_name = os.path.basename(file1)
    file2_name = os.path.basename(file2)

    yaml1 = load_yaml(file1)
    yaml2 = load_yaml(file2)
    differences = find_yaml_diff(file1, file2)
    formatted_differences = format_diff(differences, yaml1, yaml2, file1_name, file2_name)
    print(formatted_differences)
