---
description: "코딩 가이드라인 및 개발 표준"
applyTo: "**/*.{ts,js,tsx,jsx,py,md}"
---

# 개발 가이드라인

## 🎯 핵심 원칙

- **한국어 주석 필수**: 모든 주석과 문서는 한국어로 작성
- **명확한 타입 정의**: TypeScript 타입을 명확히 정의
- **구조화된 오류 처리**: 일관된 오류 처리 패턴 적용
- **간결한 코드**: 복잡한 로직보다는 명확하고 읽기 쉬운 코드

## 💻 TypeScript/JavaScript 규칙

### 인터페이스 및 타입 정의
```typescript
// ✅ 권장: 명확한 타입 정의와 한국어 주석
interface UserData {
  id: string;          // 사용자 고유 식별자
  email: string;       // 이메일 주소
  name: string;        // 사용자 이름
  createdAt: Date;     // 계정 생성 날짜
  role: UserRole;      // 사용자 권한
}

type UserRole = 'admin' | 'user' | 'guest';  // 사용자 권한 타입

// ❌ 지양: 타입이 불명확하고 주석 없음
interface User {
  id: any;
  email: string;
  data: object;
}
```

### 함수 정의 패턴
```typescript
// ✅ 권장: 명확한 함수 시그니처와 오류 처리
const fetchUserProfile = async (userId: string): Promise<UserData> => {
  try {
    const response = await fetch(`/api/users/${userId}`);
    
    if (!response.ok) {
      throw new ServiceError(
        `사용자 조회 실패: ${response.status}`,
        'USER_FETCH_FAILED',
        response.status
      );
    }
    
    return await response.json();
  } catch (error) {
    console.error('사용자 프로필 조회 오류:', error);
    throw error;
  }
};

// ❌ 지양: 타입이 불명확하고 오류 처리 없음
const fetchUser = async (id) => {
  const res = await fetch(`/api/users/${id}`);
  return res.json();
};
```

### 컴포넌트 정의 (React)
```typescript
// ✅ 권장: 명확한 Props 타입과 한국어 주석
interface UserCardProps {
  user: UserData;           // 표시할 사용자 데이터
  onEdit?: () => void;      // 편집 버튼 클릭 핸들러
  compact?: boolean;        // 컴팩트 모드 여부
}

const UserCard: React.FC<UserCardProps> = ({ 
  user, 
  onEdit, 
  compact = false 
}) => {
  // 사용자 이름 표시 형식 결정
  const displayName = user.name || user.email.split('@')[0];
  
  return (
    <div className={`user-card ${compact ? 'compact' : ''}`}>
      <h3>{displayName}</h3>
      <p>{user.email}</p>
      {onEdit && (
        <button onClick={onEdit}>
          편집
        </button>
      )}
    </div>
  );
};

// ❌ 지양: Props 타입 없고 주석 없음
const UserCard = ({ user, onEdit }) => {
  return (
    <div>
      <h3>{user.name}</h3>
      <p>{user.email}</p>
    </div>
  );
};
```

## 🛠️ 오류 처리 패턴

### 표준 오류 클래스
```typescript
// 사용자 정의 오류 클래스
class ServiceError extends Error {
  constructor(
    message: string,
    public code: string,
    public statusCode: number = 500,
    public details?: Record<string, any>
  ) {
    super(message);
    this.name = 'ServiceError';
  }
}

// API 오류 처리 유틸리티
const handleApiError = (error: unknown): never => {
  if (error instanceof ServiceError) {
    console.error(`서비스 오류 [${error.code}]:`, error.message);
    throw error;
  }
  
  if (error instanceof Error) {
    console.error('알려진 오류:', error.message);
    throw new ServiceError(
      error.message,
      'KNOWN_ERROR'
    );
  }
  
  console.error('예상치 못한 오류:', error);
  throw new ServiceError(
    '내부 서비스 오류가 발생했습니다.',
    'INTERNAL_ERROR'
  );
};
```

### 비동기 함수 오류 처리
```typescript
// ✅ 권장: 포괄적인 오류 처리
const saveUserData = async (userData: UserData): Promise<void> => {
  try {
    // 데이터 유효성 검사
    if (!userData.email || !userData.name) {
      throw new ServiceError(
        '필수 필드가 누락되었습니다.',
        'VALIDATION_ERROR',
        400
      );
    }
    
    // API 호출
    const response = await fetch('/api/users', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(userData)
    });
    
    if (!response.ok) {
      throw new ServiceError(
        `사용자 저장 실패: ${response.statusText}`,
        'SAVE_FAILED',
        response.status
      );
    }
    
    console.log('사용자 데이터 저장 완료');
  } catch (error) {
    console.error('사용자 데이터 저장 중 오류:', error);
    throw handleApiError(error);
  }
};
```

## 📝 파일 및 주석 규칙

