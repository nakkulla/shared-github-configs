---
description: "Taskmaster MCP 핵심 워크플로우 및 작업 관리 가이드"
applyTo: "**"
---

# Taskmaster 핵심 워크플로우

## 🎯 핵심 원칙

- **한국어 우선**: 모든 작업, 주석, 문서는 한국어로 작성
- **큰 작업 단위**: 메인 작업 하나씩 순차적으로 완료
- **완료 시 브리핑**: 작업 완료 후 상세 브리핑 + 다음 진행 확인
- **Gemini 모델 필수**: 비용 효율성을 위해 Gemini 사용

## 🚀 필수 도구 (핵심만)

### 프로젝트 관리
```typescript
initialize_project              // 프로젝트 초기화
parse_prd                      // PRD → 작업 생성  
get_tasks                      // 작업 목록 조회
get_task --id=X               // 특정 작업 상세 (여러 ID 가능: --id=1,2,3)
next_task                     // 다음 작업 추천
```

### 작업 실행
```typescript
set_task_status --id=X --status="pending|in-progress|done"
expand_task --id=X --research     // 복잡한 작업 → 하위 작업 분해
update_subtask --id=X.Y --prompt="진행상황"
analyze_project_complexity --research
```

### 모델 설정 (⚠️ 필수)
```typescript
models --setMain="gemini-2.5-flash-preview-04-17"  // 초기화 후 즉시 실행
```

## 📋 핵심 워크플로우

### 1단계: 프로젝트 시작
```typescript
// 1. 초기화 및 모델 설정
initialize_project
models --setMain="gemini-2.5-flash-preview-04-17"  // 필수!

// 2. PRD 작성 (.taskmaster/docs/prd.txt)
// - 핵심 기능만 명확한 한국어로
// - 과도한 디테일 금지

// 3. 작업 생성 및 분석
parse_prd
analyze_project_complexity --research

// 4. 브리핑 준비
get_tasks
complexity_report
```

**⚠️ 중요**: PRD 파싱 후 바로 개발 시작하지 말고 반드시 브리핑 먼저!

### 2단계: 큰 작업 진행 전략

#### 🎯 작업 선택 기준
- **하나씩 완료**: 여러 작업 동시 진행 금지
- **복잡도 우선**: 8-10점 작업 먼저 처리  
- **의존성 고려**: 선행 작업 완료 후 진행

#### 🔄 작업 진행 패턴
```typescript
// 1. 작업 시작
next_task
get_task --id=X                    // 작업 상세 확인
set_task_status --id=X --status="in-progress"

// 2. 복잡한 작업 분해 (복잡도 6점 이상)
expand_task --id=X --research

// 3. 하위 작업 진행 전략
// - 5개 이하: 한번에 처리
// - 6개 이상: 2-3개씩 배치 처리

// 4. 진행 상황 기록
update_subtask --id=X.Y --prompt="구체적인 진행상황 (한국어)"

// 5. 작업 완료
set_task_status --id=X --status="done"
```

### 3단계: 하위 작업 관리

#### 📊 하위 작업 수에 따른 전략

**5개 이하 → 한번에 처리**
```typescript
get_task --id=X                    // 모든 하위 작업 확인
// X.1, X.2, X.3, X.4, X.5 순차적으로 완료
```

**6개 이상 → 배치 처리**
```typescript
// 1차 배치 (첫 3개)
get_task --id=X
// X.1, X.2, X.3만 집중 완료 후 브리핑

// 2차 배치 (다음 3개)  
// X.4, X.5, X.6 완료 후 최종 통합
```

#### 🔍 진행 상황 기록 패턴
```typescript
update_subtask --id=X.Y --prompt="
완료된 부분: [구체적 설명]
현재 작업 중: [진행 내용]  
발견한 이슈: [문제점과 해결방안]
예상 완료 시간: [시간 추정]
"
```

## 📊 브리핑 템플릿

### PRD 분석 완료 브리핑
```typescript
"PRD 기반으로 총 X개의 작업이 생성되었습니다.

복잡도 분석 결과:
[고우선순위] (8-10점)
- 작업 1: 제목 (복잡도: X/10)
- 작업 2: 제목 (복잡도: X/10)

[중간우선순위] (5-7점)  
- 작업 3: 제목 (복잡도: X/10)

[저우선순위] (1-4점)
- 작업 4: 제목 (복잡도: X/10)

전체 예상 소요 시간: X시간
이 계획에 대해 피드백을 주시면 조정하겠습니다."
```

### 큰 작업 완료 브리핑
```typescript
"작업 완료: ${taskTitle}

📊 완료 내용:
- 완료 하위작업: ${completedSubtasks}개
- 소요 시간: ${duration}
- 주요 결과: ${mainResults}

📈 프로젝트 진행률: ${progress}%
🎯 다음 작업: ${nextTask}

계속 진행하시겠습니까?"
```

## ✅ 핵심 체크리스트

### 프로젝트 시작 체크리스트
- [ ] `initialize_project` 실행
- [ ] Gemini 모델로 변경 확인
- [ ] PRD 작성 (핵심 기능만)
- [ ] `parse_prd` + `analyze_project_complexity` 실행
- [ ] 브리핑 후 사용자 승인 받기

### 작업 진행 체크리스트  
- [ ] 한 번에 하나의 큰 작업만 진행
- [ ] 복잡도 6점 이상 → `expand_task` 실행
- [ ] 하위 작업 5개 초과 → 배치로 나누어 진행
- [ ] 진행 상황 `update_subtask`로 기록
- [ ] 완료 시 브리핑 후 다음 작업 확인

## 🔧 트러블슈팅

### 자주 발생하는 문제
1. **작업 복잡도 과다** → `expand_task --research`로 분해
2. **하위 작업 조회 불가** → 부모 작업 `get_task --id=X`로 조회
3. **의존성 문제** → `validate_dependencies` 실행
4. **진행 상황 미추적** → `update_subtask` 활용

### 응급 대응
```typescript
// 막힌 상황 시
set_task_status --id=X --status="blocked"
update_subtask --id=X.Y --prompt="문제 상황: [구체적 설명]"
```

---

이 가이드를 통해 Taskmaster의 핵심 기능에 집중하여 체계적인 작업 관리를 하세요! 🚀