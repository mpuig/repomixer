# Site Scraper with Repomix and GitHub Actions

This project automatically scrapes websites and repositories listed in a CSV file using [Repomix](https://www.npmjs.com/package/repomix) and GitHub Actions.

## Prerequisites

- Bash (with arrays and `set -o pipefail`)
- Node.js 18+ (with `npx`)
- Repomix (via `npx`)
- Miller (`mlr`)

## How it Works

1. The project reads URLs and configuration from a CSV file (`sites.csv`).
2. Uses Repomix (via npx) to convert each website or repository to plain text.
3. Saves the results in the `repomix-output/` directory, one file per URL (overwriting previous runs for the same URL).
4. Logs for each run are saved in the `repomix-logs/` directory (with timestamps for uniqueness).
5. Runs automatically daily via GitHub Actions, or can be run manually.
6. Commits and pushes any changes in `repomix-output/` to the repository.

## CSV Format

The `sites.csv` file should have the following columns:

| Column           | Description                                          | Required |
|------------------|------------------------------------------------------|:--------:|
| `url`            | The URL or Git repo to scrape                        | Yes      |
| `directory`      | Specific directory within a repo/site (optional)     | No       |
| `include_files`  | Glob patterns to include (optional, comma-separated) | No       |
| `exclude_files`  | Glob patterns to exclude (optional, comma-separated) | No       |

Example:
```
url,directory,include_files,exclude_files
https://github.com/google/adk-docs,,docs/**/*.md,
https://example.com,src,**/*.js,**/*.test.js
```

## Local Usage

To run the scraper locally:

1. Make sure you have [Node.js](https://nodejs.org/) 18+ and [Miller (mlr)](https://miller.readthedocs.io/en/latest/) installed.
   - Install Miller: `sudo apt-get install -y miller` (Linux) or `brew install miller` (macOS)
2. Make the script executable:
   ```bash
   chmod +x scrape.sh
   ```
3. Run the script:
   ```bash
   ./scrape.sh
   ```
4. Output files will be in `repomix-output/`, logs in `repomix-logs/`.

## GitHub Actions Usage

The workflow is defined in `.github/workflows/scrape.yml` and will:
- Run on a schedule (daily at midnight UTC) or manually via the Actions tab.
- Install Node.js and Miller.
- Run `scrape.sh` to generate outputs and logs.
- Commit and push any changes in `repomix-output/` back to the repository.

## Output

- **Scraped content:** Saved in `repomix-output/`, one `.md` file per URL (overwritten on each run).
- **Logs:** Saved in `repomix-logs/`, one `.txt` file per run per URL (timestamped for uniqueness).
- **Only `repomix-output/` is tracked by git.** The `repomix-logs/` directory is ignored (see `.gitignore`).

## Requirements

- Node.js 18+
- [Repomix](https://www.npmjs.com/package/repomix) (installed via npx)
- [Miller (mlr)](https://miller.readthedocs.io/en/latest/) for robust CSV parsing

## Troubleshooting

- If the GitHub Action does not commit changes, check that the output in `repomix-output/` actually changed.
- If you see errors about missing files or permissions, ensure the script is executable and all dependencies are installed.
- Check the logs in `repomix-logs/` for detailed error messages.

---

Feel free to open issues or pull requests for improvements! 