### 파일 헤더 템플릿
```typescript
/**
 * 사용자 인증 서비스
 * JWT 토큰 기반 인증 및 권한 관리를 담당합니다.
 * 
 * 주요 기능:
 * - 사용자 로그인/로그아웃
 * - JWT 토큰 생성 및 검증
 * - 권한 기반 접근 제어
 * 
 * @author 개발자명
 * @since 2025-06-18
 * @version 1.0.0
 */
```

### 함수 주석 규칙
```typescript
/**
 * 사용자 인증을 처리합니다.
 * 
 * @param credentials - 로그인 정보 (이메일, 비밀번호)
 * @returns JWT 토큰과 사용자 정보를 포함한 인증 결과
 * @throws {ServiceError} 인증 실패 시 AUTHENTICATION_FAILED 오류
 * 
 * @example
 * ```typescript
 * const result = await authenticateUser({
 *   email: 'user@example.com',
 *   password: 'password123'
 * });
 * console.log(result.token); // JWT 토큰
 * ```
 */
const authenticateUser = async (
  credentials: LoginCredentials
): Promise<AuthResult> => {
  // 구현...
};
```

### 인라인 주석 패턴
```typescript
const processUserData = (users: UserData[]): ProcessedUser[] => {
  return users
    .filter(user => user.isActive)           // 활성 사용자만 필터링
    .map(user => ({                          // 필요한 필드만 추출
      id: user.id,
      name: user.name,
      email: user.email,
      lastLogin: formatDate(user.lastLogin)  // 날짜 형식 변환
    }))
    .sort((a, b) => a.name.localeCompare(b.name)); // 이름순 정렬
};
```

## 🔧 코드 구조 및 조직

### 디렉토리 구조 (예시)
```
src/
├── components/          # 재사용 가능한 UI 컴포넌트
│   ├── common/         # 공통 컴포넌트
│   └── feature/        # 기능별 컴포넌트
├── services/           # API 호출 및 비즈니스 로직
├── utils/              # 유틸리티 함수
├── types/              # TypeScript 타입 정의
├── hooks/              # React 커스텀 훅
└── constants/          # 상수 정의
```

### 명명 규칙
```typescript
// ✅ 권장 명명 패턴
const getUserProfile = () => {};     // 함수: camelCase
const API_BASE_URL = '';            // 상수: SCREAMING_SNAKE_CASE
interface UserData {}               // 타입/인터페이스: PascalCase
const userService = {};             // 객체: camelCase

// 파일명 패턴
user-service.ts                     // 서비스: kebab-case
UserCard.tsx                       // 컴포넌트: PascalCase
api-client.util.ts                 // 유틸리티: kebab-case
```

## ✅ 코드 품질 체크리스트

### TypeScript 체크리스트
- [ ] 모든 함수에 명확한 타입 정의
- [ ] any 타입 사용 금지
- [ ] 인터페이스에 한국어 주석 포함
- [ ] 유니온 타입 적절히 활용

### 함수 작성 체크리스트
- [ ] 단일 책임 원칙 준수
- [ ] 입력 매개변수 검증
- [ ] 적절한 오류 처리
- [ ] 한국어 주석으로 설명

### 컴포넌트 체크리스트
- [ ] Props 타입 명확히 정의
- [ ] 기본값 적절히 설정
- [ ] 이벤트 핸들러 타입 정의
- [ ] 접근성(a11y) 고려

### 오류 처리 체크리스트
- [ ] 사용자 정의 오류 클래스 사용
- [ ] 의���있는 오류 메시지 (한국어)
- [ ] 적절한 로깅 레벨
- [ ] 오류 복구 전략 고려

## 🚀 성능 및 최적화

### React 최적화 패턴
```typescript
// 메모이제이션 활용
const ExpensiveComponent = React.memo(({ data }: { data: ComplexData }) => {
  // 복잡한 계산이 필요한 값들을 메모이제이션
  const processedData = useMemo(() => {
    return processComplexData(data);
  }, [data]);
  
  // 이벤트 핸들러 메모이제이션
  const handleClick = useCallback((id: string) => {
    console.log(`클릭된 항목: ${id}`);
  }, []);
  
  return (
    <div>
      {processedData.map(item => (
        <Item 
          key={item.id} 
          data={item} 
          onClick={handleClick}
        />
      ))}
    </div>
  );
});
```

### API 호출 최적화
```typescript
// 요청 중복 방지 및 캐싱
const apiCache = new Map<string, Promise<any>>();

const getCachedData = async <T>(url: string): Promise<T> => {
  if (apiCache.has(url)) {
    return apiCache.get(url);
  }
  
  const promise = fetch(url).then(res => res.json());
  apiCache.set(url, promise);
  
  // 5분 후 캐시 제거
  setTimeout(() => {
    apiCache.delete(url);
  }, 5 * 60 * 1000);
  
  return promise;
};
```

---

이 가이드를 통해 일관되고 고품질의 코드를 작성하여 유지보수하기 쉬운 프로젝트를 구축하세요! 💻