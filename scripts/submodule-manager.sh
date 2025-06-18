#!/bin/bash

# Git Submodule 관리 유틸리티 스크립트
# 공유 설정 저장소의 submodule을 효율적으로 관리하기 위한 도구

set -e

# 색상 설정
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 함수: 메시지 출력
print_info() {
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

print_section() {
    echo -e "${CYAN}$1${NC}"
    echo "----------------------------------------"
}

# 함수: 도움말
show_help() {
    echo "🔧 Git Submodule 관리 유틸리티"
    echo ""
    echo "사용법: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "명령어:"
    echo "  status      모든 submodule 상태 확인"
    echo "  update      모든 submodule을 최신 상태로 업데이트"
    echo "  sync        원격 저장소와 동기화"
    echo "  check       submodule 설정 검증"
    echo "  clean       불필요한 submodule 파일 정리"
    echo "  list        등록된 모든 submodule 목록 표시"
    echo "  foreach     모든 submodule에서 명령어 실행"
    echo ""
    echo "옵션:"
    echo "  -h, --help  이 도움말 표시"
    echo "  -v          상세 출력"
    echo ""
    echo "예시:"
    echo "  $0 status           # 모든 submodule 상태 확인"
    echo "  $0 update           # 모든 submodule 업데이트"
    echo "  $0 foreach git status  # 모든 submodule에서 git status 실행"
}

# 함수: Git 저장소 확인
check_git_repo() {
    if [ ! -d ".git" ]; then
        print_error "현재 디렉토리가 Git 저장소가 아닙니다."
        exit 1
    fi
}

# 함수: Submodule 상태 확인
cmd_status() {
    print_section "📊 Submodule 상태 확인"
    
    check_git_repo
    
    if [ ! -f ".gitmodules" ]; then
        print_warning ".gitmodules 파일이 없습니다. 등록된 submodule이 없습니다."
        return 0
    fi
    
    # 기본 submodule 상태
    print_info "기본 상태:"
    git submodule status
    
    echo ""
    
    # 상세 상태 (verbose 모드)
    if [ "$VERBOSE" = "1" ]; then
        print_info "상세 상태:"
        git submodule foreach 'echo "=== $name ===" && git status --short'
    fi
    
    # 업데이트 가능한 submodule 확인
    print_info "업데이트 확인 중..."
    outdated_modules=()
    
    git submodule foreach --quiet '
        if [ -n "$(git log HEAD..origin/$(git symbolic-ref --short HEAD) --oneline 2>/dev/null)" ]; then
            echo "🔄 $name: 업데이트 가능"
            outdated_modules+=("$name")
        else
            echo "✅ $name: 최신 상태"
        fi
    '
    
    if [ ${#outdated_modules[@]} -gt 0 ]; then
        echo ""
        print_warning "업데이트가 필요한 submodule이 있습니다. 'update' 명령어를 사용하세요."
    fi
}

# 함수: Submodule 업데이트
cmd_update() {
    print_section "🔄 Submodule 업데이트"
    
    check_git_repo
    
    if [ ! -f ".gitmodules" ]; then
        print_warning "업데이트할 submodule이 없습니다."
        return 0
    fi
    
    print_info "모든 submodule을 최신 상태로 업데이트 중..."
    
    # 원격 저장소에서 최신 변경사항 가져오기
    git submodule update --remote --rebase
    
    # 초기화되지 않은 submodule 처리
    git submodule update --init --recursive
    
    print_success "Submodule 업데이트 완료"
    
    # 변경된 submodule이 있는지 확인
    if [ -n "$(git diff --name-only)" ]; then
        print_info "변경된 submodule이 있습니다:"
        git diff --name-only
        
        print_warning "변경사항을 커밋하시겠습니까? (y/N)"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            git add .
            git commit -m "Update submodules to latest versions"
            print_success "변경사항이 커밋되었습니다."
        fi
    else
        print_info "모든 submodule이 이미 최신 상태입니다."
    fi
}

# 함수: 동기화
cmd_sync() {
    print_section "🔄 Submodule 동기화"
    
    check_git_repo
    
    print_info "submodule URL 동기화 중..."
    git submodule sync --recursive
    
    print_info "최신 변경사항 가져오기..."
    git submodule update --init --recursive --remote
    
    print_success "동기화 완료"
}

# 함수: 설정 검증
cmd_check() {
    print_section "🔍 Submodule 설정 검증"
    
    check_git_repo
    
    issues=0
    
    # .gitmodules 파일 확인
    if [ ! -f ".gitmodules" ]; then
        print_warning ".gitmodules 파일이 없습니다."
        ((issues++))
    else
        print_success ".gitmodules 파일 존재"
        
        # .gitmodules 내용 검증
        while IFS= read -r line; do
            if [[ $line =~ ^\[submodule.*\]$ ]]; then
                module_name=$(echo "$line" | sed 's/\[submodule "\(.*\)"\]/\1/')
                print_info "모듈 검증: $module_name"
                
                # 디렉토리 존재 확인
                if [ ! -d "$module_name" ]; then
                    print_error "디렉토리가 없습니다: $module_name"
                    ((issues++))
                fi
                
                # Git 저장소 확인
                if [ ! -d "$module_name/.git" ]; then
                    print_error "Git 저장소가 아닙니다: $module_name"
                    ((issues++))
                fi
            fi
        done < .gitmodules
    fi
    
    # Git 설정 확인
    print_info "Git 설정 확인..."
    if git config diff.submodule log &>/dev/null; then
        print_success "diff.submodule 설정 OK"
    else
        print_warning "diff.submodule이 설정되지 않았습니다."
        print_info "권장 설정: git config diff.submodule log"
    fi
    
    if git config status.submodulesummary 1 &>/dev/null; then
        print_success "status.submodulesummary 설정 OK"
    else
        print_warning "status.submodulesummary가 설정되지 않았습니다."
        print_info "권장 설정: git config status.submodulesummary 1"
    fi
    
    if [ $issues -eq 0 ]; then
        print_success "✅ 모든 검증을 통과했습니다."
    else
        print_error "❌ $issues개의 문제가 발견되었습니다."
        return 1
    fi
}

# 함수: 정리
cmd_clean() {
    print_section "🧹 Submodule 정리"
    
    check_git_repo
    
    print_info "사용하지 않는 submodule 파일 정리 중..."
    
    # .git/modules에서 사용하지 않는 항목 찾기
    if [ -d ".git/modules" ]; then
        for module_dir in .git/modules/*/; do
            if [ -d "$module_dir" ]; then
                module_name=$(basename "$module_dir")
                if [ ! -d "$module_name" ]; then
                    print_warning "사용하지 않는 모듈 데이터 발견: $module_name"
                    print_warning "제거하시겠습니까? (y/N)"
                    read -r response
                    if [[ "$response" =~ ^[Yy]$ ]]; then
                        rm -rf "$module_dir"
                        print_success "제거 완료: $module_name"
                    fi
                fi
            fi
        done
    fi
    
    # Submodule 캐시 정리
    git submodule foreach --recursive git gc --prune=now
    
    print_success "정리 완료"
}

# 함수: 목록 표시
cmd_list() {
    print_section "📋 Submodule 목록"
    
    check_git_repo
    
    if [ ! -f ".gitmodules" ]; then
        print_warning "등록된 submodule이 없습니다."
        return 0
    fi
    
    print_info "등록된 submodule:"
    git config -f .gitmodules --get-regexp '^submodule\..*\.path$' | \
        sed 's/^submodule\.\(.*\)\.path /\1: /' | \
        while IFS=': ' read -r name path; do
            url=$(git config -f .gitmodules --get "submodule.$name.url")
            branch=$(git config -f .gitmodules --get "submodule.$name.branch" || echo "main")
            
            echo "  📁 $name"
            echo "     경로: $path"
            echo "     URL: $url"
            echo "     브랜치: $branch"
            
            if [ -d "$path" ]; then
                cd "$path"
                current_commit=$(git rev-parse --short HEAD 2>/dev/null || echo "없음")
                current_branch=$(git branch --show-current 2>/dev/null || echo "detached")
                echo "     현재 커밋: $current_commit"
                echo "     현재 브랜치: $current_branch"
                cd - >/dev/null
            else
                echo "     상태: 초기화되지 않음"
            fi
            echo ""
        done
}

# 함수: 모든 submodule에서 명령어 실행
cmd_foreach() {
    if [ $# -eq 0 ]; then
        print_error "실행할 명령어를 지정해주세요."
        echo "예: $0 foreach git status"
        exit 1
    fi
    
    print_section "🔄 모든 Submodule에서 명령어 실행"
    print_info "실행할 명령어: $*"
    echo ""
    
    check_git_repo
    
    if [ ! -f ".gitmodules" ]; then
        print_warning "실행할 submodule이 없습니다."
        return 0
    fi
    
    git submodule foreach "$@"
}

# 메인 함수
main() {
    # 옵션 파싱
    VERBOSE=0
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=1
                shift
                ;;
            status|update|sync|check|clean|list|foreach)
                COMMAND=$1
                shift
                break
                ;;
            *)
                print_error "알 수 없는 옵션: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 명령어가 없으면 기본적으로 status 실행
    if [ -z "$COMMAND" ]; then
        COMMAND="status"
    fi
    
    # 명령어 실행
    case $COMMAND in
        status)
            cmd_status
            ;;
        update)
            cmd_update
            ;;
        sync)
            cmd_sync
            ;;
        check)
            cmd_check
            ;;
        clean)
            cmd_clean
            ;;
        list)
            cmd_list
            ;;
        foreach)
            cmd_foreach "$@"
            ;;
        *)
            print_error "알 수 없는 명령어: $COMMAND"
            show_help
            exit 1
            ;;
    esac
}

# 스크립트 실행
main "$@"
