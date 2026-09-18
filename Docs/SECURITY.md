# Security

## 1. Goals

Protect project data, source media access, module integrity and user credentials.

## 2. Filesystem Access (Implemented)

Request access only when necessary.

Respect macOS sandbox and security-scoped access rules when applicable.

## 3. Source Media (Implemented)

The application must not modify source media during normal editing.

Destructive filesystem operations require explicit user action.

## 4. Project Files (Implemented)

Project parsing must validate input and handle malformed or corrupted project data safely.

## 5. Modules (Design Goal — not yet built)

Modules must be validated before being loaded.

The module system should verify:
- Module identity
- Version
- Compatibility
- Integrity
- Dependencies

## 6. Updates (Design Goal — not yet built)

Module and application updates should use trusted distribution mechanisms.

Failed updates must not leave the application in an unusable state.

## 7. Credentials (Design Goal — not yet built)

Integration credentials and tokens must not be stored in plain-text project files.

Use appropriate macOS credential storage.

## 8. Network (Design Goal — not yet built)

Network access should be limited to features that require it.

The Core editor should remain functional without network access for local workflows.

## 9. Security Reporting Process

To report a security vulnerability, please follow these steps:

- **How to Report**: Do not open a public issue. Instead, report the vulnerability via GitHub Security Advisories (if enabled for this repository) or email the maintainer directly.
- **Required Information**: Include a clear description of the vulnerability, step-by-step instructions to reproduce it, and the potential impact on the application or user.
- **Response Time**: Kino is a small, open-source educational project. Please expect a realistic response time of 7-14 days for an initial assessment. We do not provide enterprise-level SLAs, but we will address critical vulnerabilities as promptly as our capacity allows.

## 10. Principle of Least Privilege (Implemented)

Every component should receive only the permissions it actually needs.
