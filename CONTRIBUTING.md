# Contributing to HandyBar

HandyBar is in the planning stage. Contributions currently focus on clarifying
the three features in the [README](README.md): Alarm, Auto Click, and Cleanup.
Discuss scope changes in a GitHub issue before implementing additional features.

## Propose a change

Search [existing issues](https://github.com/maytad/HandyBar/issues) before opening one.
Describe the problem, expected behavior, and a concrete example.
For bugs, include reproduction steps, the macOS and app versions, and the Mole
version when relevant. Remove personal paths, credentials, and sensitive data
from logs or screenshots. Follow [SECURITY.md](SECURITY.md) for vulnerabilities.

## Development and verification

There is no app project, build command, or test suite yet. The implementation
stack and minimum macOS version are still being decided.
The first implementation should document its prerequisites and exact build/test
commands here, including how to run locally without the maintainer's credentials.

For documentation changes, check relative links, keep proposed behavior distinct
from implemented behavior, and check the diff for accidental changes.
For future code changes, run the documented checks and report which passed,
failed, or could not run. Keep changes focused and add meaningful regression
coverage for behavior changes when a test setup exists.

## Submit a pull request

Use your own GitHub account. Fork the repository when you do not have branch
write access, and submit a pull request to `main`.
Link the relevant issue, explain the resulting behavior, and report verification.
Keep unrelated refactors out of the change. Add images only when they help explain
a visual change.

Credentials, signing certificates, provisioning files, and private local settings
belong outside the repository. RTK and a particular AI assistant are optional;
contributors can use standard development tools.

By submitting a contribution, you agree to license your contribution under the
project's [MIT License](LICENSE). Identify third-party code and its license before
adding it. The initial integration calls a separately installed Mole CLI; changes
that redistribute or incorporate Mole need a licensing review first.
