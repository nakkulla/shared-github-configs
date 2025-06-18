---
description: "Taskmaster MCP 및 개발 워크플로우 핵심 가이드"
applyTo: "**"
---

# Taskmaster MCP 개발 가이드

## 🚀 핵심 원칙

- **한국어 우선**: 모든 작업, 주석, 문서는 한국어로 작성
- **MCP 도구 우선**: CLI보다 MCP 도구를 먼저 활용
- **체계적 워크플로우**: PRD → 브리핑 → 승인 → 개발 순서 준수
- **AI 도구 적극 활용**: sequentialthinking, research, complexity 분석 활용
- **ntfy 알림 필수**: 작업 완료 및 피드백 요청 시 즉시 알림 전송

## 📋 Taskmaster 필수 도구

### 프로젝트 관리
- **`initialize_project`**: 새 프로젝트 초기화
- **`parse_prd`**: PRD 문서로부터 작업 생성
- **`get_tasks`**: 작업 목록 조회
- **`get_task`**: 특정 작업 상세 조회 (쉼표로 다중 조회 가능)
- **`next_task`**: 다음 작업 추천

### 작업 상태 관리
- **`set_task_status`**: 작업 상태 변경 (pending, in-progress, done, review, cancelled)
- **`add_task`**: 새 작업 추가 (AI 기반, 한국어 프롬프트)
- **`update_task`**: 작업 내용 업데이트 (AI 기반)
- **`update_subtask`**: 하위 작업에 진행사항 추가
- **`expand_task`**: 복잡한 작업을 하위 작업으로 분해

### 분석 및 최적화
- **`analyze_project_complexity`**: 작업 복잡도 분석 (--research 옵션 활용)
- **`complexity_report`**: 복잡도 분석 결과 조회
- **`research`**: AI 기반 최신 정보 수집

### 알림 관리
- **`mcp_ntfy-me-mcp_ntfy_me`**: 작업 완료 및 피드백 요청 알림 (영어 헤더 필수)

## 🔄 핵심 워크플로우

### 1. 프로젝트 시작 (필수 단계)
```typescript
// 1. 프로젝트 초기화
initialize_project

// ⚠️ 초기화 완료 알림 (필수)
mcp_ntfy-me-mcp_ntfy_me({
  taskTitle: "Project Initialized",
  taskSummary: "새 프로젝트가 초기화되었습니다. PRD 작성을 시작하세요.",
  priority: "default",
  tags: ["init", "start"]
})

// 2. 모델 설정을 Gemini로 변경 (⚠️ 필수!)
models                                          // 현재 설정 확인
models --setMain="gemini-2.5-flash-preview-04-17"  // Gemini로 변경
models                                          // 변경 확인

// 3. 한국어 PRD 작성 (.taskmaster/docs/prd.txt)
// - 프로젝트 개요와 목표를 명확한 한국어로 작성
// - 기능 요구사항은 사용자 관점에서 한국어로 서술

// 4. PRD 기반 작업 생성
parse_prd

// 5. 작업 브리핑 및 피드백 (⚠️ 중요: 바로 개발 시작하지 말 것!)
get_tasks                              // 전체 작업 목록 확인
analyze_project_complexity --research  // 복잡도 분석
complexity_report                      // 분석 결과 검토

// ⚠️ 피드백 요청 알림 (필수)
mcp_ntfy-me-mcp_ntfy_me({
  taskTitle: "Feedback Required",
  taskSummary: "PRD 기반으로 총 X개 작업이 생성되었습니다. 복잡도 분석이 완료되어 브리핑을 준비했습니다. 계속 진행하시겠습니까?",
  priority: "high",
  tags: ["feedback", "review", "prd"]
})

// 6. 사용자 브리핑 제공
/*
"PRD를 기반으로 총 X개의 작업이 생성되었습니다.
복잡도 분석 결과를 포함해 전체 작업 계획을 브리핑드리겠습니다:

[고우선순위 작업들] (복잡도 8-10점)
- 작업 1: 제목 (복잡도: X/10)
- 작업 2: 제목 (복잡도: X/10)

[중간우선순위 작업들] (복잡도 5-7점)
- 작업 3: 제목 (복잡도: X/10)

[저우선순위 작업들] (복잡도 1-4점)
- 작업 4: 제목 (복잡도: X/10)

전체 프로젝트 복잡도: [평가]
예상 소요 시간: [추정]

이 계획에 대해 피드백을 주시면 필요한 조정을 하겠습니다."
*/

// 7. 피드백 반영
move_task    // 우선순위 변경
add_task     // 새 작업 추가
remove_task  // 불필요한 작업 제거
update_task  // 작업 내용 수정

// 8. 최종 승인 후 개발 시작
next_task

// ⚠️ 개발 시작 알림 (필수)
mcp_ntfy-me-mcp_ntfy_me({
  taskTitle: "Development Started",
  taskSummary: "모든 준비가 완료되었습니다. 첫 번째 작업을 시작하겠습니다.",
  priority: "default",
  tags: ["ready", "development"]
})
```

