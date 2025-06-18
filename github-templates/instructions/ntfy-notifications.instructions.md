---
description: "ntfy 알림 시스템 및 피드백 요청 가이드"
applyTo: "**"
---

# ntfy 알림 시스템

## 🔔 핵심 원칙

- **영어 헤더 필수**: taskTitle은 반드시 영어로 (헤더 인코딩 문제 방지)
- **한국어 내용**: taskSummary는 상세한 한국어로 작성
- **필수 시점 알림**: 완료, 피드백 요청, 오류 발생시만
- **과도한 알림 금지**: 하루 10개 이내로 제한

## 📋 필수 알림 시점

### 1. PRD 분석 완료 (피드백 요청)
```typescript
parse_prd
analyze_project_complexity --research

ntfy_me({
  taskTitle: \"Planning Complete\",  // 영어 필수
  taskSummary: \"PRD 기반으로 총 X개 작업이 생성되었습니다. 복잡도 분석이 완료되어 브리핑을 준비했습니다. 계속 진행하시겠습니까?\",
  priority: \"high\",
  tags: [\"planning\", \"review\", \"feedback-needed\"]
})
```

### 2. 큰 작업 완료 (다음 진행 확인)
```typescript
set_task_status --id=X --status=\"done\"

ntfy_me({
  taskTitle: \"Major Task Complete\",  // 영어 필수
  taskSummary: `작업 \"${taskTitle}\"이 성공적으로 완료되었습니다.

📊 완료 내용:
- 완료 하위작업: ${completedSubtasks}개
- 소요 시간: ${duration}
- 주요 결과: ${mainResults}

🎯 다음 작업: \"${nextTask}\"
계속 진행하시겠습니까?`,
  priority: \"default\",
  tags: [\"complete\", \"next-action\", \"briefing\"]
})
```

### 3. 복잡한 작업 분해 (계획 확인)
```typescript
expand_task --id=X --research

ntfy_me({
  taskTitle: \"Task Expanded\",  // 영어 필수
  taskSummary: `작업 \"${taskTitle}\"이 ${subtaskCount}개의 하위 작업으로 확장되었습니다.

분해된 하위 작업들:
${subtaskList}

이 계획이 적절한지 확인해주세요.`,
  priority: \"default\",
  tags: [\"expand\", \"review\", \"planning\"]
})
```

### 4. 오류 발생 (도움 요청)
```typescript
set_task_status --id=X --status=\"blocked\"

ntfy_me({
  taskTitle: \"Help Needed\",  // 영어 필수
  taskSummary: `작업 중 문제가 발생했습니다.

🚨 문제 상황: ${errorDescription}
🔍 시도한 해결책: ${attemptedSolutions}
🆘 필요한 도움: ${helpNeeded}

긴급히 확인해주세요.`,
  priority: \"high\",
  tags: [\"error\", \"blocked\", \"urgent\"]
})
```

## 🎯 알림 우선순위 가이드

### High Priority (즉시 확인 필요)
- **피드백 요청**: PRD 브리핑, 중요 결정 필요
- **오류 발생**: 작업 막힘, 긴급 문제
- **중요 완료**: 핵심 마일스톤 달성

```typescript
priority: \"high\"
tags: [\"feedback\", \"error\", \"urgent\", \"milestone\"]
```

### Default Priority (일반 진행 상황)
- **작업 완료**: 일반 작업 완료
- **작업 확장**: 하위 작업 분해 완료
- **진행 보고**: 중간 진행 상황

```typescript
priority: \"default\"
tags: [\"complete\", \"progress\", \"expand\"]
```

## 📝 알림 작성 규칙

### taskTitle 규칙 (영어 필수)
```typescript
// ✅ 올바른 예시
\"Task Complete\"
\"Planning Complete\"
\"Help Needed\"
\"Decision Required\"
\"Milestone Reached\"

// ❌ 피해야 할 예시 (한국어, 특수문자, 이모지)
\"작업 완료\"
\"피드백 필요!\"
\"🚨 오류 발생\"
\"Planning Complete!!!\"
```

### taskSummary 규칙 (한국어 상세)
```typescript
// ✅ 상세하고 구체적인 한국어
taskSummary: `
작업 \"사용자 인증 시스템 구현\"이 완료되었습니다.

📊 완료
완료된 내용:
- JWT 토큰 기반 인증 구현
- 로그인/로그아웃 기능 완료
- 권한 관리 시스템 구축

🎯 다음 작업: "사용자 프로필 관리"
예상 소요 시간: 2시간

계속 진행하시겠습니까?`

// ❌ 너무 간단한 설명
taskSummary: "작업 완료됨"
```

### 태그 활용 패턴
```typescript
// 기능별 태그
tags: ["auth", "api", "frontend", "backend"]

// 상태별 태그
tags: ["complete", "in-progress", "blocked", "review"]

// 액션별 태그
tags: ["feedback-needed", "decision-required", "help-needed", "briefing"]

// 우선순위별 태그
tags: ["urgent", "important", "routine"]
```

## 🔄 Taskmaster 워크플로우별 알림 패턴

