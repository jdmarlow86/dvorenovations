# Van Ornum Renovations

Responsive browser-based job, employee, time, expense, invoice and payment portal.

## Website
Open `index.html` or enable GitHub Pages from Settings → Pages → Deploy from branch → `main` → `/ (root)`.

## Current backend migration status
The original website is still the localStorage prototype. Supabase database schema and the initial Row Level Security policies have been added under `supabase/schema.sql`. An employer-only employee-provisioning Edge Function is under `supabase/functions/create-employee/index.ts`.

**The website is not yet connected to Supabase.** Do not begin entering live business records or employee credentials expecting them to sync across devices until the front-end integration and authentication setup are completed and tested.

## Supabase configuration
Project URL: `https://thurixjqsmqndmqsszwv.supabase.co`

The browser will use the Supabase publishable key. Never commit a database password, service-role key, or other secret to this repository.

The Edge Function must be deployed using the Supabase CLI. Configure the function's server-side secrets in Supabase; never place the service-role key in `index.html`.

## Login design
The intended employee experience is username and password. Supabase Auth uses email/phone identifiers internally; the planned implementation maps usernames to an internal, non-mailbox login identifier. Employees are provisioned by the employer-only Edge Function and should change their temporary password after their first sign-in.

## Features in the local prototype
- Employer and employee roles, employee activation/deactivation and password resets.
- Customer jobs, employee assignment and job status.
- Per-job clock in/out and labor reports.
- Expense and materials tracking by job/category.
- Invoice generator modeled on the supplied Van Ornum Renovations invoice, including company contact information, line items, subtotal, tax, total, due-upon-receipt terms and Revelation 14:12 footer.
- Payment records, employee inbox messages, dark mode, print-to-PDF reports and JSON backup/restore.

## Data migration
Before replacing local storage, use the app's **Reports → Export data backup (JSON)** option in the browser/device that contains the records. Keep that backup in a safe location. Migration tooling should be tested against a copy before importing real records.

## Security
Customer names/addresses, employee identities, time records, invoices and business communications are private business information even when payment-card data is not stored. Use authentication and correctly tested Row Level Security. The Supabase service-role key must remain server-side.

## PDF
Use Print / Save PDF for invoices and report print dialogs, then select Save as PDF in the browser.
