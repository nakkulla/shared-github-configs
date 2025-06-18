# Git Submodule 사용법 가이드

## 개요
이 문서는 `shared-github-configs` 저장소를 Git submodule로 사용하는 방법을 설명합니다.

## 기본 Submodule 명령어

### 1. Submodule 추가
```bash
# 공유 설정 저장소를 submodule로 추가
git submodule add https://github.com/YOUR_USERNAME/shared-github-configs.git shared-configs

# 특정 브랜치 지정
git submodule add -b main https://github.com/YOUR_USERNAME/shared-github-configs.git shared-configs
```

### 2. Submodule 초기화 및 업데이트
```bash
# 기존 저장소를 클론한 후 submodule 초기화
git submodule init
git submodule update

# 또는 한 번에 실행
git submodule update --init --recursive

# 원격 저장소의 최신 변경사항으로 업데이트
git submodule update --remote
```

### 3. Submodule과 함께 저장소 클론
```bash
# 저장소와 모든 submodule을 함께 클론
git clone --recurse-submodules https://github.com/YOUR_USERNAME/your-project.git

# 기존 클론에서 submodule 추가
git submodule update --init --recursive
```

## 실제 사용 예제

### 새 프로젝트에 공유 설정 적용

1. **프로젝트 생성 및 submodule 추가**
```bash
mkdir my-new-project
cd my-new-project
git init

# 공유 설정 submodule 추가
git submodule add https://github.com/nakkulla/shared-github-configs.git shared-configs
```

2. **설정 파일 링크 생성**
```bash
# .github 폴더 링크
ln -sf shared-configs/github-templates .github

# .vscode 폴더 링크
ln -sf shared-configs/vscode-templates .vscode

# instruction 파일들 링크
mkdir -p .vscode
ln -sf ../shared-configs/instructions/* .vscode/
```

3. **자동화 스크립트 사용**
```bash
# 제공된 설정 스크립트 실행
bash shared-configs/scripts/setup-new-project.sh
```

### 기존 프로젝트에 적용

1. **submodule 추가**
```bash
git submodule add https://github.com/nakkulla/shared-github-configs.git shared-configs
git submodule update --init
```

2. **기존 설정 백업 및 링크 생성**
```bash
# 기존 설정 백업
mv .github .github.backup 2>/dev/null || true
mv .vscode .vscode.backup 2>/dev/null || true

# 새 설정 링크
ln -sf shared-configs/github-templates .github
ln -sf shared-configs/vscode-templates .vscode
```

## Submodule 업데이트 워크플로우

### 1. 공유 설정 업데이트 확인
```bash
# submodule 상태 확인
git submodule status

# 원격 변경사항 확인
cd shared-configs
git fetch
git log HEAD..origin/main --oneline
cd ..
```

### 2. 업데이트 적용
```bash
# 최신 변경사항으로 업데이트
git submodule update --remote shared-configs

# 변경사항 커밋
git add shared-configs
git commit -m "Update shared-configs submodule"
```

### 3. 자동 업데이트 (선택사항)
```bash
# 항상 최신 상태로 유지 (주의: 예상치 못한 변경 가능)
git config submodule.shared-configs.update rebase
git submodule update --remote --rebase
```

## 공유 설정 수정

### 1. Submodule 내에서 직접 수정
```bash
cd shared-configs
git checkout main
# 파일 수정
git add .
git commit -m "Update shared configurations"
git push origin main
cd ..

# 부모 프로젝트에서 submodule 포인터 업데이트
git add shared-configs
git commit -m "Update shared-configs submodule pointer"
```

### 2. 별도 저장소에서 수정 후 동기화
```bash
# 공유 설정 저장소를 별도로 클론하여 작업
git clone https://github.com/nakkulla/shared-github-configs.git temp-configs
cd temp-configs
# 수정 작업
git push origin main
cd ..
rm -rf temp-configs

# 프로젝트에서 업데이트
git submodule update --remote
git add shared-configs
git commit -m "Sync with updated shared-configs"
```

## 문제 해결

### 1. Submodule이 빈 폴더로 표시되는 경우
```bash
git submodule update --init --recursive
```

### 2. Submodule 변경사항이 감지되지 않는 경우
```bash
git config diff.submodule log
git config status.submodulesummary 1
```

### 3. Submodule 제거
```bash
# submodule 제거
git submodule deinit -f shared-configs
git rm shared-configs
rm -rf .git/modules/shared-configs
```

### 4. 충돌 해결
```bash
# submodule 충돌 시
git submodule update --init
git add shared-configs
git commit -m "Resolve submodule conflict"
```

## 모범 사례

1. **정기적인 업데이트**: 공유 설정의 변경사항을 정기적으로 확인하고 적용
2. **버전 고정**: 안정성이 중요한 프로젝트에서는 특정 태그/커밋 사용
3. **문서화**: 프로젝트별 커스터마이징 내용을 문서화
4. **테스트**: 설정 변경 후 빌드 및 배포 프로세스 테스트
5. **백업**: 기존 설정을 백업한 후 새 설정 적용

## 관련 파일
- `.gitmodules.template`: Git submodule 설정 템플릿
- `scripts/setup-new-project.sh`: 프로젝트 설정 자동화 스크립트
- `scripts/sync-configs.sh`: 설정 동기화 스크립트
- `README.md`: 전체 프로젝트 개요