### 프로젝트 시작 알림 시퀀스
```typescript
// 1. 프로젝트 초기화 완료
initialize_project
ntfy_me({
  taskTitle: "Project Initialized",
  taskSummary: "새 프로젝트가 초기화되었습니다. PRD 작성을 시작하세요.",
  priority: "default",
  tags: ["init", "start"]
})

// 2. PRD 분석 완료 (중요!)
parse_prd
analyze_project_complexity --research
ntfy_me({
  taskTitle: "Analysis Complete",
  taskSummary: "PRD 파싱과 복잡도 분석이 완료되었습니다. 작업 계획을 검토해주세요.",
  priority: "high",
  tags: ["analysis", "review-needed", "feedback"]
})

// 3. 승인 후 개발 시작
ntfy_me({
  taskTitle: "Development Started",
  taskSummary: "모든 준비가 완료되었습니다. 첫 번째 작업을 시작하겠습니다.",
  priority: "default",
  tags: ["ready", "development"]
})
```

### 작업 진행 중 알림 패턴
```typescript
// 1. 복잡한 작업 확장 시
expand_task --id=X --research
ntfy_me({
  taskTitle: "Complex Task Expanded",
  taskSummary: `작업 "${taskTitle}"이 ${subtaskCount}개의 하위 작업으로 확장되었습니다. 계획을 검토해주세요.`,
  priority: "default",
  tags: ["expand", "review"]
})

// 2. 배치 완료 시 (하위 작업 6개 이상인 경우)
ntfy_me({
  taskTitle: "Batch Complete",
  taskSummary: `작업 X의 1차 배치(하위 작업 3개)가 완료되었습니다. 2차 배치를 계속 진행하시겠습니까?`,
  priority: "default",
  tags: ["batch-complete", "progress"]
})

// 3. 전체 작업 완료 시
set_task_status --id=X --status="done"
ntfy_me({
  taskTitle: "Major Task Complete",
  taskSummary: `주요 작업이 완료되었습니다. 테스트 결과와 다음 작업을 확인해주세요.`,
  priority: "high",
  tags: ["complete", "next-action", "briefing"]
})
```

## 📊 특수 상황별 알림

### Sequential Thinking 분석 완료
```typescript
sequentialthinking()
ntfy_me({
  taskTitle: "Analysis Complete",
  taskSummary: "복잡한 문제 분석이 완료되었습니다. 결과를 검토하고 방향을 결정해주세요.",
  priority: "high",
  tags: ["analysis", "decision-needed", "review"]
})
```

### 연구 조사 완료
```typescript
research --query="..."
ntfy_me({
  taskTitle: "Research Complete",
  taskSummary: "기술 조사가 완료되었습니다. 최신 동향과 구현 방향을 제안합니다.",
  priority: "default",
  tags: ["research", "recommendation"]
})
```

### GitHub 연동 완료
```typescript
create_pull_request()
ntfy_me({
  taskTitle: "PR Created",
  taskSummary: `Pull Request가 생성되었습니다. 코드 리뷰를 요청합니다.\n\nPR: #${prNumber}\n브랜치: ${branchName}`,
  priority: "default",
  tags: ["github", "review-requested"]
})
```

## ⚠️ 알림 관리 주의사항

### 알림 빈도 제한
- **일일 제한**: 최대 10개 알림
- **중요 알림 우선**: High priority를 남발하지 말 것
- **배치 처리**: 유사한 내용은 묶어서 발송

### 피해야 할 알림 패턴
```typescript
// ❌ 너무 빈번한 알림
update_subtask() // 하위 작업마다 알림 X
set_task_status() // 상태 변경마다 알림 X

// ❌ 불필요한 알림
"Task Started" // 시작 알림은 복잡한 작업만
"File Saved"   // 파일 저장 알림 X
"Debug Info"   // 디버그 정보 알림 X

// ✅ 적절한 알림 시점
"Major Task Complete"  // 큰 작업 완료
"Feedback Required"    // 피드백 요청
"Error Occurred"       // 오류 발생
```

### 내용 품질 관리
- **구체적 정보**: 무엇이 완료되었고 다음에 무엇을 할지 명확히
- **액션 아이템**: 사용자가 해야 할 행동을 명시
- **컨텍스트 제공**: 전체 프로젝트에서의 위치와 중요도
- **적절한 길이**: 너무 길거나 짧지 않게

## ✅ ntfy 알림 체크리스트

### 기본 규칙 체크리스트
- [ ] taskTitle은 영어로 작성
- [ ] taskSummary는 상세한 한국어로 작성
- [ ] 적절한 priority 설정 (high/default)
- [ ] 관련 tags 포함

### 내용 품질 체크리스트
- [ ] 완료된 내용 구체적으로 설명
- [ ] 다음 단계 명확히 제시
- [ ] 필요한 액션 명시
- [ ] 전체 맥락에서의 위치 설명

### 시점 적절성 체크리스트
- [ ] 중요한 완료 시점에만 발송
- [ ] 피드백이 실제로 필요한 경우만
- [ ] 오류나 막힘 상황에서만
- [ ] 하루 10개 이내 제한 준수

---

이 가이드를 통해 효과적인 ntfy 알림 시스템으로 원활한 개발 워크플로우를 유지하세요! 🔔
