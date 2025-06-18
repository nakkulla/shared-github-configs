# GitHub Actions 워크플로우 예제
# 이 폴더에는 다양한 CI/CD 워크플로우 템플릿들이 포함됩니다.

## 포함된 워크플로우:

### 1. ci-basic.yml
- 기본적인 CI 파이프라인
- 코드 체크아웃, 의존성 설치, 테스트, 빌드

### 2. node-ci.yml (예정)
- Node.js 프로젝트용 CI
- 여러 Node.js 버전 매트릭스 테스트

### 3. python-ci.yml (예정)
- Python 프로젝트용 CI
- 여러 Python 버전 매트릭스 테스트

### 4. release.yml (예정)
- 자동 릴리즈 워크플로우
- 버전 태깅, 릴리즈 노트 생성

### 5. dependabot.yml (예정)
- 의존성 자동 업데이트 설정

## 사용법:
프로젝트의 `.github/workflows/` 폴더에 필요한 워크플로우 파일을 복사하여 사용하세요.
