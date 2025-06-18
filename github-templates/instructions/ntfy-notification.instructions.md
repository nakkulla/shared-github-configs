---
description: "ntfy MCP를 활용한 작업 완료 및 피드백 알림 가이드"
applyTo: "**"
---

# ntfy MCP 알림 가이드

## 🚀 핵심 원칙

- **작업 완료 시 필수 알림**: 모든 주요 작업이 완료되면 ntfy로 알림 전송
- **피드백 요청 시 알림**: 사용자 승인이나 피드백이 필요한 경우 즉시 알림
- **영어 헤더 사용**: ntfy 헤더 문제 방지를 위해 taskTitle은 영어로 작성
- **한국어 내용**: taskSummary는 한국어로 상세하게 작성

## 📋 필수 알림 시나리오

### 1. 작업 완료 알림
```typescript
// Taskmaster 작업 완료 후
set_task_status --id=X --status="done"

// 즉시 ntfy 알림 전송
mcp_ntfy-me-mcp_ntfy_me({
  taskTitle: "Task Completed", // 영어 필수
  taskSummary: "작업 [작업명]이 성공적으로 완료되었습니다. 다음 작업을 진행하시겠습니까?",
  priority: "default",
  tags: ["task-complete", "success"]
})
```

### 2. 피드백 요청 알림
```typescript
// PRD 파싱 완료 후 브리핑 전
parse_prd
get_tasks
analyze_project_complexity --research

// 피드백 요청 알림
mcp_ntfy-me-mcp_ntfy_me({
  taskTitle: "Feedback Required", // 영어 필수
  taskSummary: "PRD 기반으로 총 X개 작업이 생성되었습니다. 복잡도 분석이 완료되어 브리핑을 준비했습니다. 계속 진행하시겠습니까?",
  priority: "high",
  tags: ["feedback", "review", "prd"]
})
```

### 3. 오류 발생 알림
```typescript
// 오류나 막힘 상황 발생 시
set_task_status --id=X.Y --status="blocked"

mcp_ntfy-me-mcp_ntfy_me({
  taskTitle: "Issue Detected", // 영어 필수
  taskSummary: "작업 중 문제가 발생했습니다: [구체적인 문제 설명]. 도움이 필요합니다.",
  priority: "high",
  tags: ["error", "blocked", "help-needed"]
})
```

### 4. 중요 결정점 알림
```typescript
// 기술적 선택이나 아키텍처 결정 필요 시
mcp_ntfy-me-mcp_ntfy_me({
  taskTitle: "Decision Required", // 영어 필수
  taskSummary: "중요한 기술적 결정이 필요합니다: [결정 내용]. Sequential thinking 분석을 완료했습니다.",
  priority: "high",
  tags: ["decision", "architecture", "review"]
})
```

## 🔄 Taskmaster 워크플로우와 ntfy 연동

### 1. 프로젝트 시작 시 알림 패턴
```typescript
// 1. 프로젝트 초기화 완료
initialize_project
mcp_ntfy-me-mcp_ntfy_me({
  taskTitle: "Project Initialized",
  taskSummary: "새 프로젝트가 초기화되었습니다. PRD 작성을 시작하세요.",
  priority: "default",
  tags: ["init", "start"]
})

// 2. PRD 파싱 및 복잡도 분석 완료
parse_prd
analyze_project_complexity --research
mcp_ntfy-me-mcp_ntfy_me({
  taskTitle: "Analysis Complete",
  taskSummary: "PRD 파싱과 복잡도 분석이 완료되었습니다. 작업 계획을 검토해주세요.",
  priority: "high",
  tags: ["analysis", "review-needed"]
})

// 3. 개발 시작 준비 완료
next_task
mcp_ntfy-me-mcp_ntfy_me({
  taskTitle: "Ready to Start",
  taskSummary: "모든 준비가 완료되었습니다. 첫 번째 작업을 시작하겠습니다.",
  priority: "default",
  tags: ["ready", "development"]
})
```

### 2. 개발 사이클 알림 패턴
```typescript
// 복잡한 작업 시작 시
expand_task --id=X --research
mcp_ntfy-me-mcp_ntfy_me({
  taskTitle: "Complex Task Expanded",
  taskSummary: "작업 X가 Y개의 하위 작업으로 확장되었습니다. 계획을 검토해주세요.",
  priority: "default",
  tags: ["expand", "review"]
})

// 중요 하위 작업 완료 시
set_task_status --id=X.Y --status="done"
mcp_ntfy-me-mcp_ntfy_me({
  taskTitle: "Milestone Reached",
  taskSummary: "핵심 하위 작업이 완료되었습니다. 다음 단계로 진행합니다.",
  priority: "default",
  tags: ["milestone", "progress"]
})

// 전체 작업 완료 시
set_task_status --id=X --status="done"
mcp_ntfy-me-mcp_ntfy_me({
  taskTitle: "Major Task Complete",
  taskSummary: "주요 작업이 완료되었습니다. 테스트 결과와 다음 작업을 확인해주세요.",
  priority: "high",
  tags: ["complete", "next-action"]
})
```

