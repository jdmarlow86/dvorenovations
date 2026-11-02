# Van Ornum Renovations

Responsive browser-based job, employee, time, expense, invoice and payment portal.

## Run
Open `index.html` or enable GitHub Pages from Settings → Pages → Deploy from branch → `main` → `/ (root)`.

## Initial employer login
- Username: `DVO`
- Password: `admin`

Change this password immediately. Employees are added by the employer and prompted to change their initial password after first login.

## Features
- Employer and employee roles, employee activation/deactivation and password resets.
- Customer jobs, employee assignment and job status.
- Per-job clock in/out and labor reports.
- Expense and materials tracking by job/category.
- Invoice generator modeled on the supplied Van Ornum Renovations invoice, including company contact information, line items, subtotal, tax, total, due-upon-receipt terms and Revelation 14:12 footer.
- Payment records, employee inbox messages, dark mode, print-to-PDF reports and JSON backup/restore.

## Important limitation
This is a local-only prototype. Data is saved in the browser's localStorage and is not shared between employees, browsers or devices. GitHub Pages is static hosting and cannot provide secure multi-user authentication or a shared database. Passwords are salted and hashed in-browser, but the bootstrap `DVO/admin` credentials are present in public source. Do not use this prototype for sensitive employee, payroll, customer or financial records. A production release needs server-side authentication, role-based authorization, a shared database, audit logging and secure backups.

## PDF
Use Print / Save PDF for invoices and the report print dialogs, then select Save as PDF in the browser.