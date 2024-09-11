# GitHub Team Auditor

![Main View Screenshot](screenshots/index.png)

## Features:

- **Import a GitHub team** and related access issues to a members.csv
- Import script iterates over **pagination** and **rate limits** itself according to response headers
- Reads and writes directly to CSV
- **Keyboard shortcuts** for navigating table body/header (<kbd>Ctrl</kbd>+<kbd>A/E</kbd> and <kbd>Ctrl</kbd>+<kbd>F/B/P/N</kbd>or <kbd>Ctrl</kbd>-<kbd>H/J/K/L)</kbd>. Use <kbd>Ctrl</kbd>+<kbd>/</kbd> for help.
- Column **sorting** (click or press Enter on header)
- Column **filtering** (<kbd>/</kbd> to search) including regex searching
- In-place editing (<kbd>Shift</kbd>+<kbd>Enter</kbd>/<kbd>Enter</kbd>/<kbd>Tab</kbd>/<kbd>Shift</kbd>+<kbd>Tab</kbd> to navigate, <kbd>Esc</kbd> to cancel, <kbd>Enter</kbd> to save)
- **Auto-selects name** when tabbing for easy copying to clipboard (for searching in your company's directory/Slack)
- **Search GitHub Team for member** by pressing <kbd>Ctrl</kbd>+<kbd>T</kbd>
- **Merge script** to sync updates from a new members.csv while preserving changes
- **Revisioning** of members.csv (keeps last ten changes in members.csv-*timestamp*)

## Running locally

1. Run `cp .env.local.example .env.local`
2. Edit `$EDITOR .env.local` with your own values
3. Run `bundle; rackup`
