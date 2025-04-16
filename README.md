# Site Scraper with GitHub Actions

This project automatically scrapes websites and repositories listed in a CSV file using Repomix and GitHub Actions.

## How it Works

1. The project reads URLs and configuration from a CSV file (`sites.csv`)
2. Uses Repomix (via npx) to convert each website or repository to plain text
3. Saves the results in the `scraped_sites` directory
4. Runs automatically daily via GitHub Actions
5. Commits and pushes any changes to the repository

## CSV Format

The `sites.csv` file should have the following columns:

- `url`: The URL to scrape (required)
- `directory`: A specific directory to scrape (optional)
- `include_files`: Glob patterns for files to include (optional)
- `exclude_files`: Glob patterns for files to exclude (optional)

Example:
```
url,directory,include_files,exclude_files
https://github.com/google/adk-docs,,"docs/**/*.md",
https://example.com,src,"**/*.js,**/*.ts","**/*.test.js"
```

## Setup

1. Fork this repository
2. Edit `sites.csv` to include the URLs and configuration you want to scrape
3. Enable GitHub Actions in your repository
4. The scraper will run daily at midnight UTC

## Manual Trigger

You can also manually trigger the scraping process:
1. Go to the "Actions" tab in your repository
2. Select the "Scrape Sites" workflow
3. Click "Run workflow"

## Local Development

To run the scraper locally, use the provided shell script:

```bash
bash scrape_local.sh
```

This will:
- Create the `scraped_sites` directory if it doesn't exist
- Read each row from `sites.csv` (skipping the header)
- Build and run the appropriate `repomix` command for each row
- Save the output to a file in `scraped_sites/`

### Requirements
- Node.js 18+
- [repomix](https://www.npmjs.com/package/repomix) (installed via npx)

### Debugging & Troubleshooting
- The script prints each command and variable for debugging.
- If nothing happens, check for:
  - Empty or malformed `sites.csv`
  - Quoting or comma issues in CSV fields
  - Errors from `repomix` (check the output files for error messages)
- You can add `set -x` to the top of the script for more verbose output.

## Output

The scraped content will be saved in the `scraped_sites` directory, with one file per URL. The files are named based on the URL, with special characters replaced by underscores. 