---
description: "MCP 기반 개발 워크플로우 메인 가이드"
applyTo: "**"
---

# MCP 개발 워크플로우 가이드

## 🎯 핵심 원칙

- **한국어 우선**: 모든 작업, 주석, 문서는 한국어로 작성
- **MCP 도구 우선**: CLI보다 MCP 도구를 먼저 활용  
- **큰 작업 단위**: 메인 작업 하나씩 순차적으로 완료
- **완료 시 브리핑**: 작업 완료 후 상세 브리핑 + 다음 진행 확인
- **Shell Integration 제약**: 터미널 명령어 간결화 필수

## 📋 세부 가이드 참조

이 메인 가이드는 개요를 제공하며, 구체적인 내용은 각 세부 가이드를 참조하세요:

### 1. [Taskmaster 핵심 워크플로우](instructions/taskmaster-core.instructions.md)
- 프로젝트 초기화 및 PRD 파싱
- 큰 작업 단위 진행 전략
- 하위 작업 관리 및 복잡도 분석
- **필수**: 모든 프로젝트는 여기서 시작

### 2. [GitHub 연동 & Shell Integration](instructions/github-integration.instructions.md)
- GitHub 워크플로우 (브랜치, 이슈, PR)
- **Shell Integration 제약사항** (터미널 명령어 간결화)
- Git 커밋 메시지 규칙
- **중요**: 명령어 파싱 한계 준수 필수

### 3. [ntfy 알림 시스템](instructions/ntfy-notifications.instructions.md)
- 필수 알림 시점 (완료, 피드백 요청, 오류)
- 알림 작성 규칙 (영어 헤더, 한국어 내용)
- 우선순위 관리
- **필수**: 모든 큰 작업 완료 시 알림

### 4. [개발 가이드라인](instructions/development-guidelines.instructions.md)
- TypeScript/JavaScript 코딩 규칙
- 오류 처리 패턴
- 한국어 주석 및 문서화
- 코드 품질 관리

## 🚀 빠른 시작 체크리스트

### 프로젝트 시작
- [ ] `initialize_project` 실행
- [ ] Gemini 모델로 변경: `models --setMain="gemini-2.5-flash-preview-04-17"`
- [ ] PRD 작성 (핵심 기능만)
- [ ] `parse_prd` + `analyze_project_complexity --research`
- [ ] **브리핑 후 사용자 승인 받기** (바로 개발 시작 금지)

### 작업 진행
- [ ] 한 번에 하나의 큰 작업만 진행
- [ ] 복잡도 6점 이상 → `expand_task --research`
- [ ] 하위 작업 5개 초과 → 배치로 나누어 진행
- [ ] Shell 명령어 간결하게 (git commit 메시지 한 줄)
- [ ] 완료 시 브리핑 + ntfy 알림

## ⚠️ 중요 제약사항

### Shell Integration 제약 (필수 준수)
- **Git 커밋 메시지**: 50자 이내, 한 줄로
- **터미널 명령어**: 복잡한 파이프라인 금지
- **여러줄 명령**: 단일 명령어로 실행

### 작업 진행 제약
- **병렬 진행 금지**: 여러 큰 작업 동시 진행 불가
- **브리핑 필수**: PRD 분석 후, 큰 작업 완료 후
- **알림 필수**: 완료, 피드백 요청, 오류 시

## 🔗 워크플로우 흐름

```
1. 프로젝트 초기화 → 
2. PRD 작성 → 
3. 작업 생성 및 분석 → 
4. 브리핑 및 승인 → 
5. 큰 작업 선택 → 
6. 하위 작업 분해 (필요시) → 
7. 순차적 구현 → 
8. 완료 브리핑 + 알림 → 
9. 다음 작업 진행 확인
```

## 📞 지원 및 트러블슈팅

각 기능별 상세 가이드에서 트러블슈팅 섹션을 참조하세요:
- Taskmaster 문제: `taskmaster-core.instructions.md` 참조
- GitHub/Shell 문제: `github-integration.instructions.md` 참조  
- 알림 문제: `ntfy-notifications.instructions.md` 참조
- 코딩 문제: `development-guidelines.instructions.md` 참조

---

**시작하기**: 새 프로젝트라면 [Taskmaster 핵심 워크플로우](instructions/taskmaster-core.instructions.md)부터 시작하세요! 🚀