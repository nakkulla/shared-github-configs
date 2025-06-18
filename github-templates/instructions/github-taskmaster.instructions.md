---
description: "GitHub 프로젝트에서 Taskmaster MCP 기반 체계적 개발 워크플로우 가이드"
applyTo: "**"
---

# GitHub + Taskmaster 통합 개발 워크플로우

## 🚀 핵심 원칙

- **메인 태스크 단위 실행**: 한 번에 하나의 메인 작업만 집중해서 진행
- **하위 작업 분할 관리**: 복잡한 작업은 적절히 나누어 단계별 진행
- **완료 브리핑 필수**: 모든 작업 완료 시 상세한 진행 상황 브리핑 제공
- **ntfy 알림 자동화**: 주요 마일스톤과 완료 시점에 즉시 알림 전송
- **체계적 문서화**: 모든 진행 상황을 Taskmaster와 GitHub에 동시 기록

## 📋 GitHub 프로젝트 시작 워크플로우

### 1단계: 프로젝트 초기화 및 설정
```typescript
// 1. Taskmaster 프로젝트 초기화
initialize_project

// 2. GitHub 저장소 생성 (필요시)
mcp_github_create_repository({
  name: "project-name",
  description: "프로젝트 설명",
  private: false
})

// 3. 초기화 완료 알림
mcp_ntfy-me-mcp_ntfy_me({
  taskTitle: "GitHub Project Initialized",
  taskSummary: "GitHub 저장소와 Taskmaster 프로젝트가 초기화되었습니다. PRD 작성을 시작하세요.",
  priority: "default",
  tags: ["github", "init", "start"]
})
```

### 2단계: PRD 기반 작업 계획
```typescript
// 1. PRD 파싱 및 작업 생성
parse_prd

// 2. 복잡도 분석
analyze_project_complexity --research

// 3. GitHub 이슈 생성 (각 메인 작업별)
// 메인 작업들을 GitHub 이슈로 동기화
mcp_github_create_issue({
  title: "[Task-1] 작업 제목",
  body: `
  ## 작업 개요
  ${task.description}
  
  ## 완료 기준
  - [ ] 하위 작업 1
  - [ ] 하위 작업 2
  
  ## Taskmaster ID
  작업 ID: ${task.id}
  `,
  labels: ["taskmaster", "feature"]
})

// 4. 브리핑 준비 완료 알림
mcp_ntfy-me-mcp_ntfy_me({
  taskTitle: "Planning Complete",
  taskSummary: "PRD 기반으로 총 X개 작업이 생성되고 GitHub 이슈로 동기화되었습니다. 작업 계획을 검토해주세요.",
  priority: "high",
  tags: ["planning", "review-needed", "github"]
})
```

## 🎯 메인 작업 실행 워크플로우

### 작업 선택 및 시작
```typescript
// 1. 다음 작업 확인 (한 번에 하나만!)
next_task

// 2. 작업 복잡도 확인 및 분해 결정
get_task --id=X

// 복잡도에 따른 분기:
// - 8-10점: 반드시 하위 작업으로 분해
// - 5-7점: 분해 권장 
// - 1-4점: 바로 실행 가능

// 3. 필요시 작업 확장
expand_task --id=X --research

// 4. GitHub 브랜치 생성
mcp_github_create_branch({
  branch: `feature/task-${taskId}`,
  from_branch: "main"
})

// 5. 작업 시작 표시
set_task_status --id=X --status="in-progress"

// 6. 작업 시작 알림
mcp_ntfy-me-mcp_ntfy_me({
  taskTitle: "Task Started",
  taskSummary: "작업 '${taskTitle}'을 시작했습니다. GitHub 브랜치: feature/task-${taskId}",
  priority: "default",
  tags: ["task-start", "github", "development"]
})
```

### 하위 작업 분할 실행 전략

#### 🎯 하위 작업이 5개 이하인 경우
```typescript
// 전체 하위 작업을 한 번에 진행
get_task --id=X  // 모든 하위 작업 확인

// 각 하위 작업별 진행
set_task_status --id=X.1 --status="in-progress"
// 구현 작업...
update_subtask --id=X.1 --prompt="진행 상황 기록"
set_task_status --id=X.1 --status="done"

// 중간 진행 상황 업데이트 (2-3개 하위 작업마다)
update_subtask --id=X.2 --prompt="중간 진행 상황: X.1, X.2 완료. 다음: X.3"
```