### 2. 일반적인 개발 사이클
```typescript
// 1. 다음 작업 확인
next_task

// 2. 작업 상세 분석 (복잡한 작업의 경우)
get_task --id=X
expand_task --id=X --force --research  // 하위 작업으로 분해

// 3. 작업 시작
set_task_status --id=X --status="in-progress"

// ⚠️ 복잡한 작업 시작 알림 (필요시)
mcp_ntfy-me-mcp_ntfy_me({
  taskTitle: "Complex Task Started",
  taskSummary: "복잡한 작업 '[작업명]'을 시작했습니다. 예상 완료 시간: X시간",
  priority: "default",
  tags: ["started", "complex"]
})

// 4. 구현 진행 (MCP 도구 활용)
// - sequentialthinking으로 복잡한 문제 분석
// - mcp_tavily-search로 최신 정보 조사
// - mcp_context7로 라이브러리 문서 참조
// - 코드 작성 (한국어 주석 필수)

// 5. 진행 상황 기록
update_subtask --id=X.Y --prompt="구체적인 진행 상황 (한국어)"

// 6. 작업 완료
set_task_status --id=X --status="done"

// ⚠️ 작업 완료 알림 (필수)
mcp_ntfy-me-mcp_ntfy_me({
  taskTitle: "Task Completed",
  taskSummary: "작업 '[작업명]'이 성공적으로 완료되었습니다. 다음 작업을 진행하시겠습니까?",
  priority: "default",
  tags: ["complete", "next-action"]
})
```

### 3. 하위 작업 확장 (expand_task) 상세 가이드

#### 🎯 하위 작업 확장 시기
- **복잡도 8-10점 작업**: 반드시 하위 작업으로 분해
- **복잡도 5-7점 작업**: 구현 전 분해 권장  
- **모호한 요구사항**: 명확한 단계별 작업으로 분해
- **새로운 기술/라이브러리 사용**: 학습 → 테스트 → 구현 단계로 분해

#### 📝 하위 작업 확장 패턴
```typescript
// 1. 기본 확장 패턴
expand_task --id=X                      // 기본 확장 (AI가 복잡도 기반 판단)
expand_task --id=X --num=5              // 구체적 개수 지정
expand_task --id=X --research           // 연구 기반 확장 (최신 정보 반영)
expand_task --id=X --force              // 기존 하위 작업이 있어도 재생성

// 2. 확장 후 검토 및 설명
get_task --id=X                         // 확장된 하위 작업 확인
/*
확장 결과 브리핑:
"작업 X가 Y개의 하위 작업으로 확장되었습니다:

X.1: [제목] - [설명] (우선순위: 높음)
X.2: [제목] - [설명] (우선순위: 중간)
X.3: [제목] - [설명] (우선순위: 낮음)

각 하위 작업의 구체적인 구현 방향:
- X.1: 구체적인 구현 계획과 고려사항
- X.2: 필요한 기술 스택과 예상 시간
- X.3: 테스트 방법과 검증 기준

이 분해가 적절한지 확인해주세요."
*/

// 3. 필요시 추가 조정
add_subtask --id=X --title="추가 하위작업" --description="설명"
remove_subtask --id=X.Y                 // 불필요한 하위 작업 제거
update_subtask --id=X.Y --prompt="상세 내용 추가"
```

