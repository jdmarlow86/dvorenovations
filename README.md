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


## Supabase integration work in progress

The public browser configuration is in `supabase-config.js`. It contains only the project URL and publishable key. The main `index.html` still uses browser-local storage; the public configuration file alone does not connect or synchronize app records.

### Required Supabase setup

1. The database foundation in `supabase/schema.sql` should already have been run.
2. The employer profile and private `auth_login_aliases` row should already have been created in Supabase SQL Editor.
3. Run `supabase/profile-security.sql` as a separate SQL query. This adds the self-service password-change guard and RPC.
4. Deploy both Edge Functions from this repository:
   - `supabase/functions/username-login/index.ts`
   - `supabase/functions/create-employee/index.ts`

Using Supabase CLI from the repository root:

```sh
supabase login
supabase link --project-ref thurixjqsmqndmqsszwv
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=YOUR_SERVICE_ROLE_SECRET
supabase functions deploy username-login
supabase functions deploy create-employee
```

The functions also need the project URL and anon key as environment values. Supabase normally provides `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY` to deployed Edge Functions; verify the secrets/environment in the Edge Function settings. Do not put the service-role secret in GitHub, a browser file, or a chat.

### Important current limitation

Do not treat this as a completed cloud migration yet. The app's `index.html` still reads and writes `localStorage`. Existing local records have not been imported into Postgres, and employee creation, clock events, expenses, invoices, payments, and inbox messages do not yet synchronize between devices. Export a JSON backup from every browser/device that contains records before migration.
