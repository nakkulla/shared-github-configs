---
description: "GitHub 연동 및 Shell Integration 제약사항 가이드"
applyTo: "**"
---

# GitHub 연동 & Shell Integration

## ⚠️ Shell Integration 제약사항 (필수 준수)

### 터미널 명령어 제약
- **길이 제한**: 긴 명령어 금지
- **Git 커밋 간결화**: 한 줄로 핵심만 표현
- **여러줄 명령 지양**: 단일 명령어로 실행
- **파이프 최소화**: 복잡한 파이프라인 피하기

### 올바른 명령어 패턴
```bash
# ✅ 권장 패턴
git add .
git commit -m "Add user auth"
git push origin task-1

# ❌ 피해야 할 패턴  
git commit -m "Implement comprehensive user authentication system with JWT tokens and role-based access control including password hashing and session management"
git add . && git commit -m "Update files" && git push
```

## 🔗 GitHub 핵심 워크플로우

### 브랜치 관리 (간소화)
```typescript
// 1. 브랜치 생성 (간단한 이름)
create_branch({
  branch: `task-${taskId}`,
  from_branch: "main"
})

// 2. 작업 진행
set_task_status --id=X --status="in-progress"

// 3. 코드 작업 및 커밋
// Git 명령어는 간결하게!
```

### 이슈 관리
```typescript
// 메인 작업별 이슈 생성
create_issue({
  title: `Task-${taskId}: ${간단한제목}`,
  body: `
## 작업 개요
${task.description}

## 완료 기준  
- [ ] ${subtask1}
- [ ] ${subtask2}

## Taskmaster ID: ${taskId}
`,
  labels: ["taskmaster", "feature"]
})
```

### Pull Request 생성
```typescript
create_pull_request({
  title: `Task-${taskId}: ${간단한제목}`,
  head: `task-${taskId}`,
  base: "main",
  body: `
## 완료된 작업
${taskTitle}

### 주요 변경사항
- ${change1}
- ${change2}

### 테스트 결과
${testResults}

Closes #${issueNumber}
`
})
```

## 📋 GitHub + Taskmaster 통합 패턴

### 작업 시작 시
```typescript
// 1. Taskmaster에서 작업 시작
next_task
set_task_status --id=X --status="in-progress"

// 2. GitHub 브랜치 생성
create_branch({
  branch: `task-${taskId}`,
  from_branch: "main"
})

// 3. 이슈 생성 (필요시)
create_issue({
  title: `Task-${taskId}: ${taskTitle}`,
  body: `작업 상세: ${taskDescription}\n\nTaskmaster ID: ${taskId}`
})
```

### 작업 진행 중
```typescript
// 1. 코드 작업 진행
// 2. 진행 상황 기록
update_subtask --id=X.Y --prompt="구현 완료: ${feature}"

// 3. 간결한 커밋
// git add .
// git commit -m "Add ${feature}"
// git push origin task-${taskId}

// 4. 이슈 업데이트
add_issue_comment({
  issue_number: issueNumber,
  body: `🔄 진행 상황: ${progress}`
})
```

### 작업 완료 시
```typescript
// 1. Taskmaster에서 완료 표시
set_task_status --id=X --status="done"

// 2. Pull Request 생성
create_pull_request({
  title: `Task-${taskId}: ${taskTitle}`,
  head: `task-${taskId}`,
  base: "main",
  body: `완료: ${completedFeatures}\n\nCloses #${issueNumber}`
})

// 3. 이슈 닫기
update_issue({
  issue_number: issueNumber,
  state: "closed"
})
```

## 🏷️ 브랜치 및 커밋 네이밍 규칙

### 브랜치 네이밍
```typescript
// ✅ 권장 패턴
task-1          // 단순하고 명확
task-5-auth     // 기능 추가시
hotfix-2        // 핫픽스시

// ❌ 지양 패턴
feature/task-1-implement-comprehensive-user-authentication-system
fix/bug-in-user-authentication-module-that-causes-login-failure
```

### 커밋 메시지 규칙
```typescript
// ✅ 권장 패턴 (한 줄, 50자 이내)
"Add user auth"
"Fix login bug"  
"Update docs"
"Remove unused code"

// ❌ 지양 패턴 (너무 길거나 복잡)
"Implement comprehensive user authentication system with JWT tokens"
"Fix critical bug in user authentication module that was causing login failures"
```

## 🔄 협업 워크플로우

### 코드 리뷰 요청
```typescript
// PR 생성 후
create_pull_request({
  // ... 기본 정보
  body: prBody + `\n\n@reviewer 리뷰 요청드립니다! 🙏`
})

// 알림은 ntfy로 별도 처리
```

### 충돌 해결
```typescript
// 머지 충돌 발생 시
// 1. 로컬에서 해결
// 2. 간단한 커밋 메시지로 푸시
// git commit -m "Resolve conflict"

// 3. Taskmaster에 기록
update_subtask --id=X.Y --prompt="머지 충돌 해결 완료"
```

## ✅ GitHub 연동 체크리스트

### Shell 명령어 체크리스트
- [ ] Git 커밋 메시지 50자 이내
- [ ] 터미널 명령어 단일 라인
- [ ] 파이프 명령어 최소화
- [ ] 복잡한 스크립트 대신 단순 명령 사용

### GitHub 워크플로우 체크리스트
- [ ] 브랜치명 간단하게 (`task-X`)
- [ ] 이슈 제목 간결하게
- [ ] PR 설명에 완료 내용 포함
- [ ] 이슈와 PR 올바르게 연결 (`Closes #번호`)

### Taskmaster 연동 체크리스트
- [ ] GitHub 작업 전 Taskmaster 상태 업데이트
- [ ] 진행 상황 `update_subtask`로 기록
- [ ] 완료 시 양쪽 모두 상태 업데이트
- [ ] 브랜치명에 Taskmaster ID 포함

## 🛠️ 자동화 패턴

### 이슈-브랜치-PR 자동 연결
```typescript
// 표준 패턴
const taskId = "5";
const branchName = `task-${taskId}`;
const issueTitle = `Task-${taskId}: ${taskTitle}`;
const prTitle = `Task-${taskId}: ${taskTitle}`;

// 모든 요소가 taskId로 연결됨
```

### 라벨 관리
```typescript
// 표준 라벨 세트
const labels = [
  "taskmaster",           // Taskmaster 관련
  "feature|bugfix|docs",  // 작업 타입
  "priority-high|medium|low", // 우선순위
  "in-progress|review|done"   // 상태
];
```

## 🔧 트러블슈팅

### Shell Integration 문제
1. **명령어 파싱 오류** → 명령어 간소화
2. **커밋 메시지 오류** → 50자 이내로 단축
3. **복잡한 파이프 실패** → 단일 명령어로 분해

### GitHub 연동 문제
1. **브랜치 생성 실패** → 이름 단순화
2. **PR 생성 오류** → 설명 길이 확인  
3. **이슈 연결 실패** → `Closes #번호` 정확히 입력

---

이 가이드를 통해 GitHub과 Taskmaster를 효율적으로 연동하되 Shell Integration 제약사항을 준수하세요! 🔗