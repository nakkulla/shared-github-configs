# 🔧 Shared GitHub Configs

여러 프로젝트 간 .github 및 .vscode 설정을 공유하는 Git Submodule 저장소입니다.

## 📋 개요

이 저장소는 다음과 같은 공통 설정들을 중앙화하여 관리합니다:

- **GitHub 워크플로우**: CI/CD 파이프라인, 자동화 스크립트
- **이슈 & PR 템플릿**: 일관된 이슈 리포팅 및 코드 리뷰 프로세스
- **VSCode 설정**: 개발 환경 표준화 (설정, 확장, 스니펫)
- **개발 가이드**: Taskmaster MCP 워크플로우, 코딩 스타일 가이드
- **자동화 스크립트**: 설정 동기화, 설치 스크립트

## 🚀 빠른 시작

### 1. 기존 프로젝트에 서브모듈 추가

```bash
# 프로젝트 루트 디렉토리에서 실행
git submodule add https://github.com/nakkulla/shared-github-configs.git .shared-configs

# 심볼릭 링크 생성
ln -s .shared-configs/github-templates .github
ln -s .shared-configs/vscode-templates .vscode
```

### 2. 새 프로젝트 설정

```bash
# 자동화 스크립트 사용
./scripts/setup-new-project.sh /path/to/your/project

# 또는 현재 디렉토리에 설정
./scripts/setup-new-project.sh
```

## 📁 저장소 구조

```
shared-github-configs/
├── github-templates/           # GitHub 관련 설정
│   ├── workflows/             # GitHub Actions 워크플로우
│   ├── ISSUE_TEMPLATE/        # 이슈 템플릿
│   ├── PULL_REQUEST_TEMPLATE/ # PR 템플릿
│   └── CODEOWNERS            # 코드 소유자 설정
├── vscode-templates/          # VSCode 관련 설정 (표준화됨)
│   ├── settings.json         # 핵심 설정만 포함 (25개 설정)
│   ├── extensions.json       # 필수 확장 프로그램 (11개 선별)
│   ├── tasks.json           # 기본 npm 스크립트 작업 (6개)
│   ├── launch.json          # 단순화된 디버그 설정 (4개)
│   └── snippets/            # 공통 코드 스니펫
├── instructions/             # VSCode Copilot 및 개발 가이드
│   ├── taskmaster.instructions.md      # Taskmaster MCP 통합 가이드
│   ├── github-taskmaster.instructions.md # GitHub + Taskmaster 워크플로우
│   ├── ntfy-notification.instructions.md # 알림 설정 가이드
│   └── instruction-formatting.instructions.md # 문서화 규칙
├── scripts/                 # 자동화 및 관리 스크립트
│   ├── setup-new-project.sh # 새 프로젝트 자동 설정
│   ├── sync-configs.sh      # 설정 동기화
│   ├── submodule-manager.sh # Git submodule 관리 도구
│   ├── validate-structure.sh     # 전체 구조 검증
│   ├── validate-github-templates.sh  # GitHub 템플릿 검증
│   └── validate-vscode-templates.sh  # VSCode 템플릿 검증 (신규)
├── docs/                    # 상세 문서
│   ├── git-submodule-guide.md   # Git Submodule 사용 가이드
│   ├── installation.md      # 설치 가이드 (예정)
│   ├── customization.md     # 커스터마이징 방법 (예정)
│   └── troubleshooting.md   # 문제 해결 가이드 (예정)
├── README.md               # 이 파일
├── .gitignore              # Git 제외 파일
└── LICENSE                 # 라이센스
```

## 🔄 Git Submodule 관리

### 자동화 도구 사용
```bash
# 모든 submodule 상태 확인
./scripts/submodule-manager.sh status

# 모든 submodule 업데이트
./scripts/submodule-manager.sh update

# 설정 검증
./scripts/submodule-manager.sh check

# 등록된 submodule 목록 확인
./scripts/submodule-manager.sh list

# 도움말 보기
./scripts/submodule-manager.sh --help
```

### 수동 관리
```bash
# 최신 변경사항 가져오기
git submodule update --remote --rebase

# 변경사항 푸시 (서브모듈 내에서)
cd .shared-configs
git add .
git commit -m "Update shared configs"
git push origin main
```

## 🛠️ 사용법

### VSCode 설정 표준화
이 저장소의 VSCode 설정은 실용적이고 단순한 개발 환경을 제공합니다:

**표준화된 설정 (settings.json)**
- 핵심 편집기 설정만 포함 (포맷팅, 탭 크기, 인코딩 등)
- GitHub Copilot 통합 및 한국어 지원
- Git 자동화 설정
- 프로젝트 타입별 기본 파일 연결

**선별된 확장 프로그램 (extensions.json)**
- 언어 지원: JSON, YAML, TypeScript
- 코드 품질: ESLint, Prettier
- GitHub 통합: Copilot, GitLens
- 필수 유틸리티: Markdown, 아이콘, 자동완성

**단순화된 작업 (tasks.json)**
- 의존성 설치, 빌드, 테스트, 린트, 개발 서버 실행
- 모든 작업은 npm 스크립트 기반
- 프로젝트 타입에 관계없이 일관된 인터페이스

**기본 디버그 설정 (launch.json)**
- Chrome 브라우저 디버깅
- Node.js 애플리케이션 디버깅
- Jest 테스트 디버깅
- TypeScript 컴파일 후 디버깅

### 설정 수정
1. `.shared-configs` 디렉토리에서 필요한 파일 수정
2. 변경사항 커밋 및 푸시
3. 다른 프로젝트에서 `git submodule update --remote` 실행

### 프로젝트별 커스터마이징
- 로컬 설정 파일로 공통 설정 오버라이드 가능
- 프로젝트 특화 설정은 별도 디렉토리에 보관

## 📚 관련 문서

- [Git Submodule 사용 가이드](docs/git-submodule-guide.md)
- [설치 가이드](docs/installation.md) (예정)
- [커스터마이징 방법](docs/customization.md) (예정)
- [문제 해결](docs/troubleshooting.md) (예정)
- [기여 가이드](CONTRIBUTING.md) (예정)

## 📄 라이센스

MIT License - 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## 🤝 기여하기

이 프로젝트에 기여하고 싶으시다면:

1. 이 저장소를 포크하세요
2. 새 브랜치를 생성하세요 (`git checkout -b feature/새기능`)
3. 변경사항을 커밋하세요 (`git commit -am '새 기능 추가'`)
4. 브랜치에 푸시하세요 (`git push origin feature/새기능`)
5. Pull Request를 생성하세요

## 📞 지원

문제가 발생하거나 질문이 있으시면:
- [Issues](https://github.com/nakkulla/shared-github-configs/issues) 탭에서 새 이슈 생성
- [Discussions](https://github.com/nakkulla/shared-github-configs/discussions)에서 질문

---

💡 **팁**: 이 저장소는 [Taskmaster MCP](https://github.com/taskmaster-ai/taskmaster) 워크플로우와 완벽하게 통합되어 체계적인 개발 환경을 제공합니다.