#### 🔍 하위 작업 확장 체크리스트
- [ ] **완전성**: 모든 구현 단계가 포함되었는가?
- [ ] **순서**: 의존성에 따른 올바른 순서인가?
- [ ] **세분화**: 각 하위 작업이 1-2시간 내 완료 가능한가?
- [ ] **명확성**: 각 하위 작업의 목표와 완료 기준이 명확한가?
- [ ] **테스트**: 검증 및 테스트 단계가 포함되었는가?

### 4. 작업 수정 (update_task) 상세 가이드

#### 🔧 작업 수정 시나리오
- **요구사항 변경**: 기능 명세 변경 시
- **기술적 발견**: 구현 중 새로운 기술적 제약 발견
- **범위 조정**: 작업 범위 확대/축소 필요 시
- **우선순위 변경**: 비즈니스 우선순위 변경 시

#### 📝 작업 수정 패턴
```typescript
// 1. 기본 수정 패턴
update_task --id=X --prompt="변경사항 설명 (한국어)"
update_task --id=X --research --prompt="기술적 변경사항과 최신 동향 반영"
update_task --id=X --append --prompt="기존 내용에 추가 정보"

// 2. 수정 후 브리핑 제공
get_task --id=X                         // 수정된 작업 확인
/*
작업 수정 브리핑:
"작업 X가 다음과 같이 수정되었습니다:

변경 전: [이전 내용 요약]
변경 후: [수정된 내용 요약]

주요 변경사항:
1. [변경사항 1]: 구체적인 영향과 이유
2. [변경사항 2]: 관련 하위 작업에 미치는 영향
3. [변경사항 3]: 예상 소요 시간 변화

관련 하위 작업 영향도:
- X.1: [영향 없음/수정 필요/재생성 필요]
- X.2: [영향 분석]

이 수정사항이 전체 프로젝트 일정에 미치는 영향을 검토해주세요."
*/

// 3. 연쇄 수정 처리
get_task --id=X                         // 하위 작업 영향도 확인
expand_task --id=X --force              // 필요시 하위 작업 재생성
update --from=X --prompt="상위 작업 변경에 따른 후속 작업들 일괄 수정"
```

#### 🎯 작업 수정 후 체크리스트
- [ ] **일관성**: 수정된 내용이 프로젝트 전체 목표와 일치하는가?
- [ ] **의존성**: 다른 작업들과의 의존성이 올바르게 유지되는가?
- [ ] **하위 작업**: 기존 하위 작업들이 여전히 유효한가?
- [ ] **우선순위**: 수정으로 인한 우선순위 재조정이 필요한가?
- [ ] **일정**: 예상 소요 시간이 현실적으로 조정되었는가?

### 5. 하위 작업 진행 상황 관리

#### 📊 하위 작업 상태 추적 패턴
```typescript
// 1. 하위 작업 시작
set_task_status --id=X.Y --status="in-progress"

// 2. 진행 상황 기록 (타임스탬프 포함)
update_subtask --id=X.Y --prompt="구체적인 진행 상황:
- 완료된 부분: [상세 설명]
- 현재 작업 중: [진행 내용]
- 발견한 이슈: [문제점과 해결 방안]
- 예상 완료 시간: [시간 추정]"

// 3. 막힘 상황 처리
update_subtask --id=X.Y --prompt="막힌 상황:
- 문제: [구체적인 문제 설명]
- 시도한 해결책: [시도한 방법들]
- 필요한 도움: [어떤 도움이 필요한지]"
set_task_status --id=X.Y --status="blocked"

// 4. 완료 및 검증
update_subtask --id=X.Y --prompt="완료 보고:
- 구현된 기능: [완료된 기능 설명]
- 테스트 결과: [테스트 방법과 결과]
- 코드 위치: [관련 파일 경로]
- 다음 단계: [후속 작업 준비사항]"
set_task_status --id=X.Y --status="done"
```

#### 🔄 부모 작업 상태 동기화
```typescript
// 모든 하위 작업 완료 시
get_task --id=X                         // 하위 작업 완료 상태 확인
set_task_status --id=X --status="review" // 부모 작업을 리뷰 상태로 변경
update_task --id=X --append --prompt="모든 하위 작업 완료:
- 통합 테스트 결과: [결과]
- 전체 기능 검증: [검증 내용]
- 문서화 완료: [문서 링크]"
```

