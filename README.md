# Casino – Database Marketing Analysis

This project simulates a real-world database marketing analyst workflow
for a casino environment.

## Key Features
- Raw data preserved (no mutation)
- Clean analytical view with compliance rules
- Rejection/audit view with explicit data quality reasons
- Legal gambling age enforcement (21+)
- Email, phone, ZIP, and signup date validation

## Tech Stack
- PostgreSQL
- SQL (CTEs, CASE logic, regex)

## Notes
All transformations are implemented as views to preserve data lineage
and auditability.
