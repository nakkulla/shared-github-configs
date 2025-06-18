#!/bin/bash

# Shared GitHub Configs 설정 스크립트
# GitHub 및 VSCode 공유 설정을 새 프로젝트에 간단하게 설치합니다.
#
# 주요 기능:
# - Git submodule로 공유 설정 저장소 추가
# - .github, .vscode 디렉토리에 심볼릭 링크 생성
# - 기본 Git hooks 설치 (변경사항 알림)
# 
# 사용법: ./setup-new-project.sh [PROJECT_PATH]
#
# 버전: 2.0 (단순화됨)
# 최종 수정: 2025-06-18

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
    echo "🔧 Shared GitHub Configs 설정 스크립트 v2.0"
    echo ""
    echo "📝 설명:"
    echo "   GitHub과 VSCode 공유 설정을 새 프로젝트에 간단하게 설치합니다."
    echo "   Git submodule과 심볼릭 링크를 사용하여 설정을 동기화합니다."
    echo ""
    echo "🚀 사용법:"
    echo "   $0 [PROJECT_PATH]"
    echo ""
    echo "📋 옵션:"
    echo "   PROJECT_PATH    설정할 프로젝트 경로 (기본값: 현재 디렉토리)"
    echo "   -h, --help      이 도움말 표시"
    echo ""
    echo "💡 예시:"
    echo "   $0 /path/to/my-project    # 지정된 경로에 설정"
    echo "   $0                        # 현재 디렉토리에 설정"
    echo ""
    echo "📦 설치되는 항목:"
    echo "   - .shared-configs/        (Git submodule)"
    echo "   - .github/                (심볼릭 링크)"
    echo "   - .vscode/                (심볼릭 링크)"
    echo "   - .git/hooks/post-commit  (변경사항 알림)"
}

# 함수: 필수 프로그램 확인 (단순화됨)
check_requirements() {
    print_status "필수 프로그램 확인 중..."
    
    local missing_tools=()
    
    if ! command -v git &> /dev/null; then
        missing_tools+=("git")
    fi
    
    if ! command -v ln &> /dev/null; then
        missing_tools+=("ln")
    fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_error "다음 프로그램들이 필요합니다: ${missing_tools[*]}"
        print_error "설치 후 다시 실행해주세요."
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

# 함수: Submodule 추가 (개선됨)
add_submodule() {
    print_status "Shared GitHub Configs submodule 추가 중..."
    
    cd "$PROJECT_PATH"
    
    # 기존 submodule 확인
    if [ -d ".shared-configs" ]; then
        if [ -d ".shared-configs/.git" ]; then
            print_success ".shared-configs submodule이 이미 존재합니다."
            return 0
        else
            print_warning ".shared-configs 디렉토리가 존재하지만 Git submodule이 아닙니다."
            print_warning "제거하고 다시 설정하시겠습니까? (y/N)"
            read -r response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                rm -rf .shared-configs
            else
                print_error "기존 .shared-configs 디렉토리를 제거하거나 이름을 변경해주세요."
                exit 1
            fi
        fi
    fi
    
    # Submodule 추가
    if ! git submodule add https://github.com/nakkulla/shared-github-configs.git .shared-configs; then
        print_error "Submodule 추가에 실패했습니다. 인터넷 연결을 확인해주세요."
        exit 1
    fi
    
    if ! git submodule update --init --recursive; then
        print_error "Submodule 초기화에 실패했습니다."
        exit 1
    fi
    
    print_success "Submodule 추가 완료"
}

# 함수: 심볼릭 링크 생성 (개선됨)
create_symlinks() {
    print_status "심볼릭 링크 생성 중..."
    
    cd "$PROJECT_PATH"
    
    # 안전한 백업 및 링크 생성
    local backup_created=false
    
    # .github 처리
    if [ -e ".github" ]; then
        if [ ! -L ".github" ]; then
            print_warning ".github 디렉토리를 .github.backup으로 백업합니다."
            mv .github .github.backup
            backup_created=true
        else
            rm .github
        fi
    fi
    
    # .vscode 처리
    if [ -e ".vscode" ]; then
        if [ ! -L ".vscode" ]; then
            print_warning ".vscode 디렉토리를 .vscode.backup으로 백업합니다."
            mv .vscode .vscode.backup
            backup_created=true
        else
            rm .vscode
        fi
    fi
    
    # 새 심볼릭 링크 생성
    if ! ln -sf .shared-configs/github-templates .github; then
        print_error ".github 심볼릭 링크 생성 실패"
        exit 1
    fi
    
    if ! ln -sf .shared-configs/vscode-templates .vscode; then
        print_error ".vscode 심볼릭 링크 생성 실패"
        exit 1
    fi
    
    # .github/instructions 링크 생성
    if ! mkdir -p .github || ! ln -sf ../.shared-configs/instructions .github/instructions; then
        print_error ".github/instructions 심볼릭 링크 생성 실패"
        exit 1
    fi
    
    print_success "심볼릭 링크 생성 완료"
    if [ "$backup_created" = true ]; then
        print_status "백업된 설정: .github.backup, .vscode.backup"
    fi
    print_status "생성된 링크:"
    print_status "  .github → .shared-configs/github-templates"
    print_status "  .vscode → .shared-configs/vscode-templates"
    print_status "  .github/instructions → .shared-configs/instructions"
}

# 함수: 기본 Git hooks 설치 (단순화됨)
install_git_hooks() {
    print_status "기본 Git hooks 설치 중..."
    
    cd "$PROJECT_PATH"
    
    # hooks 디렉토리가 없으면 생성
    mkdir -p .git/hooks
    
    # 단순한 Post-commit hook 생성 (알림만)
    cat > .git/hooks/post-commit << 'EOF'
#!/bin/bash
# 공유 설정 변경 알림 hook

# .shared-configs 디렉토리에 변경사항이 있는지 확인
if [ -d ".shared-configs" ]; then
    cd .shared-configs
    if [ -n "$(git status --porcelain)" ]; then
        echo "� 공유 설정에 변경사항이 있습니다."
        echo "    수동으로 동기화하려면: cd .shared-configs && git add . && git commit && git push"
        echo "    상위 프로젝트 업데이트: git submodule update --remote"
    fi
fi
EOF
    
    # 실행 권한 부여
    chmod +x .git/hooks/post-commit
    
    print_success "기본 Git hooks 설치 완료 (수동 동기화 권장)"
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

# 함수: 사용법 안내 (단순화됨)
show_usage_info() {
    print_success "🎉 Shared GitHub Configs 설정이 완료되었습니다!"
    echo ""
    echo "📋 기본 사용법:"
    echo "1. 최신 설정 가져오기:"
    echo "   git submodule update --remote"
    echo ""
    echo "2. 설정 파일 위치:"
    echo "   - GitHub: .github/ (→ .shared-configs/github-templates/)"
    echo "   - VSCode: .vscode/ (→ .shared-configs/vscode-templates/)"
    echo "   - 가이드: .github/instructions/"
    echo ""
    echo "3. 로컬 커스터마이징:"
    echo "   - 프로젝트별 설정은 별도 파일로 추가"
    echo "   - 예: .github/workflows/project-specific.yml"
    echo ""
    echo "4. 수동 동기화 (변경사항이 있을 때):"
    echo "   cd .shared-configs"
    echo "   git add . && git commit -m 'Update configs' && git push"
    echo "   cd .. && git submodule update --remote"
    echo ""
    print_status "상세 가이드: .shared-configs/README.md"
    print_status "스크립트 도구: .shared-configs/scripts/"
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
