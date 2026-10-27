# Elyon Labs GitHub Actions workflows

Reusable GitHub Actions workflows shared by Elyon Labs repositories.

## Workflows

- `validate-pr-title.yml` checks pull request titles against the configured Conventional Commits types.
- `validate-flutter-melos.yml` installs Flutter and Melos, then formats, analyzes, and tests Dart and Flutter packages.
- `validate-supabase.yml` validates Supabase Edge Functions with Deno and checks database migrations and schema linting.
- `validate-web.yml` installs JavaScript dependencies, typechecks, tests, and builds a web application.
- `deploy-supabase-production.yml` applies production database migrations and deploys Supabase Edge Functions, with optional Discord failure notifications.
- `deploy-web-cloudflare.yml` typechecks, builds, and deploys a web application to Cloudflare.
- `publish-github-release.yml` creates a GitHub release for a tag with generated release notes.
- `pr_title.yml` runs the pull request title check for this repository itself.

## Calling a reusable workflow

Reference reusable workflows from a caller repository's job and pin the reference to a full commit SHA:

```yaml
jobs:
  validate-web:
    uses: elyon-labs/workflows/.github/workflows/validate-web.yml@<full-commit-sha>
    with:
      node-version: "22.23.2"
```

See each workflow's `workflow_call` declaration for its inputs and required secrets. Callers should pass secrets explicitly and grant only the permissions their jobs need.

Third-party actions in these workflows are pinned to full commit SHAs; release tags are included in comments for readability.
