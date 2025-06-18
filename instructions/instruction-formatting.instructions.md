---
description: "VS Code Copilot instruction 파일 작성 및 관리 규칙"
applyTo: "**/*.instructions.md"
---

# VS Code Copilot Instruction 파일 작성 가이드

## 필수 파일 구조

### 기본 형식
```markdown
---
description: "명확한 한 줄 설명"
applyTo: "파일경로패턴"
---

# 제목

## 주요 섹션
- **중요 포인트**
  - 세부 설명
  - 예제 및 설명
```

### 메타데이터 필드
- **description**: 규칙이 무엇을 하는지 명확히 설명
- **applyTo**: 적용될 파일 패턴 지정 (예: `"**/*.{js,ts}"`)

## 파일 참조 방법

### 프로젝트 내 파일 참조
```markdown
`package.json` 파일에서 설정을 확인하세요.
`src/components/UserCard.tsx` 컴포넌트를 참고하세요.
```

### 관련 instruction 파일 참조
```markdown
자세한 내용은 `taskmaster-basic.instructions.md`를 참고하세요.
워크플로우는 `development-workflow.instructions.md`에서 확인할 수 있습니다.
```

## 코드 예제 작성

### 좋은 예제와 나쁜 예제 구분
```typescript
// ✅ 권장: 명확한 타입 정의와 한국어 주석
interface UserData {
  id: string;          // 사용자 고유 식별자
  email: string;       // 이메일 주소
  createdAt: Date;     // 생성 날짜
}

// ❌ 지양: 타입이 불명확하고 주석 없음
const user = {
  id: '123',
  email: 'test@example.com'
};
```

### 실용적인 예제 제공
```typescript
// 실제 API 호출 예제
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
```

## 규칙 내용 작성 가이드라인

### 구조화된 접근
1. **개요**: 높은 수준의 개요부터 시작
2. **구체적 요구사항**: 실행 가능한 구체적 요구사항 포함
3. **올바른 구현 예제**: 정확한 구현 방법 제시
4. **기존 코드 참조**: 가능한 경우 기존 코드 참조
5. **DRY 원칙**: 다른 instruction 파일 참조하여 중복 방지

### 내용 작성 모범 사례
```markdown
## 기능 구현 시 체크리스트

### 필수 사항
- [ ] TypeScript 타입 정의 완료
- [ ] 한국어 주석 및 문서화
- [ ] 오류 처리 로직 구현
- [ ] 단위 테스트 작성

### 권장 사항
- [ ] 성능 최적화 고려
- [ ] 접근성 개선
- [ ] 보안 검증
```

## Instruction 파일 관리

### 파일 업데이트 시기
- 새로운 패턴이 코드베이스에 나타날 때
- 기존 규칙의 더 나은 예제가 발견될 때
- 관련 규칙들이 업데이트될 때
- 구현 세부사항이 변경될 때

### 유지보수 체크리스트
```markdown
- [ ] 예제가 최신 코드와 일치하는가?
- [ ] 외부 문서 참조가 유효한가?
- [ ] 관련 instruction 파일들과 일관성이 있는가?
- [ ] 중복된 내용이 없는가?
```

## 최적화 및 품질 관리

### 일관성 유지
- 모든 instruction 파일에서 동일한 형식 사용
- 용어 사용의 일관성 유지
- 예제 스타일의 통일성 보장

### 접근성 고려
- 명확하고 간결한 설명
- 단계별 가이드 제공
- 실용적인 예제 중심

### Taskmaster 연동
- instruction 파일 업데이트를 `add_task`로 관리
- 규칙 개선을 `expand_task`로 세분화
- 진행 상황을 `update_subtask`로 기록
- 완료된 업데이트를 `set_task_status`로 추적

이 가이드를 통해 일관되고 효과적인 VS Code Copilot instruction 파일을 작성하고 관리하세요.
