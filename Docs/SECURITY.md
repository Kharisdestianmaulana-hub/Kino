# Security

## 1. Goals

Protect project data, source media access, module integrity and user credentials.

## 2. Filesystem Access

Request access only when necessary.

Respect macOS sandbox and security-scoped access rules when applicable.

## 3. Source Media

The application must not modify source media during normal editing.

Destructive filesystem operations require explicit user action.

## 4. Project Files

Project parsing must validate input and handle malformed or corrupted project data safely.

## 5. Modules

Modules must be validated before being loaded.

The module system should verify:
- Module identity
- Version
- Compatibility
- Integrity
- Dependencies

## 6. Updates

Module and application updates should use trusted distribution mechanisms.

Failed updates must not leave the application in an unusable state.

## 7. Credentials

Integration credentials and tokens must not be stored in plain-text project files.

Use appropriate macOS credential storage.

## 8. Network

Network access should be limited to features that require it.

The Core editor should remain functional without network access for local workflows.

## 9. Security Reporting

Security issues should have a documented reporting process.

## 10. Principle of Least Privilege

Every component should receive only the permissions it actually needs.
