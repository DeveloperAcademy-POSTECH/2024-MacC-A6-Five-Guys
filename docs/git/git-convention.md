# Git Convention

## 1) Branch Structure & Rules

### Default Branches
- `main`: Release (production)
- `develop`: Integration (development baseline)

### Working Branch Principles
- Always start new work on a **new branch**.
- Do **not** commit directly to `main`, `develop`, or `dev`.
- Merge all working branches into `develop`.
- Merge releases into `main`.
- When starting implementation (e.g., dev work), if you are on a protected branch (`main` / `develop` / `dev`), **create a working branch immediately**.

### Branch Naming (Recommended)
- `feature/<key>-<short-description>`
- `bugfix/<key>-<short-description>`
- `release/<version>`

Examples:
- `feature/ABC-123-profile-edit`
- `bugfix/ABC-456-login-crash`
- `release/1.2.0`

---

## 2) Commit Convention

### Commit Message Format
```text
<type>: <summary>

<optional body>
```

### Allowed Types
- `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`

### Rules
- Keep `type` in **English**.
- Write the subject/body in **English**.
- Keep the subject concise and clearly describe the intent of the change.

Examples:
- `feat: add profile edit`
- `fix: handle missing error message on login failure`
- `refactor: extract profile validation logic`

---

## 3) PR Convention & Workflow

### Before Creating a PR
1. Review the entire commit history (don’t only look at the latest commit).
2. Review all changes:
   - `git diff [base-branch]...HEAD`

### PR Writing Rules
- Write the PR title and description in **Korean**.
- Use `.github/pull_request_template.md` as the default PR description format.
- Recommended: keep commit `type` in English and write the PR title as `<type>: <한글 요약>`  
  Example: `refactor: 메인 홈 독서 흐름 MVVM 전환`

### Must Include in PR Description
- `## 📝 작업 내용`
  - 이번 PR의 핵심 변경 사항과 변경 이유
  - 테스트 수행 내역/결과
  - 후속 작업(TODO / Follow-ups)
- `### 스크린샷 (선택)` 필요 시 첨부
- `## 💬 리뷰 요구사항(선택)` 리뷰어 확인 포인트 작성

### Branch Push Rule
- For the first push of a new branch, set upstream:
  - `git push -u origin <branch-name>`
