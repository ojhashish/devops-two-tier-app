# devops-two-tier-app

Branching Strategy-

main: This branch always contains production-ready code. Deployments to production will happen from main.

develop: This branch integrates all new features and bug fixes before they are ready for production. All feature branches are merged into develop.

feature/your-feature-name: For developing new features. Branch off develop and merge back into develop via a Pull Request (PR).

bugfix/your-bug-name: For fixing bugs. Branch off develop and merge back into develop via a PR.
