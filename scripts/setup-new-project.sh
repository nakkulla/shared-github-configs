#!/bin/bash

# 새 프로젝트에 Shared GitHub Configs 설정 스크립트
# Usage: ./setup-new-project.sh [PROJECT_PATH]

set -e  # 오류 발생 시 스크립트 종료

# 색상 설정
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 함수: 메시지 출력
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 함수: 도움말 출력
show_help() {
    echo "🔧 Shared GitHub Configs 설정 스크립트"
    echo ""
    echo "사용법: $0 [PROJECT_PATH]"
    echo ""
    echo "옵션:"
    echo "  PROJECT_PATH    설정할 프로젝트 경로 (기본값: 현재 디렉토리)"
    echo "  -h, --help      이 도움말 표시"
    echo ""
    echo "예시:"
    echo "  $0 /path/to/my-project"
    echo "  $0  # 현재 디렉토리에 설정"
}

# 함수: 필수 프로그램 확인
check_requirements() {
    print_status "필수 프로그램 확인 중..."
    
    if ! command -v git &> /dev/null; then
        print_error "Git이 설치되어 있지 않습니다."
        exit 1
    fi
    
    if ! command -v ln &> /dev/null; then
        print_error "ln 명령어를 사용할 수 없습니다."
        exit 1
    fi
    
    print_success "필수 프로그램 확인 완료"
}

# 함수: 프로젝트 경로 설정
setup_project_path() {
    if [ -z "$1" ]; then
        PROJECT_PATH=$(pwd)
        print_status "현재 디렉토리를 프로젝트 경로로 설정: $PROJECT_PATH"
    else
        PROJECT_PATH=$(realpath "$1")
        print_status "프로젝트 경로 설정: $PROJECT_PATH"
    fi
    
    if [ ! -d "$PROJECT_PATH" ]; then
        print_error "프로젝트 디렉토리가 존재하지 않습니다: $PROJECT_PATH"
        exit 1
    fi
    
    # Git 저장소인지 확인
    if [ ! -d "$PROJECT_PATH/.git" ]; then
        print_warning "Git 저장소가 아닙니다. Git 저장소를 초기화하시겠습니까? (y/N)"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            cd "$PROJECT_PATH"
            git init
            print_success "Git 저장소 초기화 완료"
        else
            print_error "Git 저장소가 필요합니다."
            exit 1
        fi
    fi
}

# 함수: Submodule 추가
add_submodule() {
    print_status "Shared GitHub Configs submodule 추가 중..."
    
    cd "$PROJECT_PATH"
    
    # 기존 submodule 확인
    if [ -d ".shared-configs" ]; then
        print_warning ".shared-configs 디렉토리가 이미 존재합니다."
        print_warning "기존 설정을 제거하고 다시 설정하시겠습니까? (y/N)"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            rm -rf .shared-configs
            git submodule deinit -f .shared-configs 2>/dev/null || true
            git rm -f .shared-configs 2>/dev/null || true
        else
            print_status "기존 설정을 사용합니다."
            return 0
        fi
    fi
    
    # Submodule 추가
    git submodule add https://github.com/nakkulla/shared-github-configs.git .shared-configs
    git submodule update --init --recursive
    
    print_success "Submodule 추가 완료"
}

# 함수: 심볼릭 링크 생성
create_symlinks() {
    print_status "심볼릭 링크 생성 중..."
    
    cd "$PROJECT_PATH"
    
    # 기존 디렉토리 백업
    if [ -d ".github" ] && [ ! -L ".github" ]; then
        print_warning ".github 디렉토리가 이미 존재합니다. .github.backup으로 백업합니다."
        mv .github .github.backup
    fi
    
    if [ -d ".vscode" ] && [ ! -L ".vscode" ]; then
        print_warning ".vscode 디렉토리가 이미 존재합니다. .vscode.backup으로 백업합니다."
        mv .vscode .vscode.backup
    fi
    
    # 기존 심볼릭 링크 제거
    [ -L ".github" ] && rm .github
    [ -L ".vscode" ] && rm .vscode
    [ -L ".github/instructions" ] && rm .github/instructions
    
    # 새 심볼릭 링크 생성
    ln -sf .shared-configs/github-templates .github
    ln -sf .shared-configs/vscode-templates .vscode
    
    # .github/instructions 링크 생성 (GitHub 디렉토리 내부)
    mkdir -p .github
    ln -sf ../.shared-configs/instructions .github/instructions
    
    print_success "심볼릭 링크 생성 완료"
    print_status "생성된 링크:"
    print_status "  .github -> .shared-configs/github-templates"
    print_status "  .vscode -> .shared-configs/vscode-templates"
    print_status "  .github/instructions -> .shared-configs/instructions"
}

