# ui-audit-dashboard

Password-protected audit dashboards published to GitHub Pages. Plaintext sources live on **`main`**; password-protected reports are built automatically on **`reports`**.

**Live site:** [https://acsgenui.github.io/ui-audit-dashboard/](https://acsgenui.github.io/ui-audit-dashboard/)

---

## Branches

| Branch | Purpose | Who updates it |
|--------|---------|----------------|
| **`main`** | Plaintext HTML, CSV, JSON, and assets | You (via PR) |
| **`reports`** | Password-protected HTML + assets for GitHub Pages | GitHub Actions only |

Do not commit password-protected HTML to `main` or edit `reports` by hand.

---

## Submitting a PR (what to include)

### Fork and open a PR

1. **Fork** [acsgenui/ui-audit-dashboard](https://github.com/acsgenui/ui-audit-dashboard) on GitHub (Fork → create a copy under your account).
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/<your-username>/ui-audit-dashboard.git
   cd ui-audit-dashboard
   ```
3. **Create a branch** for your changes:
   ```bash
   git checkout -b add-<client-name>-dashboard
   ```
4. **Commit and push** to your fork, then on GitHub open a **Pull Request** into `acsgenui/ui-audit-dashboard` → **`main`**.

### What to add in the PR

1. **Create or update a project folder** named after the client (e.g. `Abbvie/`, `ASUS/`, `UoS/`).
2. **Add the dashboard HTML** (and any data the page needs) under that folder.

### Typical folder layout

```text
Abbvie/
  dashboard.html          # required — main dashboard page
  Metrics.csv
  Code_Audit_Checklist.csv
  Browser_Audit_Checklist.csv
  Manual_Checklist.csv
```

### Rules

- Put every dashboard under a **subfolder** (not the repo root).
- Use **plaintext** `.html` on `main` — CI password-protects it on `reports`.
- Include **all files** the HTML loads (CSV, JSON, images, etc.) in the **same parent folder** as the HTML file.
- Target the upstream **`main`** branch (not `reports`).

### After merge

| Trigger | Workflow | What happens |
|---------|----------|----------------|
| Push to `main` (HTML / CSV / JSON under a client folder) | **Encrypt HTML (delta)** | Syncs that folder to `reports`, password-protects HTML, removes deleted files/folders |
| Manual: Actions → **Encrypt HTML (all)** | Full rebuild | Clears `reports`, rebuilds password protection for every dashboard from `main` |

---

## Preview on GitHub Pages

Page is served from the **`reports`** branch. After CI finishes, open:

```text
https://acsgenui.github.io/ui-audit-dashboard/<parent-folder>/<page>.html
```

### Example URLs

| Project | Report URL |
|---------|------------|
| **Abbvie** | [https://acsgenui.github.io/ui-audit-dashboard/Abbvie/dashboard.html](https://acsgenui.github.io/ui-audit-dashboard/Abbvie/dashboard.html) |
| **ASUS** | [https://acsgenui.github.io/ui-audit-dashboard/ASUS/dashboard.html](https://acsgenui.github.io/ui-audit-dashboard/ASUS/dashboard.html) |

Replace `<parent-folder>` and `<page>.html` with your paths.

---

On the login screen you will see:

- **Title:** parent folder name (e.g. `Abbvie`)
- **Instructions:** PRoGenAI Analysis Report
- **Button:** Show Report

Share the URL and password only with people who should access that report.

---

## PR checklist for reviewers

- [ ] Changes target **`main`** only (plaintext).
- [ ] Client folder contains `dashboard.html` (or `report.html`) plus required data files.
- [ ] After merge, **Encrypt HTML** workflow succeeded on Actions.
- [ ] GitHub Pages preview loads and decrypts with `@<parent-directory>#`.

---

## Deleting a report

Remove the client folder (or files) on **`main`** and merge. The delta workflow deletes the matching paths on **`reports`**. For a full reset, run **Encrypt HTML (all)** from the Actions tab.

---

## Workflows (maintainers)

| Workflow | When |
|----------|------|
| [encrypt-html.yml](.github/workflows/encrypt-html.yml) | Push to `main` (delta) |
| [encrypt-html-all.yml](.github/workflows/encrypt-html-all.yml) | Manual full rebuild |
| [encrypt-reports-reusable.yml](.github/workflows/encrypt-reports-reusable.yml) | Shared implementation |

Scripts live under [.github/scripts/](.github/scripts/).
