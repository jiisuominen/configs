# Function to check encodings of files in the current branch relative to main
check_encodings_branch() {
  # Get list of PHP, JS, and HTML files changed in the current branch relative to master
  # Use readarray/mapfile equivalent for zsh to properly handle files with spaces and newlines
  changed_files=("${(@f)$(git diff --name-only origin/master..HEAD -- "*.php" "*.js" "*.html")}")

  # If no PHP, JS, or HTML files have been changed, exit
  if [ ${#changed_files[@]} -eq 0 ]; then
    echo "No PHP, JS, or HTML files changed in this branch."
    return 0
  fi

  echo "Checking file encodings for changed files..."
  echo "----------------------------------------"

  # Iterate over each changed file and check its encoding
  for file in "${changed_files[@]}"; do
    if [ ! -f "$file" ]; then
      echo "Warning: File '$file' not found (may have been deleted)"
      continue
    fi

    echo "Checking file: $file"
    
    # Try to detect encoding with 'file' command
    file_output=$(file -I "$file")
    encoding=$(echo "$file_output" | grep -o "charset=.*" | cut -d= -f2)
    echo "Detected encoding: $encoding"

    # Convert encoding to lowercase for comparison
    encoding_lower=$(echo "$encoding" | tr '[:upper:]' '[:lower:]')
    
    # Check if the encoding matches any of the ISO-8859-1 variants
    if [[ "$encoding_lower" != "iso-8859-1" && \
          "$encoding_lower" != "iso8859-1" && \
          "$encoding_lower" != "latin1" ]]; then
      
      # Try to detect if the file is actually UTF-8 with ASCII content
      if file "$file" | grep -q "ASCII text"; then
        echo "Note: File appears to be ASCII text (compatible with ISO-8859-1)"
      else
        echo "⚠️  Warning: File '$file' has encoding '$encoding' which is not ISO-8859-1"
        echo "    Full encoding info: $file_output"
        
        # Additional check with iconv
        if iconv -f ISO-8859-1 -t UTF-8 "$file" >/dev/null 2>&1; then
          echo "    Note: File content is compatible with ISO-8859-1 encoding"
        else
          echo "    ❌ File content is NOT compatible with ISO-8859-1 encoding"
        fi
      fi
    else
      echo "✓ File encoding is ISO-8859-1 compatible"
    fi
    echo "----------------------------------------"
  done
}




# Function to check encodings of files in a specific commit
check_encodings_commit() {
  # Check if a commit hash is provided
  if [ -z "$1" ]; then
    echo "Please provide a commit hash."
    return 1
  fi

  # Get list of PHP, JS, and HTML files changed in the specific commit
  changed_files=("${(@f)$(git show --name-only "$1" -- "*.php" "*.js" "*.html" | tail -n +2)}")

  # If no PHP, JS, or HTML files have been changed in the commit, exit
  if [ ${#changed_files[@]} -eq 0 ]; then
    echo "No PHP, JS, or HTML files changed in commit $1."
    return 0
  fi

  echo "Checking file encodings for files in commit $1..."
  echo "----------------------------------------"

  # Iterate over each changed file and check its encoding
  for file in "${changed_files[@]}"; do
    if [ ! -f "$file" ]; then
      echo "Warning: File '$file' not found (may have been deleted)"
      continue
    fi

    echo "Checking file: $file"
    
    # Try to detect encoding with 'file' command
    file_output=$(file -I "$file")
    encoding=$(echo "$file_output" | grep -o "charset=.*" | cut -d= -f2)
    echo "Detected encoding: $encoding"

    # Convert encoding to lowercase for comparison
    encoding_lower=$(echo "$encoding" | tr '[:upper:]' '[:lower:]')
    
    # Check if the encoding matches any of the ISO-8859-1 variants
    if [[ "$encoding_lower" != "iso-8859-1" && \
          "$encoding_lower" != "iso8859-1" && \
          "$encoding_lower" != "latin1" ]]; then
      
      # Try to detect if the file is actually UTF-8 with ASCII content
      if file "$file" | grep -q "ASCII text"; then
        echo "Note: File appears to be ASCII text (compatible with ISO-8859-1)"
      else
        echo "⚠️  Warning: File '$file' has encoding '$encoding' which is not ISO-8859-1"
        echo "    Full encoding info: $file_output"
        
        # Additional check with iconv
        if iconv -f ISO-8859-1 -t UTF-8 "$file" >/dev/null 2>&1; then
          echo "    Note: File content is compatible with ISO-8859-1 encoding"
        else
          echo "    ❌ File content is NOT compatible with ISO-8859-1 encoding"
        fi
      fi
    else
      echo "✓ File encoding is ISO-8859-1 compatible"
    fi
    echo "----------------------------------------"
  done
}

# Function to check encodings of all files recursively in current directory
check_encodings() {
  echo "Checking file encodings recursively in current directory..."
  echo "Looking for files that are not ISO-8859-1 compatible..."
  echo "----------------------------------------"

  found_non_iso=false

  # Find all PHP, JS, and HTML files recursively in the current directory
  # Use process substitution to properly handle filenames with spaces
  while IFS= read -r file; do
    if [ ! -f "$file" ]; then
      continue
    fi

    # Try to detect encoding with 'file' command
    encoding=$(file -I "$file" | grep -o "charset=.*" | cut -d= -f2)
    encoding_lower=$(echo "$encoding" | tr '[:upper:]' '[:lower:]')
    
    # Check if the encoding matches any of the ISO-8859-1 variants
    if [[ "$encoding_lower" != "iso-8859-1" && \
          "$encoding_lower" != "iso8859-1" && \
          "$encoding_lower" != "latin1" ]]; then
      
      # Only proceed with output if it's not ASCII text (which is compatible)
      if ! file "$file" | grep -q "ASCII text" || ! iconv -f ISO-8859-1 -t UTF-8 "$file" >/dev/null 2>&1; then
        found_non_iso=true
        echo "$file: $encoding"
      fi
    fi
  done < <(find . \( -name "*.php" -o -name "*.js" -o -name "*.html" \) -type f)

  if [ "$found_non_iso" = false ]; then
    echo "All files are ISO-8859-1 compatible."
  fi
}