### 3. 연구 및 분석 완료 알림
```typescript
// Sequential thinking 분석 완료
mcp_sequential-thinking_sequentialthinking
mcp_ntfy-me-mcp_ntfy_me({
  taskTitle: "Analysis Complete",
  taskSummary: "복잡한 문제 분석이 완료되었습니다. 결과를 검토하고 방향을 결정해주세요.",
  priority: "high",
  tags: ["analysis", "decision-needed"]
})

// 최신 기술 조사 완료
research --query="..."
mcp_ntfy-me-mcp_ntfy_me({
  taskTitle: "Research Complete",
  taskSummary: "기술 조사가 완료되었습니다. 최신 동향과 구현 방향을 제안합니다.",
  priority: "default",
  tags: ["research", "recommendation"]
})
```

## 🎯 알림 우선순위 가이드

### High Priority (즉시 확인 필요)
- **피드백 요청**: 사용자 승인이나 결정이 필요한 경우
- **오류 발생**: 작업이 막히거나 문제가 발생한 경우
- **중요 완료**: 핵심 기능이나 마일스톤 완료
- **보안 이슈**: 보안 관련 문제 발견

### Default Priority (일반 진행 상황)
- **작업 완료**: 일반적인 작업 완료
- **진행 상황**: 정기적인 진행 보고
- **준비 완료**: 다음 단계 준비 완료

### Low Priority (참고 정보)
- **시작 알림**: 새 작업 시작
- **설정 변경**: 환경 설정 변경
- **문서 업데이트**: 문서화 완료

## 📱 알림 내용 작성 가이드

### taskTitle 작성 규칙 (영어 필수)
```typescript
// ✅ 좋은 예시
"Task Completed"
"Feedback Required"
"Error Detected"
"Analysis Complete"
"Decision Needed"
"Milestone Reached"

// ❌ 피해야 할 예시 (한국어 또는 특수문자)
"작업 완료"
"피드백 필요!"
"오류 발생!!!"
```

### taskSummary 작성 규칙 (한국어)
```typescript
// ✅ 상세하고 구체적인 한국어 작성
taskSummary: `
작업 "사용자 인증 시스템 구현"이 완료되었습니다.

완료된 내용:
- JWT 토큰 기반 인증 구현
- 로그인/로그아웃 기능 완료
- 권한 관리 시스템 구축

다음 작업: "사용자 프로필 관리" 
예상 소요 시간: 2시간

계속 진행하시겠습니까?
`

// ❌ 너무 간단한 설명
taskSummary: "작업 완료됨"
```

### 태그 활용 가이드
```typescript
// 기능별 태그
tags: ["auth", "api", "frontend", "backend"]

// 상태별 태그  
tags: ["complete", "in-progress", "blocked", "review"]

// 우선순위별 태그
tags: ["urgent", "important", "routine"]

// 액션별 태그
tags: ["feedback-needed", "decision-required", "help-needed"]
```

## 🔧 실제 적용 예시

### 완전한 Taskmaster + ntfy 워크플로우
```typescript
// 1. 프로젝트 시작
initialize_project
mcp_ntfy-me-mcp_ntfy_me({
  taskTitle: "Project Setup Complete",
  taskSummary: "mcp-notification 프로젝트가 초기화되었습니다. .taskmaster/docs/prd.txt 파일을 작성해주세요.",
  priority: "default",
  tags: ["setup", "next-step"]
})

// 2. PRD 작성 후 파싱
parse_prd
analyze_project_complexity --research
complexity_report
mcp_ntfy-me-mcp_ntfy_me({
  taskTitle: "Ready for Review",
  taskSummary: "PRD 기반으로 8개 작업이 생성되었습니다. 복잡도 분석 완료. 고우선순위 작업 3개, 중간우선순위 3개, 저우선순위 2개입니다. 작업 계획을 검토하고 승인해주세요.",
  priority: "high",
  tags: ["prd-complete", "review-needed", "approval"]
})

// 3. 승인 후 개발 시작
next_task
set_task_status --id=1 --status="in-progress"
mcp_ntfy-me-mcp_ntfy_me({
  taskTitle: "Development Started",
  taskSummary: "첫 번째 작업 '프로젝트 구조 설계'를 시작했습니다. 예상 완료 시간: 1시간",
  priority: "default",
  tags: ["started", "development"]
})

// 4. 작업 완료 및 다음 작업 안내
set_task_status --id=1 --status="done"
next_task
mcp_ntfy-me-mcp_ntfy_me({
  taskTitle: "Task 1 Complete",
  taskSummary: "프로젝트 구조 설계가 완료되었습니다. 다음 작업 'MCP 서버 구현'을 시작하겠습니다. 계속 진행하시겠습니까?",
  priority: "default",
  tags: ["complete", "next-task", "continue"]
})
```

## ⚠️ 주의사항

### 헤더 문제 방지
- **taskTitle은 반드시 영어로 작성**: ntfy 헤더 인코딩 문제 방지
- **특수문자 사용 금지**: 감탄표, 한글, 이모지 등 사용 금지
- **간단명료하게**: 50자 이내로 핵심 내용만 포함

### 알림 빈도 관리
- **중요한 시점에만 발송**: 모든 작업마다 알림 보내지 말 것
- **배치 알림 활용**: 여러 하위 작업 완료 시 묶어서 알림
- **사용자 피로도 고려**: 하루 10개 이내로 제한

### 내용 품질 관리
- **구체적인 정보 포함**: 무엇이 완료되었고 다음에 무엇을 할지 명확히
- **액션 아이템 포함**: 사용자가 해야 할 행동을 명시
- **컨텍스트 제공**: 전체 프로젝트에서의 위치와 중요도 설명

이 가이드를 통해 효과적인 ntfy 알림 시스템을 구축하여 원활한 개발 워크플로우를 유지하세요!
