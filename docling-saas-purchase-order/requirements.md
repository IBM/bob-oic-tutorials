# Purchase Order Consolidator Requirements

## Purpose
Process multiple Purchase Order PDFs using Docling for watsonx SaaS and generate consolidated inventory analytics.

## Input
- Upload multiple PO PDFs (drag-and-drop or file selection)

## Output
Extracts: PO numbers, vendors, dates, items, quantities, prices, and calculates the total.

Three consolidated views as tables:
1. All Line Items: Complete itemized list with PO details as table
2. By Vendor: Total POs and spend per supplier
3. By Product: Total quantities and costs with vendor sources
4. Allow CSV export for all line items.

## Users
Procurement teams, inventory managers, finance teams, supply chain coordinators.

## Technical
- PDF only.
- Requires Docling for watsonx SaaS API.
- Docling SaaS credentials provided in .env file
- Build with Python Flask with the port configure in .env file.
- Use IBM Carbon Design System with two-page design: (1) Upload page with drag-and-drop zone, blue-to-purple gradient hero header, and feature cards; (2) Results page with gradient hero, colorful stat cards (purple/green/magenta/blue borders), and three data tables with color-coded tags for PO numbers and vendors
- Follow Python folder structure best practices
- No Docker requirment, run locally on machine with Python virtual environment.
- Stateless service, no persistent storage.
- Note: Use pandas>=2.2.0 and docling>=2.95.0+.
- Parsing tip: When extracting data from Docling markdown output, capture table headers before separator lines and handle multiline metadata with flexible regex patterns.
- Important: To validate your implementation, create integration test with Docling based on the sample PDF in the sample folder. Before doing that ask me to fill in my Docling API Key on .env file.

### Sample Code

from pathlib import Path

from docling.service_client import DoclingServiceClient

SERVICE_URL="https://api.aws-c1.dcls.saas.ibm.com/20260519-2040-0213-6007-20006a73b966"
API_KEY="your-api-key"

with DoclingServiceClient(url=SERVICE_URL, api_key=API_KEY) as client:
    result = client.convert(
        source=Path("path/to/your/file.pdf")
    )

print(result.document.export_to_markdown())