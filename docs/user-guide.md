# Shared GitHub Configs 사용자 가이드

## 🚀 빠른 시작

### 1. 새 프로젝트에 공유 설정 적용

```bash
# 1. 기존 프로젝트에 submodule 추가
git submodule add https://github.com/your-org/shared-github-configs.git .shared-configs

# 2. 설정 동기화 실행
cd .shared-configs
./scripts/sync-configs-improved.sh pull

# 3. GitHub 설정 적용
./scripts/sync-configs-improved.sh push --type github

# 4. VSCode 설정 적용  
./scripts/sync-configs-improved.sh push --type vscode
```

### 2. Submodule 관리

```bash
# 상태 확인
./scripts/submodule-manager.sh status

# 전체 업데이트
./scripts/submodule-manager.sh update

# 백업 생성
./scripts/submodule-manager.sh backup

# 분석 실행
./scripts/submodule-manager.sh analyze
```

## 📋 주요 스크립트

### sync-configs-improved.sh
**용도**: 공유 설정 파일 동기화

**주요 명령어**:
- `status` - 동기화 상태 확인
- `pull` - 원격에서 최신 설정 가져오기
- `push` - 로컬 변경사항 원격에 적용
- `backup` - 현재 설정 백업
- `validate` - 설정 파일 유효성 검사

**옵션**:
- `--dry-run` - 실제 변경 없이 미리보기
- `--verbose` - 상세 출력
- `--type [github|vscode|all]` - 특정 설정만 동기화
- `--log FILE` - 로그 파일 지정

### submodule-manager.sh  
**용도**: Git submodule 고급 관리

**주요 명령어**:
- `status` - 전체 submodule 상태 확인
- `update` - 모든 submodule 업데이트
- `backup` - 현재 상태 백업
- `restore` - 백업에서 복원
- `analyze` - 고급 분석 (순환참조, 중복 등)
- `repair` - 손상된 submodule 자동 복구

## 🔧 일반적인 사용 시나리오

### 시나리오 1: 새 프로젝트 설정
```bash
# 1. 프로젝트 초기화
git init my-project && cd my-project

# 2. 공유 설정 추가
git submodule add https://github.com/your-org/shared-github-configs.git .shared-configs

# 3. 모든 설정 적용
cd .shared-configs
./scripts/sync-configs-improved.sh pull
./scripts/sync-configs-improved.sh push
```

### 시나리오 2: 설정 업데이트
```bash
# 1. 최신 공유 설정 확인
./scripts/sync-configs-improved.sh status

# 2. 안전한 업데이트 (백업 포함)
./scripts/sync-configs-improved.sh backup
./scripts/sync-configs-improved.sh pull --verbose

# 3. 변경사항 적용
./scripts/sync-configs-improved.sh push --dry-run  # 미리보기
./scripts/sync-configs-improved.sh push            # 실제 적용
```

### 시나리오 3: 문제 해결
```bash
# 1. 문제 진단
./scripts/submodule-manager.sh analyze

# 2. 자동 복구 시도
./scripts/submodule-manager.sh repair

# 3. 수동 복구
./scripts/submodule-manager.sh backup
git submodule update --init --recursive
./scripts/submodule-manager.sh restore [백업ID]
```

## 🧪 테스트 시나리오

### 기본 기능 테스트
```bash
# 1. 도움말 확인
./scripts/sync-configs-improved.sh --help
./scripts/submodule-manager.sh --help

# 2. 상태 확인
./scripts/sync-configs-improved.sh status
./scripts/submodule-manager.sh status

# 3. 유효성 검사
./scripts/sync-configs-improved.sh validate
```

### Dry-run 테스트
```bash
# 안전한 미리보기 테스트
./scripts/sync-configs-improved.sh pull --dry-run --verbose
./scripts/sync-configs-improved.sh push --dry-run --type github
```

### 백업/복원 테스트
```bash
# 1. 백업 생성
./scripts/sync-configs-improved.sh backup
./scripts/submodule-manager.sh backup

# 2. 의도적 변경
echo "test" > .github/workflows/test.yml

# 3. 복원 테스트
./scripts/sync-configs-improved.sh restore [백업ID]
```

## ⚠️ 문제 해결

### 일반적인 오류

**"command not found" 오류**
```bash
# 실행 권한 확인
chmod +x scripts/*.sh

# 의존성 설치
brew install rsync jq  # macOS
```

**"Git submodule 오류"**
```bash
# submodule 초기화
git submodule update --init --recursive

# 손상된 submodule 복구
./scripts/submodule-manager.sh repair
```

**"동기화 실패"**
```bash
# 상세 로그 확인
./scripts/sync-configs-improved.sh status --verbose --log sync.log

# 수동 백업 후 재시도
./scripts/sync-configs-improved.sh backup
./scripts/sync-configs-improved.sh pull --force
```

### 로그 확인
모든 스크립트는 자동으로 로그를 생성합니다:
- `sync-configs-improved.sh`: `.shared-configs/logs/sync-YYYYMMDD.log`  
- `submodule-manager.sh`: `submodule-manager-YYYYMMDD.log`

## 📚 추가 자료

- [Git Submodule 가이드](git-submodule-guide.md)
- [GitHub 워크플로우 템플릿](../github-templates/)
- [VSCode 설정 템플릿](../vscode-templates/)

## 🔗 관련 명령어

### Git 관련
```bash
# Submodule 상태 확인
git submodule status

# Submodule 업데이트
git submodule update --remote --merge

# Submodule URL 변경
git submodule set-url .shared-configs NEW_URL
```

### 검증 명령어
```bash
# JSON 파일 검증
jq . .vscode/settings.json

# YAML 파일 검증 (yq 설치된 경우)
yq eval . .github/workflows/ci.yml
```

---

**💡 팁**: `--dry-run` 옵션을 사용하여 실제 변경 전에 항상 미리보기를 확인하세요!
