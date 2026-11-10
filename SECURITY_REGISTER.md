# DevSecOps Security Risk Register & Pipeline Report

**Course**: DevSecOps - Security at Every Level (Week 5 In-Class Activity)  
**Author**: Karabo-jpg (`k.ojiambo@alustudent.com`)  
**Repository**: `Karabo-jpg/devops-2025S-demo`  
**Pull Request**: [#1](https://github.com/Karabo-jpg/devops-2025S-demo/pull/1)  

---

## 1. Security Gates Policy (Drill 5)

| Workflow Job | Scanner Tool | Target | Gating Policy | Justification |
| :--- | :--- | :--- | :--- | :--- |
| **Secrets Scan** | Gitleaks v8 | Repository History & PR Commits | **Strict Block** (Exit Code 1 on any match) | Any real credential committed to git represents immediate exposure and credential compromise. Zero tolerance policy. |
| **Code Scan** | Bandit | Python Source Code (`campus_notifier/`) | **Strict Block** (`continue-on-error: false`) | Ensures hardcoded secrets, weak crypto, and dangerous calls are resolved before merging into the main branch. |
| **Container Scan** | Trivy | Docker Image (`campus-notifier:dev`) | **Block on CRITICAL** (`severity: CRITICAL`, `exit-code: 1`) | Prevents immediately exploitable remote execution or root compromise vulnerabilities. 49 HIGH OS findings are tracked as documented risk for upstream base image updates. |
| **IaC Scan** | Checkov | Terraform (`terraform/*.tf`) | **Strict Block** (`soft_fail: false`) | Unsuppressed infrastructure misconfigurations (e.g. open security groups, unencrypted public buckets) fail the build. Non-critical deviations require deliberate `#checkov:skip` justifications. |

---

## 2. Security Findings & Risk Register (Drills 2–4)

| Finding ID | Scanner | Target & Location | Severity | Action | Owner | Revisit Date | Justification & Remediation Details |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **B105** | Bandit | `campus_notifier/settings.py:27` | Low | **Remediated** | Karabo-jpg | Resolved | **Finding**: `hardcoded_password_string` detected on `SECRET_KEY = "django-insecure-..."`.<br>**Remediation**: Moved `SECRET_KEY` to load via `os.environ["DJANGO_SECRET_KEY"]` using `python-dotenv`. Added local `.env` (gitignored).<br>**Note on Rotation**: The previous development secret still resides in previous commit history, so removing it from the file does not equal secret rotation. A newly generated 32-byte secret was placed in `.env`. |
| **Gitleaks-01** | Gitleaks | Git Commits / Staged Files | High | **Remediated** | Karabo-jpg | Resolved | **Finding**: Tested with real 32-byte hex API key in settings.py to verify pre-commit hook enforcement. Blocked with `generic-api-key`.<br>**Remediation**: Verified hook blocks commits containing secrets; ensured no credentials exist in repository tracking. |
| **CVE-2025-64459** | Trivy | `campus-notifier:dev` (Python pkg: Django 5.2.7) | CRITICAL | **Remediated** | Karabo-jpg | Resolved | **Finding**: Django SQL injection vulnerability in Django 5.2.7 (`CVE-2025-64459`). Trivy gate (`severity: CRITICAL`, `exit-code: 1`) successfully caught this vulnerability and blocked the build.<br>**Remediation**: Upgraded `requirements.txt` to `Django==5.2.8`. Container build now has 0 CRITICAL vulnerabilities and passes the gate. |
| **CVEs (Base OS)** | Trivy | Docker Image `campus-notifier:dev` (Debian 13.7) | High (49) | **Accepted Risk** | DevOps Team | 2026-11-24 | **Finding**: 49 HIGH severity vulnerabilities detected in Debian base OS libraries (e.g. `glibc`, `openssl`). 0 CRITICAL vulnerabilities remaining.<br>**Remediation Plan**: Base image is `python:3.12-slim`. Policy blocks on `CRITICAL`. Rebuild weekly against latest patch releases; evaluate migration to Chainguard or Alpine distroless images to minimize package attack surface. |
| **CKV_AWS_136** | Checkov | `aws_ecr_repository.devops_repo` in `terraform/main.tf` | Medium | **Suppressed** | Cloud Team | 2026-11-24 | **Finding**: "Ensure that ECR repositories are encrypted using KMS".<br>**Suppression Justification**: `#checkov:skip=CKV_AWS_136: Accepted risk: AWS-managed default AES-256 encryption is sufficient for classroom testing demo images; customer-managed KMS key is omitted to prevent recurring KMS CMK costs.` |

---

## 3. Technical Discussion Questions

### Q1: Why does CI run Gitleaks again when the commit-time hook already exists?
Commit-time pre-commit hooks execute client-side on the developer's local machine. Local hooks can easily be bypassed (e.g., using `git commit --no-verify` or `git commit -n`), bypassed due to misconfigured developer environments, or missed when changes are submitted via the GitHub web editor or external integrations. 

Running Gitleaks in CI creates an immutable, server-side security boundary that guarantees every commit and pull request satisfies the organization's secret-free policy before code reaches the shared branch.

### Q2: Why did Bandit flag a key that Gitleaks passed?
- **Gitleaks** relies on regex pattern matching and entropy detection designed to detect live API keys and tokens. Gitleaks deliberately contains exception heuristics that ignore strings prefixed with `django-insecure-`, recognizing them as generated development placeholders rather than true leaked production credentials.
- **Bandit** performs static Abstract Syntax Tree (AST) analysis on Python code. Its `B105` rule checks for any literal string assignment to variables with names associated with passwords and secrets (like `SECRET_KEY`, `PASSWORD`, `API_KEY`). Because a hardcoded string literal was directly assigned in the Python source code, Bandit correctly flagged the anti-pattern regardless of whether the string appeared to be a development placeholder.

---

## 4. Verification & Artifacts

- **Pre-commit hook**: Configured with Ruff linting, Ruff formatting, and Gitleaks (`v8.30.1`).
- **GitHub Actions Workflow**: `.github/workflows/security.yml` executes `code` (Bandit), `secrets` (Gitleaks), `image` (Trivy), and `iac` (Checkov).
- **All Checks Passing**: All 4 security gates pass in CI with policy thresholds enforced.