#### 🔄 하위 작업이 6개 이상인 경우
```typescript
// 하위 작업을 2-3개씩 배치로 나누어 진행

// 1차 배치 (처음 3개)
get_task --id=X
// X.1, X.2, X.3만 집중해서 완료

// 1차 배치 완료 알림
mcp_ntfy-me-mcp_ntfy_me({
  taskTitle: "Batch 1 Complete",
  taskSummary: "작업 X의 1차 배치(하위 작업 3개)가 완료되었습니다. 2차 배치를 계속 진행하시겠습니까?",
  priority: "default",
  tags: ["batch-complete", "progress"]
})

// 2차 배치 (다음 3개)
// X.4, X.5, X.6 진행...

// 최종 완료 후 통합
```

## 📊 작업 완료 및 브리핑 워크플로우

### 메인 작업 완료 시
```typescript
// 1. 모든 하위 작업 완료 확인
get_task --id=X

// 2. 최종 코드 커밋 및 푸시
// GitHub에서 코드 작업 완료...

// 3. Pull Request 생성
mcp_github_create_pull_request({
  title: `[Task-${taskId}] ${taskTitle}`,
  head: `feature/task-${taskId}`,
  base: "main",
  body: `
  ## 작업 완료 보고서
  
  ### 완료된 하위 작업들
  ${subtasks.map(st => `- [x] ${st.title}`).join('\n')}
  
  ### 주요 변경사항
  - 구현된 기능: [상세 설명]
  - 수정된 파일: [파일 목록]
  - 테스트 결과: [테스트 상황]
  
  ### Taskmaster 정보
  - 메인 작업 ID: ${taskId}
  - 완료 일시: ${new Date().toISOString()}
  
  Closes #${githubIssueNumber}
  `
})

// 4. Taskmaster에서 작업 완료 표시
set_task_status --id=X --status="done"

// 5. GitHub 이슈 업데이트
mcp_github_add_issue_comment({
  issue_number: githubIssueNumber,
  body: `
  ✅ **작업 완료!**
  
  모든 하위 작업이 완료되었습니다.
  Pull Request: #${prNumber}
  
  **완료 요약:**
  ${completionSummary}
  `
})
```

### 완료 브리핑 및 알림
```typescript
// 상세 브리핑 생성
const briefing = `
## 📋 작업 완료 브리핑

### 🎯 완료된 작업
**${taskTitle}** (작업 ID: ${taskId})

### ✅ 완료된 하위 작업들
${completedSubtasks.map(st => `- ${st.title}: ${st.status}`).join('\n')}

### 📊 성과 지표
- 총 소요 시간: ${totalTime}
- 완료된 하위 작업: ${completedCount}개
- 코드 변경 파일: ${changedFiles}개
- 테스트 통과율: ${testPassRate}%

### 🔗 GitHub 연동
- Pull Request: #${prNumber}
- 브랜치: feature/task-${taskId}
- 관련 이슈: #${issueNumber}

### 📈 프로젝트 진행률
- 전체 진행률: ${overallProgress}%
- 완료된 메인 작업: ${completedMainTasks}개
- 남은 메인 작업: ${remainingMainTasks}개

### 🚀 다음 단계
${nextSteps}
`;

// 완료 알림 발송
mcp_ntfy-me-mcp_ntfy_me({
  taskTitle: "Major Task Complete",
  taskSummary: briefing,
  priority: "high",
  tags: ["task-complete", "github", "milestone", "celebration"]
})
```

## 🔄 GitHub 연동 자동화 패턴

### 이슈 관리 자동화
```typescript
// 작업 시작 시
mcp_github_update_issue({
  issue_number: issueNumber,
  body: updatedDescription,
  labels: ["in-progress", "taskmaster"]
})

// 진행 상황 업데이트
mcp_github_add_issue_comment({
  issue_number: issueNumber,
  body: `🔄 진행 상황 업데이트\n\n${progressUpdate}`
})

// 완료 시
mcp_github_update_issue({
  issue_number: issueNumber,
  state: "closed",
  labels: ["completed", "taskmaster"]
})
```