## 🛠️ 주요 MCP 도구 활용

### Sequential Thinking (복잡한 문제 해결)
```typescript
// 다음 상황에서 적극 활용:
// - 아키텍처 설계 결정
// - 복잡한 버그 분석
// - 기술 선택 및 비교
// - 리팩터링 계획 수립
// - 성능 최적화 전략

// 사용 후 결과를 반드시 Taskmaster에 기록:
update_subtask --id=X.Y --prompt="sequential thinking 결과: [분석 내용]"
```

### Tavily 검색 (최신 정보 수집)
```typescript
// 새로운 기술 도입 전 조사 워크플로우:
// 1. mcp_tavily-mcp_tavily-search로 최신 정보 검색
// 2. mcp_tavily-mcp_tavily-extract로 상세 문서 추출  
// 3. research 도구로 프로젝트 컨텍스트에 맞는 구체적 가이드 생성
// 4. add_task로 도입 작업 생성
```

### Context7 (라이브러리 문서)
```typescript
// 새 라이브러리 사용 전:
// 1. mcp_context7_resolve-library-id로 라이브러리 ID 확인
// 2. mcp_context7_get-library-docs로 최신 문서 획득
// 3. 문서 기반으로 구현 계획 수립
// 4. expand_task로 구현 단계 세분화
```

### GitHub MCP (협업 관리)
```typescript
// 완전한 GitHub 워크플로우:
// 1. mcp_github_create_issue로 이슈 생성
// 2. mcp_github_create_branch로 개발 브랜치 생성
// 3. 개발 진행 (update_subtask로 진행 상황 기록)
// 4. mcp_github_create_pull_request로 PR 생성
// 5. set_task_status로 작업 완료 표시
```

### Obsidian MCP (지식 관리)
```typescript
// 개발 과정에서 얻은 인사이트 문서화:
// 1. mcp_obsidian-mcp-_obsidian_update_file로 노트 생성
// 2. mcp_obsidian-mcp-_obsidian_manage_tags로 태그 관리
// 3. update_subtask로 Taskmaster에 문서 링크 추가
```

## 💻 코딩 가이드라인

### TypeScript/JavaScript 필수 규칙
```typescript
// ✅ 권장: 명확한 타입 정의와 한국어 주석
interface UserData {
  id: string;          // 사용자 고유 식별자
  email: string;       // 이메일 주소
  createdAt: Date;     // 생성 날짜
}

const fetchUserProfile = async (userId: string): Promise<UserData> => {
  try {
    const response = await fetch(`/api/users/${userId}`);
    if (!response.ok) {
      throw new Error(`사용자 조회 실패: ${response.status}`);
    }
    return await response.json();
  } catch (error) {
    console.error('사용자 프로필 조회 오류:', error);
    throw error;
  }
};

// ❌ 지양: 타입이 불명확하고 주석 없음
const fetchUser = async (id) => {
  const res = await fetch(`/api/users/${id}`);
  return res.json();
};
```

### 파일 헤더 및 주석 규칙
```typescript
/**
 * 사용자 인증 서비스
 * JWT 토큰 기반 인증 및 권한 관리를 담당
 * 
 * @author 개발자명
 * @since 2025-06-17
 */
```

### 오류 처리 패턴
```typescript
// 표준 오류 처리 패턴
class ServiceError extends Error {
  constructor(
    message: string,
    public code: string,
    public statusCode: number = 500
  ) {
    super(message);
    this.name = 'ServiceError';
  }
}

const handleApiError = (error: unknown): never => {
  if (error instanceof ServiceError) {
    console.error(`서비스 오류 [${error.code}]:`, error.message);
    throw error;
  }
  
  console.error('예상치 못한 오류:', error);
  throw new ServiceError(
    '내부 서비스 오류가 발생했습니다.',
    'INTERNAL_ERROR'
  );
};
```

## 🎯 중요 체크포인트

### PRD 후 브리핑 필수 확인사항
- [ ] 모든 핵심 기능이 작업으로 포함되었는가?
- [ ] 작업 간 의존성이 올바르게 설정되었는가?
- [ ] 우선순위가 비즈니스 요구사항과 일치하는가?
- [ ] 복잡도가 높은 작업들의 분해 계획이 있는가?
- [ ] 예상 일정이 현실적인가?