# 함수: Git hooks 설치
install_git_hooks() {
    print_status "Git hooks 설치 중..."
    
    cd "$PROJECT_PATH"
    
    # hooks 디렉토리가 없으면 생성
    mkdir -p .git/hooks
    
    # Post-commit hook 생성
    cat > .git/hooks/post-commit << 'EOF'
#!/bin/bash
# 공유 설정 자동 동기화 hook

# .shared-configs 디렉토리에 변경사항이 있는지 확인
if [ -d ".shared-configs" ]; then
    cd .shared-configs
    if [ -n "$(git status --porcelain)" ]; then
        echo "🔄 공유 설정 변경사항 감지, 자동 동기화 중..."
        git add .
        git commit -m "Auto-sync shared configs from $(basename $(dirname $PWD))"
        git push origin main
        echo "✅ 공유 설정 동기화 완료"
        
        # 부모 프로젝트에서 submodule 업데이트
        cd ..
        git add .shared-configs
        git commit -m "Update shared configs submodule"
        echo "✅ Submodule 참조 업데이트 완료"
    fi
fi
EOF
    
    # 실행 권한 부여
    chmod +x .git/hooks/post-commit
    
    print_success "Git hooks 설치 완료"
}

# 함수: 설정 확인
verify_setup() {
    print_status "설정 확인 중..."
    
    cd "$PROJECT_PATH"
    
    # Submodule 확인
    if [ ! -d ".shared-configs" ]; then
        print_error "Submodule이 올바르게 설치되지 않았습니다."
        return 1
    fi
    
    # 심볼릭 링크 확인
    if [ ! -L ".github" ] || [ ! -L ".vscode" ]; then
        print_error "심볼릭 링크가 올바르게 생성되지 않았습니다."
        return 1
    fi
    
    # 파일 존재 확인
    if [ ! -f ".shared-configs/README.md" ]; then
        print_error "공유 설정 파일들이 올바르게 로드되지 않았습니다."
        return 1
    fi
    
    print_success "설정 확인 완료"
    return 0
}

# 함수: 사용법 안내
show_usage_info() {
    print_success "🎉 Shared GitHub Configs 설정이 완료되었습니다!"
    echo ""
    echo "📋 사용법:"
    echo "1. 공유 설정 수정:"
    echo "   cd .shared-configs"
    echo "   # 파일 수정 후"
    echo "   git add . && git commit -m 'Update configs' && git push"
    echo ""
    echo "2. 최신 설정 가져오기:"
    echo "   git submodule update --remote --rebase"
    echo ""
    echo "3. 로컬 커스터마이징:"
    echo "   # 프로젝트별 설정은 별도 파일로 관리"
    echo "   # 예: .github/local-workflows/, .vscode/local-settings.json"
    echo ""
    echo "4. Taskmaster 사용:"
    echo "   # VSCode에서 Ctrl+Shift+P -> 'Tasks: Run Task'"
    echo "   # 또는 터미널에서: npx task-master-ai"
    echo ""
    print_status "자세한 내용은 .shared-configs/README.md를 참조하세요."
}

# 메인 함수
main() {
    echo "🔧 Shared GitHub Configs 설정 스크립트"
    echo "============================================"
    echo ""
    
    # 도움말 확인
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_help
        exit 0
    fi
    
    # 설정 시작
    check_requirements
    setup_project_path "$1"
    add_submodule
    create_symlinks
    install_git_hooks
    
    if verify_setup; then
        show_usage_info
    else
        print_error "설정 중 오류가 발생했습니다."
        exit 1
    fi
}

# 스크립트 실행
main "$@"
