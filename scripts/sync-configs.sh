#!/bin/bash

# Shared GitHub Configs 동기화 스크립트
# Usage: ./sync-configs.sh [OPTIONS]

set -e

# 색상 설정
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# 함수: 도움말
show_help() {
    echo "🔄 Shared GitHub Configs 동기화 스크립트"
    echo ""
    echo "사용법: $0 [OPTIONS]"
    echo ""
    echo "옵션:"
    echo "  -p, --push     로컬 변경사항을 원격 저장소에 푸시"
    echo "  -u, --update   원격 저장소에서 최신 변경사항 가져오기"
    echo "  -f, --force    강제 동기화 (충돌 무시)"
    echo "  -s, --status   동기화 상태 확인"
    echo "  -h, --help     이 도움말 표시"
    echo ""
    echo "예시:"
    echo "  $0 --push      # 변경사항 푸시"
    echo "  $0 --update    # 최신 변경사항 가져오기"
    echo "  $0 --status    # 동기화 상태 확인"
}

# 함수: 환경 확인
check_environment() {
    # Git 확인
    if ! command -v git &> /dev/null; then
        print_error "Git이 설치되어 있지 않습니다."
        exit 1
    fi
    
    # .shared-configs 디렉토리 확인
    if [ ! -d ".shared-configs" ]; then
        print_error ".shared-configs 디렉토리가 없습니다."
        print_error "먼저 setup-new-project.sh를 실행하세요."
        exit 1
    fi
    
    # Git 저장소 확인
    if [ ! -d ".git" ]; then
        print_error "Git 저장소가 아닙니다."
        exit 1
    fi
}

# 함수: 동기화 상태 확인
check_sync_status() {
    print_status "🔍 동기화 상태 확인 중..."
    echo ""
    
    # 현재 프로젝트 상태
    print_status "📁 현재 프로젝트:"
    if [ -n "$(git status --porcelain)" ]; then
        echo "  ❌ 커밋되지 않은 변경사항이 있습니다."
        git status --short | head -10
    else
        echo "  ✅ 깨끗한 상태입니다."
    fi
    echo ""
    
    # Submodule 상태
    print_status "📦 Submodule 상태:"
    cd .shared-configs
    
    # 로컬 변경사항 확인
    if [ -n "$(git status --porcelain)" ]; then
        echo "  ❌ 커밋되지 않은 변경사항이 있습니다:"
        git status --short | head -10
    else
        echo "  ✅ 로컬 변경사항 없음"
    fi
    
    # 원격과의 차이 확인
    git fetch origin &>/dev/null
    
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/main)
    BASE=$(git merge-base HEAD origin/main)
    
    if [ "$LOCAL" = "$REMOTE" ]; then
        echo "  ✅ 원격 저장소와 동기화됨"
    elif [ "$LOCAL" = "$BASE" ]; then
        echo "  ⬆️  원격에 새로운 커밋이 있습니다. (업데이트 필요)"
    elif [ "$REMOTE" = "$BASE" ]; then
        echo "  ⬇️  로컬에 새로운 커밋이 있습니다. (푸시 필요)"
    else
        echo "  ⚠️  로컬과 원격이 분기되었습니다. (수동 해결 필요)"
    fi
    
    cd ..
    echo ""
}

# 함수: 변경사항 푸시
push_changes() {
    print_status "⬆️  변경사항 푸시 중..."
    
    cd .shared-configs
    
    # 변경사항 확인
    if [ -z "$(git status --porcelain)" ]; then
        print_warning "푸시할 변경사항이 없습니다."
        cd ..
        return 0
    fi
    
    # 변경사항 표시
    print_status "다음 변경사항을 푸시합니다:"
    git status --short
    echo ""
    
    # 커밋 메시지 입력 받기
    PROJECT_NAME=$(basename $(dirname $PWD))
    DEFAULT_MSG="Update shared configs from $PROJECT_NAME"
    
    echo "커밋 메시지를 입력하세요 (Enter: 기본 메시지 사용):"
    echo "기본값: $DEFAULT_MSG"
    read -r COMMIT_MSG
    
    if [ -z "$COMMIT_MSG" ]; then
        COMMIT_MSG="$DEFAULT_MSG"
    fi
    
    # 커밋 및 푸시
    git add .
    git commit -m "$COMMIT_MSG"
    git push origin main
    
    print_success "푸시 완료: $COMMIT_MSG"
    
    # 부모 프로젝트에서 submodule 업데이트
    cd ..
    git add .shared-configs
    git commit -m "Update shared configs submodule"
    
    print_success "Submodule 참조 업데이트 완료"
}

