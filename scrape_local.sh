#!/bin/bash
set -euo pipefail # More robust error handling than just -xe

# Ensure the output directory exists
mkdir -p repomix-logs
mkdir -p repomix-output

# Use mlr to process the CSV robustly, skipping header (implicit with --icsv)
mlr --icsv --ocsv cat sites.csv | tail -n +2 | while IFS=',' read -r url directory include_files exclude_files; do
  # Skip potentially empty lines from mlr output (though unlikely)
  [ -z "$url" ] && continue

  echo "Processing URL: $url"
  echo " -> Directory: ${directory:-<none>}" # Use default value for clarity if empty
  echo " -> Include: ${include_files:-<none>}"
  echo " -> Exclude: ${exclude_files:-<none>}"

  # --- Robust Filename Generation ---
  # 1. Basic cleaning: remove protocol, replace non-alphanumeric with underscore
  safe_base=$(echo "$url" | sed -e 's|^\w+://||' -e 's|/$||' -e 's|[^a-zA-Z0-9._-]|_|g')
  # 2. Truncate if too long (adjust max length as needed, 200 is usually safe)
  max_len=200
  if [[ ${#safe_base} -gt $max_len ]]; then
    safe_base="${safe_base:0:$max_len}"
  fi
  # 3. Add a hash for uniqueness (optional, but good if URLs might be very similar)
  # url_hash=$(echo -n "$url" | md5sum | cut -c1-8)
  # logs_filename="scraped_sites/${safe_base}_${url_hash}.txt"
  # OR simpler without hash:
  timestamp=$(date +%s) # Add timestamp for simple uniqueness if run frequently
  logs_filename="repomix-logs/${safe_base}_${timestamp}.txt"
  output_filename="$(pwd)/repomix-output/${safe_base}_${timestamp}.md"


  # --- Secure Command Construction using Arrays ---
  cmd=("npx" "repomix" "--no-file-summary" "--no-directory-structure") # Start with base command

  if [[ "$url" == *"github.com"* ]]; then
    cmd+=("--remote" "$url") # Append arguments safely
  else
    cmd+=("$url")
  fi

  if [[ -n "$directory" ]]; then
    cmd+=("$directory")
  fi

  # Handle potentially comma-separated include/exclude patterns safely
  if [[ -n "$include_files" ]]; then
      # Split the comma-separated string into an array
      IFS=',' read -r -a include_patterns <<< "$include_files"
      # Add each pattern as a separate --include argument
      for pattern in "${include_patterns[@]}"; do
          # Trim whitespace (optional but good practice)
          pattern_trimmed=$(echo "$pattern" | xargs)
          if [[ -n "$pattern_trimmed" ]]; then
              cmd+=("--include" "$pattern_trimmed")
          fi
      done
  fi

  if [[ -n "$exclude_files" ]]; then
      IFS=',' read -r -a exclude_patterns <<< "$exclude_files"
      for pattern in "${exclude_patterns[@]}"; do
          pattern_trimmed=$(echo "$pattern" | xargs)
          if [[ -n "$pattern_trimmed" ]]; then
              cmd+=("--ignore" "$pattern_trimmed")
          fi
      done
  fi

  # Add output file to repomix command
  cmd+=("--output" "$output_filename")

  echo "Running command: ${cmd[@]}"
  if "${cmd[@]}" > "$logs_filename" 2>&1; then
    echo "Success: Saved output to $output_filename"
    echo "Log: $logs_filename"
  else
    exit_code=$?
    echo "Error: Command failed for $url with exit code $exit_code. Check $logs_filename for error details." >&2
    # exit $exit_code # Uncomment this line to stop the script on the first error
  fi
  echo "-----------------------------------------"

done

echo "Scraping process finished."