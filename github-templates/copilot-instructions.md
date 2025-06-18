# Taskmaster MCP 도구 사용 가이드

## 기본 원칙

- 한국어로 응답하고 설명합니다
- Taskmaster MCP 도구를 우선적으로 사용하여 작업을 관리합니다
- CLI 명령어보다 MCP 도구를 권장합니다
- 체계적인 작업 관리 및 개발 워크플로우를 사용합니다

## 프로젝트 초기화 및 설정

### 1. 프로젝트 초기화 (`initialize_project`)
새로운 Taskmaster 프로젝트를 설정할 때 사용합니다.
- 프로젝트 루트 디렉토리에 기본 파일 구조와 설정을 생성합니다
- PRD 파일을 파싱하기 전에 반드시 실행해야 합니다

### 2. PRD 파싱 (`parse_prd`)
Product Requirements Document를 분석하여 초기 작업 목록을 생성합니다.
- `.taskmaster/docs/prd.txt` 파일을 기반으로 작업을 자동 생성
- AI 처리가 필요하여 완료까지 1분 정도 소요됩니다

## 작업 관리

### 작업 조회
- `get_tasks`: 전체 작업 목록 조회
- `get_task`: 특정 작업의 상세 정보 조회 (여러 ID를 쉼표로 구분하여 한 번에 조회 가능)
- `next_task`: 다음에 수행할 작업 찾기

### 작업 생성 및 수정
- `add_task`: 새 작업 추가 (AI 기반)
- `add_subtask`: 하위 작업 추가
- `update_task`: 특정 작업 업데이트 (AI 기반)
- `update_subtask`: 하위 작업에 타임스탬프와 함께 정보 추가
- `set_task_status`: 작업 상태 변경 (pending, in-progress, done, review, cancelled 등)

### 작업 구조 관리
- `expand_task`: 복잡한 작업을 하위 작업으로 분해 (AI 기반)
- `expand_all`: 모든 적격 작업을 하위 작업으로 확장
- `move_task`: 작업 위치 이동
- `remove_task`: 작업 삭제

## 의존성 관리

- `add_dependency`: 작업 간 의존성 추가
- `remove_dependency`: 의존성 제거
- `validate_dependencies`: 의존성 문제 확인
- `fix_dependencies`: 의존성 문제 자동 수정

## 분석 및 리포팅

- `analyze_project_complexity`: 작업 복잡도 분석 (AI 기반)
- `complexity_report`: 복잡도 분석 결과 조회
- `research`: AI 기반 연구 수행 (최신 정보 수집)

## 태그 관리

여러 컨텍스트(브랜치, 기능 등)에서 작업을 분리하여 관리할 수 있습니다.

- `list_tags`: 사용 가능한 태그 목록 조회
- `add_tag`: 새 태그 생성
- `use_tag`: 활성 태그 변경
- `copy_tag`: 태그 복사
- `delete_tag`: 태그 삭제

## 파일 관리

- `generate`: tasks.json을 기반으로 개별 마크다운 파일 생성

## 모델 설정

- `models`: AI 모델 설정 조회 및 변경

## 사용 예시

### 새 프로젝트 시작
1. `initialize_project` - 프로젝트 초기화
2. PRD 파일 작성 (`.taskmaster/docs/prd.txt`)
3. `parse_prd` - PRD를 기반으로 작업 생성
4. `get_tasks` - 생성된 작업 확인

### 일반적인 개발 워크플로우
1. `next_task` - 다음 작업 확인
2. `set_task_status` - 작업을 'in-progress'로 변경
3. 코딩 작업 수행
4. `update_subtask` - 진행 상황 기록
5. `set_task_status` - 작업을 'done'으로 변경

### 복잡한 작업 처리
1. `expand_task` - 복잡한 작업을 하위 작업으로 분해
2. 각 하위 작업을 순차적으로 처리
3. `update_task` - 전체 작업 상태 업데이트

## 주의사항

- AI 기반 도구들(`parse_prd`, `add_task`, `update_task`, `expand_task`, `research` 등)은 처리 시간이 필요합니다
- 여러 작업 정보가 필요한 경우 `get_task`에서 쉼표로 구분된 ID를 사용하여 한 번에 조회하세요
- 작업 상태는 정확히 관리하여 의존성 체인이 올바르게 작동하도록 하세요
- 연구 도구(`research`)를 적극 활용하여 최신 정보를 바탕으로 작업하세요

## 환경 변수 설정

필요한 API 키들을 `.env` 파일에 설정하거나 MCP 설정에 포함해야 합니다:
- `ANTHROPIC_API_KEY`
- `PERPLEXITY_API_KEY` (연구 기능용)
- `OPENAI_API_KEY`
- 기타 사용하는 AI 모델의 API 키

이 가이드를 참고하여 Taskmaster MCP 도구를 효과적으로 활용하세요.
