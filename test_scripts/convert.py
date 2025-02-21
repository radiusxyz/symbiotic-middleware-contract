def convert_fish_to_bash(fish_file_content):
    # Split content into lines and initialize output
    lines = fish_file_content.strip().split('\n')
    bash_lines = ['# Network Configuration']
    
    for line in lines:
        # Skip empty lines
        if not line.strip():
            continue
            
        # Parse fish format: set -x VAR "value"
        parts = line.split(None, 3)  # Split into max 4 parts
        if len(parts) >= 4 and parts[0] == 'set' and parts[1] == '-x':
            var_name = parts[2]
            # Remove surrounding quotes if they exist
            value = parts[3].strip('"')
            
            # Special case for PRIVATE_KEY using variable reference
            if var_name == 'PRIVATE_KEY' and value == parts[3].strip('"'):
                bash_lines.append(f'export {var_name}="$NETWORK_PRIVATE_KEY"')
            else:
                bash_lines.append(f'export {var_name}="{value}"')
    
    return '\n'.join(bash_lines)

def main():
    # Read input file
    try:
        with open('env.fish', 'r') as file:
            fish_content = file.read()
        
        # Convert to bash format
        bash_content = convert_fish_to_bash(fish_content)
        
        # Write output file
        with open('env.bash', 'w') as file:
            file.write(bash_content)
            
        print("Successfully converted env.fish to env.bash")
        
    except FileNotFoundError:
        print("Error: env.fish file not found")
    except Exception as e:
        print(f"An error occurred: {str(e)}")

if __name__ == "__main__":
    main()