# 함수: 최신 변경사항 가져오기
update_configs() {
    local FORCE_UPDATE=$1
    
    print_status "⬇️  최신 변경사항 가져오는 중..."
    
    cd .shared-configs
    
    # 로컬 변경사항 확인
    if [ -n "$(git status --porcelain)" ] && [ "$FORCE_UPDATE" != "force" ]; then
        print_error "커밋되지 않은 변경사항이 있습니다."
        print_error "먼저 변경사항을 커밋하거나 --force 옵션을 사용하세요."
        git status --short
        cd ..
        exit 1
    fi
    
    # 강제 업데이트인 경우 로컬 변경사항 백업
    if [ -n "$(git status --porcelain)" ] && [ "$FORCE_UPDATE" = "force" ]; then
        print_warning "로컬 변경사항을 stash에 백업합니다."
        git stash push -m "Auto-backup before force update $(date)"
    fi
    
    # 원격 변경사항 가져오기
    git fetch origin
    
    # 현재 브랜치 확인
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    if [ "$CURRENT_BRANCH" != "main" ]; then
        print_warning "현재 브랜치가 main이 아닙니다: $CURRENT_BRANCH"
        git checkout main
    fi
    
    # 업데이트 실행
    if [ "$FORCE_UPDATE" = "force" ]; then
        git reset --hard origin/main
        print_warning "강제 업데이트가 완료되었습니다."
    else
        git rebase origin/main
    fi
    
    print_success "최신 변경사항 가져오기 완료"
    
    # 부모 프로젝트에서 submodule 업데이트
    cd ..
    git submodule update --init --recursive
    
    print_success "Submodule 업데이트 완료"
}

# 함수: 충돌 해결 도우미
resolve_conflicts() {
    print_status "⚠️  충돌 해결 도우미"
    echo ""
    
    cd .shared-configs
    
    # 충돌 파일 확인
    CONFLICT_FILES=$(git diff --name-only --diff-filter=U)
    
    if [ -z "$CONFLICT_FILES" ]; then
        print_success "충돌이 없습니다."
        cd ..
        return 0
    fi
    
    print_warning "다음 파일에서 충돌이 발생했습니다:"
    echo "$CONFLICT_FILES"
    echo ""
    
    print_status "충돌 해결 옵션:"
    echo "1. 수동으로 해결하기 (권장)"
    echo "2. 로컬 변경사항 유지"
    echo "3. 원격 변경사항 유지"
    echo "4. 종료"
    echo ""
    
    read -p "선택하세요 (1-4): " choice
    
    case $choice in
        1)
            print_status "수동 해결을 위해 에디터를 열거나 직접 파일을 편집하세요."
            print_status "해결 후 다음 명령어를 실행하세요:"
            echo "  git add ."
            echo "  git rebase --continue"
            ;;
        2)
            for file in $CONFLICT_FILES; do
                git checkout --ours "$file"
            done
            git add .
            git rebase --continue
            print_success "로컬 변경사항으로 해결되었습니다."
            ;;
        3)
            for file in $CONFLICT_FILES; do
                git checkout --theirs "$file"
            done
            git add .
            git rebase --continue
            print_success "원격 변경사항으로 해결되었습니다."
            ;;
        4)
            print_status "충돌 해결을 중단합니다."
            git rebase --abort
            ;;
        *)
            print_error "잘못된 선택입니다."
            ;;
    esac
    
    cd ..
}

# 함수: ntfy 알림 전송 (선택사항)
send_notification() {
    local title="$1"
    local message="$2"
    
    # ntfy 설정이 있는 경우에만 알림 전송
    if [ -n "$NTFY_TOPIC" ] && command -v curl &> /dev/null; then
        curl -s -d "$message" -H "Title: $title" "ntfy.sh/$NTFY_TOPIC" >/dev/null 2>&1 || true
    fi
}

# 메인 함수
main() {
    echo "🔄 Shared GitHub Configs 동기화 도구"
    echo "===================================="
    echo ""
    
    # 인자가 없으면 도움말 표시
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi
    
    # 환경 확인
    check_environment
    
    # 옵션 처리
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--push)
                push_changes
                send_notification "Config Sync" "설정 변경사항이 푸시되었습니다."
                shift
                ;;
            -u|--update)
                update_configs
                send_notification "Config Sync" "최신 설정이 적용되었습니다."
                shift
                ;;
            -f|--force)
                if [ "$2" = "--update" ] || [ "$2" = "-u" ]; then
                    update_configs "force"
                    shift 2
                else
                    print_error "--force는 --update와 함께 사용해야 합니다."
                    exit 1
                fi
                ;;
            -s|--status)
                check_sync_status
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                print_error "알 수 없는 옵션: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# 스크립트 실행
main "$@"