### 브랜치 관리 전략
```typescript
// 메인 작업별 브랜치 네이밍
const branchName = `feature/task-${taskId}-${taskTitle.toLowerCase().replace(/\s+/g, '-')}`;

// 하위 작업이 많을 경우 배치별 브랜치
const batchBranchName = `feature/task-${taskId}-batch-${batchNumber}`;

// 최종 통합은 메인 브랜치에서
```

## 📈 진행 상황 추적 및 리포팅

### 주간 리뷰 자동화
```typescript
// 매주 금요일 자동 진행 상황 리포트
const weeklyReport = `
## 📊 주간 진행 리포트

### 이번 주 완료 작업
${weeklyCompletedTasks}

### GitHub 활동
- 생성된 PR: ${weeklyPRs}개
- 머지된 커밋: ${weeklyCommits}개
- 해결된 이슈: ${weeklyClosedIssues}개

### 다음 주 계획
${nextWeekPlan}
`;

mcp_ntfy-me-mcp_ntfy_me({
  taskTitle: "Weekly Progress Report",
  taskSummary: weeklyReport,
  priority: "default",
  tags: ["weekly-report", "progress", "github"]
})
```

### 마일스톤 추적
```typescript
// 주요 마일스톤 달성 시
mcp_ntfy-me-mcp_ntfy_me({
  taskTitle: "Milestone Achieved",
  taskSummary: `🎉 주요 마일스톤 달성!\n\n${milestoneDescription}\n\n완료된 작업들:\n${milestoneAchievements}`,
  priority: "high",
  tags: ["milestone", "celebration", "achievement"]
})
```

## 🛠️ 팀 협업 워크플로우

### 코드 리뷰 요청
```typescript
// PR 생성 후 리뷰 요청
mcp_github_create_pull_request({
  // ... PR 생성 옵션
  body: prBody + `\n\n@팀원 리뷰 요청드립니다! 🙏`
})

// 리뷰 요청 알림
mcp_ntfy-me-mcp_ntfy_me({
  taskTitle: "Review Requested",
  taskSummary: "작업 완료 후 코드 리뷰를 요청했습니다. 리뷰어의 피드백을 기다리고 있습니다.",
  priority: "default",
  tags: ["review-requested", "collaboration"]
})
```

### 충돌 해결 워크플로우
```typescript
// 머지 충돌 발생 시
mcp_ntfy-me-mcp_ntfy_me({
  taskTitle: "Merge Conflict Detected",
  taskSummary: "머지 충돌이 발생했습니다. 수동 해결이 필요합니다.",
  priority: "high",
  tags: ["conflict", "urgent", "action-required"]
})
```

## ⚠️ 주의사항 및 모범 사례

### 🎯 작업 분할 가이드라인
- **메인 작업**: 한 번에 하나씩만 진행
- **하위 작업 5개 이하**: 한 번에 처리
- **하위 작업 6-10개**: 2개 배치로 분할
- **하위 작업 11개 이상**: 3개 배치로 분할 또는 메인 작업 재분해 고려

### 📋 브리핑 필수 포함 사항
- 완료된 기능의 구체적 설명
- 변경된 파일 및 코드 라인 수
- 테스트 결과 및 검증 상황
- GitHub PR 및 이슈 번호
- 다음 작업에 미치는 영향
- 예상 일정 업데이트

### 🔔 알림 우선순위 설정
- **High**: 작업 완료, 에러 발생, 리뷰 필요
- **Default**: 작업 시작, 진행 상황, 배치 완료
- **Low**: 일반 업데이트, 주간 리포트

### 🔄 GitHub 연동 체크리스트
- [ ] 메인 작업마다 GitHub 이슈 생성
- [ ] 작업별 전용 브랜치 생성
- [ ] PR에 상세한 작업 완료 보고서 포함
- [ ] 이슈와 PR 적절히 연결 (Closes #번호)
- [ ] 라벨을 통한 작업 상태 관리

이 워크플로우를 통해 GitHub 프로젝트에서 체계적이고 효율적인 개발을 진행하세요! 🚀
