#!/usr/bin/env python3

import requests
import argparse
import re
import sys
import os

def extract_sheet_id(url):
    """Extract Google Sheet ID from URL."""
    # Pattern for Google Sheets URLs
    pattern = r'https://docs\.google\.com/spreadsheets/d/([a-zA-Z0-9_-]+)'
    match = re.search(pattern, url)

    if match:
        return match.group(1)
    else:
        raise ValueError("Invalid Google Sheets URL. Please provide a URL in the format: "
                         "https://docs.google.com/spreadsheets/d/YOUR_SHEET_ID/...")

def download_sheet_as_csv(sheet_id, output_path=None, sheet_number=0):
    """Download Google Sheet as CSV.

    Args:
        sheet_id (str): The Google Sheet ID.
        output_path (str, optional): The output file path. If None, will use sheet_id as filename.
        sheet_number (int, optional): Sheet number to download (0-based index). Default is 0 (first sheet).

    Returns:
        str: Path to the saved CSV file.
    """
    # Construct the export URL
    # export_url = f"https://docs.google.com/spreadsheets/d/{sheet_id}/export?format=csv&gid={sheet_number}"
    export_url = f"https://docs.google.com/spreadsheets/d/{sheet_id}/export?format=csv"

    # import pdb; pdb.set_trace()
    # Make the request
    response = requests.get(export_url)

    # Check if request was successful
    if response.status_code != 200:
        raise Exception(f"Failed to download the sheet. Status code: {response.status_code}")

    # Set output filename
    if not output_path:
        output_path = f"{sheet_id}.csv"

    # Write the CSV content to a file
    with open(output_path, 'wb') as f:
        f.write(response.content)

    return output_path

def main():
    # Set up argument parser
    parser = argparse.ArgumentParser(description='Download a Google Sheet as CSV.')
    parser.add_argument('url', help='Public URL of the Google Sheet')
    parser.add_argument('-o', '--output', help='Output file path (default: SHEET_ID.csv)')
    parser.add_argument('-s', '--sheet', type=int, default=0,
                        help='Sheet number to download (0-based index, default: 0)')

    # Parse arguments
    args = parser.parse_args()

    try:
        # Extract Sheet ID from URL
        sheet_id = extract_sheet_id(args.url)

        # Download the sheet
        output_file = download_sheet_as_csv(sheet_id, args.output, args.sheet)

        print(f"Successfully downloaded the sheet to {output_file}")

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