### 코드 구현 시 체크리스트
- [ ] TypeScript 타입 정의 완료
- [ ] 한국어 주석 및 문서화
- [ ] 오류 처리 로직 구현
- [ ] update_subtask로 진행 상황 기록
- [ ] 작업 완료 후 set_task_status 업데이트

### Taskmaster ID 처리 규칙
```typescript
// ✅ 올바른 사용
get_task --id=4        // 부모 작업 조회 (하위 작업 포함)
get_task --id=1,2,3    // 여러 작업 한 번에 조회
set_task_status --id=4.1 --status="done"  // 하위 작업 상태 변경
update_subtask --id=4.7 --prompt="진행 상황"

// ❌ 잘못된 사용
get_task --id=4.1      // 하위 작업 독립 조회 불가
```

## ⚠️ 주의사항

- **AI 도구 처리 시간**: parse_prd, analyze_project_complexity, research 등은 1분 정도 소요
- **하위 작업 조회**: 부모 작업을 통해서만 조회 가능 (독립 조회 불가)
- **의존성 관리**: 작업 순서를 올바르게 유지하여 체인이 작동하도록 관리
- **한국어 우선**: 모든 작업 제목, 설명, 주석은 반드시 한국어로 작성

## 🔧 환경 설정

### MCP 설정 파일 (`claude_desktop_config.json`)
필수 API 키들을 MCP 설정에 포함:
```json
{
  "mcpServers": {
    "taskmaster-ai": {
      "command": "npx",
      "args": [
        "-y",
        "--package=task-master-ai",
        "task-master-ai"
      ],
      "env": {
        "PERPLEXITY_API_KEY": "your-perplexity-key",
        "GOOGLE_API_KEY": "your-google-key",
        "MODEL": "gemini-2.5-flash-preview-04-17",
        "PERPLEXITY_MODEL": "sonar-pro",
        "MAX_TOKENS": "64000",
        "TEMPERATURE": "0.2",
        "DEFAULT_SUBTASKS": "5",
        "DEFAULT_PRIORITY": "medium"
      }
    }
  }
}
```

### Taskmaster 모델 설정

**⚠️ 중요**: `initialize_project` 후 반드시 모델을 Gemini로 변경해야 합니다!

#### 1. 프로젝트 초기화 후 모델 설정 확인 및 변경
```typescript
// 1. 프로젝트 초기화
initialize_project

// 2. 현재 모델 설정 확인
models

// 3. 메인 모델을 Gemini로 변경 (필수!)
models --setMain="gemini-2.5-flash-preview-04-17"

// 4. 설정 변경 확인
models
```

#### 2. 권장 모델 설정
- **메인 모델**: `gemini-2.5-flash-preview-04-17` (Google) - 빠르고 경제적
- **연구 모델**: `sonar-pro` (Perplexity) - 최신 정보 검색용
- **폴백 모델**: `claude-3-5-sonnet-20240620` (Anthropic) - 백업용

#### 3. 모델 변경이 필요한 이유
- **비용 효율성**: Gemini가 Claude보다 경제적
- **속도**: 더 빠른 응답 시간
- **품질**: 코드 생성 및 분석에서 우수한 성능
- **환경 변수 연동**: MCP 설정의 `MODEL` 환경변수와 일치

#### 4. 모델 설정 체크리스트
```typescript
// 프로젝트 시작 시 필수 확인사항
- [ ] initialize_project 실행
- [ ] models 명령어로 현재 설정 확인
- [ ] 메인 모델이 Claude인 경우 Gemini로 변경
- [ ] 변경 후 models 명령어로 설정 확인
- [ ] 모든 모델이 올바르게 설정되었는지 검증
```

### 모델별 API 키 요구사항
```json
{
  "env": {
    "GOOGLE_API_KEY": "your-google-key",        // Gemini 모델용 (필수)
    "PERPLEXITY_API_KEY": "your-perplexity-key", // 연구 기능용 (필수)
    "ANTHROPIC_API_KEY": "your-anthropic-key"    // 폴백용 (선택)
  }
}
```

---

이 통합 가이드를 통해 핵심 기능들을 효율적으로 활용하여 체계적인 개발 워크플로우를 구축하세요!
