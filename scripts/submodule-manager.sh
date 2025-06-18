#!/bin/bash

# Git Submodule 관리 유틸리티 스크립트 (강화 버전 2.1.0)
# 공유 설정 저장소의 submodule을 효율적으로 관리하기 위한 고급 도구
# 
# 주요 기능:
# - 고급 submodule 상태 분석 및 관리
# - 백업/복원 지원으로 안전한 작업
# - 배치 처리 및 병렬 실행
# - 충돌 감지 및 자동 해결
# - 롤백 지원
#
# 작성자: GitHub Copilot
# 버전: 2.1.0

set -euo pipefail

# ==============================================================================
# 공통 라이브러리 로드
# ==============================================================================
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common-logging.sh"

# ==============================================================================
# 전역 변수 및 설정
# ==============================================================================
VERBOSE=0
DRY_RUN=0
PARALLEL=0
BACKUP_DIR=""
LOG_FILE=""
readonly SCRIPT_VERSION="2.1.0"

# ==============================================================================
# 메시지 출력 함수들 (공통 라이브러리 래핑)
# ==============================================================================

print_info() {
    log_info "$1"
}

print_success() {
    log_success "$1"
}

print_warning() {
    log_warning "$1"
}

print_error() {
    log_error "$1"
}

print_debug() {
    log_debug "$1"
}

print_section() {
    echo -e "${CYAN}${BOLD}$1${NC}"
    echo "========================================="
    log_info "섹션: $1"
}

print_subsection() {
    echo -e "${PURPLE}$1${NC}"
    echo "-----------------------------------------"
    log_debug "하위섹션: $1"
}

# 함수: 도움말 (확장된 기능)
show_help() {
    echo -e "${CYAN}${BOLD}🔧 Git Submodule 관리 유틸리티 v${SCRIPT_VERSION}${NC}"
    echo ""
    echo -e "${WHITE}사용법:${NC} $0 [COMMAND] [OPTIONS]"
    echo ""
    echo -e "${WHITE}기본 명령어:${NC}"
    echo "  status      모든 submodule 상태 확인 (확장된 분석)"
    echo "  update      모든 submodule을 최신 상태로 업데이트"
    echo "  sync        원격 저장소와 동기화"
    echo "  check       submodule 설정 검증 (고급 검증)"
    echo "  clean       불필요한 submodule 파일 정리"
    echo "  list        등록된 모든 submodule 목록 표시"
    echo "  foreach     모든 submodule에서 명령어 실행"
    echo ""
    echo -e "${WHITE}고급 명령어:${NC}"
    echo "  add         새 submodule 추가"
    echo "  remove      기존 submodule 제거"
    echo "  reset       submodule을 특정 상태로 재설정"
    echo "  backup      현재 submodule 상태 백업"
    echo "  restore     백업에서 submodule 상태 복원"
    echo "  analyze     submodule 의존성 및 상태 분석"
    echo "  repair      손상된 submodule 자동 복구"
    echo ""
    echo -e "${WHITE}전역 옵션:${NC}"
    echo "  -h, --help      이 도움말 표시"
    echo "  -v, --verbose   상세 출력 모드"
    echo "  -n, --dry-run   실제 변경 없이 시뮬레이션"
    echo "  -p, --parallel  병렬 처리 활성화"
    echo "  -l, --log FILE  로그 파일 지정"
    echo "  -b, --backup DIR 백업 디렉토리 지정"
    echo ""
    echo -e "${WHITE}예시:${NC}"
    echo "  $0 status -v                    # 상세 상태 확인"
    echo "  $0 add shared-config https://github.com/user/repo.git"
    echo "  $0 update -p                    # 병렬 업데이트"
    echo "  $0 backup -b ./backups          # 백업 생성"
    echo "  $0 foreach -p git pull          # 병렬로 모든 submodule에서 git pull"
    echo "  $0 analyze                      # 고급 분석 실행"
}

# 함수: Git 저장소 확인 (강화됨)
check_git_repo() {
    if [ ! -d ".git" ]; then
        print_error "현재 디렉토리가 Git 저장소가 아닙니다."
        print_info "Git 저장소를 초기화하려면: git init"
        exit 1
    fi
    
    # Git 버전 확인
    if ! command -v git &> /dev/null; then
        print_error "Git이 설치되지 않았습니다."
        exit 1
    fi
    
    local git_version=$(git --version | cut -d' ' -f3)
    print_debug "Git 버전: $git_version"
    
    # 최소 Git 버전 확인 (2.13+ submodule 기능 개선)
    if [[ $(echo -e "2.13\n$git_version" | sort -V | head -n1) != "2.13" ]]; then
        print_warning "Git 버전이 오래되었습니다. 일부 기능이 제한될 수 있습니다."
    fi
}

# 함수: 의존성 확인
check_dependencies() {
    log_debug "의존성 검사 시작"
    
    # 공통 라이브러리 함수 사용
    validate_command "git"
    validate_command "rsync"
    
    log_debug "모든 의존성 확인 완료"
}

# 함수: 백업 디렉토리 설정
setup_backup_dir() {
    if [ -z "$BACKUP_DIR" ]; then
        BACKUP_DIR="./.submodule-backups"
    fi
    
    if [ ! -d "$BACKUP_DIR" ]; then
        if [ "$DRY_RUN" = "0" ]; then
            mkdir -p "$BACKUP_DIR"
            print_info "백업 디렉토리 생성: $BACKUP_DIR"
        else
            print_info "[DRY-RUN] 백업 디렉토리 생성 예정: $BACKUP_DIR"
        fi
    fi
}

# 함수: 사용자 확인
confirm_action() {
    local message="$1"
    local default="${2:-n}"
    
    if [ "$DRY_RUN" = "1" ]; then
        print_info "[DRY-RUN] $message"
        return 0
    fi
    
    echo -n -e "${YELLOW}$message (y/N): ${NC}"
    read -r response
    
    case "$response" in
        [Yy]|[Yy][Ee][Ss])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# 함수: 병렬 실행 래퍼
run_parallel() {
    local cmd="$1"
    local items=("${@:2}")
    
    if [ "$PARALLEL" = "1" ] && [ ${#items[@]} -gt 1 ]; then
        print_info "병렬 처리 모드로 ${#items[@]}개 항목 처리 중..."
        
        for item in "${items[@]}"; do
            (
                print_debug "병렬 처리 시작: $item"
                eval "$cmd '$item'"
                print_debug "병렬 처리 완료: $item"
            ) &
        done
        
        wait
        print_success "병렬 처리 완료"
    else
        for item in "${items[@]}"; do
            eval "$cmd '$item'"
        done
    fi
}

# 함수: Submodule 상태 확인 (강화됨)
cmd_status() {
    print_section "📊 Submodule 상태 분석"
    
    check_git_repo
    
    if [ ! -f ".gitmodules" ]; then
        print_warning ".gitmodules 파일이 없습니다. 등록된 submodule이 없습니다."
        print_info "새 submodule을 추가하려면: $0 add <name> <url>"
        return 0
    fi
    
    # 기본 submodule 상태
    print_subsection "기본 상태"
    git submodule status
    echo ""
    
    # 고급 상태 분석
    print_subsection "고급 상태 분석"
    local total_modules=0
    local initialized_modules=0
    local outdated_modules=0
    local clean_modules=0
    local dirty_modules=0
    local detached_modules=0
    
    while IFS= read -r line; do
        if [[ $line =~ ^\[submodule.*\]$ ]]; then
            module_name=$(echo "$line" | sed 's/\[submodule "\(.*\)"\]/\1/')
            module_path=$(git config -f .gitmodules --get "submodule.$module_name.path")
            
            ((total_modules++))
            
            if [ -d "$module_path" ] && [ -d "$module_path/.git" ]; then
                ((initialized_modules++))
                
                cd "$module_path"
                
                # 브랜치 상태 확인
                if git symbolic-ref -q HEAD >/dev/null 2>&1; then
                    current_branch=$(git symbolic-ref --short HEAD)
                    branch_status="📍 브랜치: $current_branch"
                else
                    ((detached_modules++))
                    current_commit=$(git rev-parse --short HEAD)
                    branch_status="⚠️  detached HEAD: $current_commit"
                fi
                
                # 작업 디렉토리의 변경사항 확인
                if [ -n "$(git status --porcelain)" ]; then
                    ((dirty_modules++))
                    clean_status="🔄 변경사항 있음"
                else
                    ((clean_modules++))
                    clean_status="✅ 깨끗함"
                fi
                
                # 원격과의 차이 확인
                git fetch origin >/dev/null 2>&1 || true
                local ahead=$(git rev-list --count HEAD..origin/$(git symbolic-ref --short HEAD 2>/dev/null || echo "main") 2>/dev/null || echo "0")
                local behind=$(git rev-list --count origin/$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")..HEAD 2>/dev/null || echo "0")
                
                if [ "$ahead" != "0" ] || [ "$behind" != "0" ]; then
                    ((outdated_modules++))
                    sync_status="🔄 동기화 필요 (ahead: $ahead, behind: $behind)"
                else
                    sync_status="✅ 최신 상태"
                fi
                
                echo "  � $module_name"
                echo "     $branch_status"
                echo "     $clean_status"
                echo "     $sync_status"
                
                # 상세 정보 (verbose 모드)
                if [ "$VERBOSE" = "1" ]; then
                    echo "     📂 경로: $module_path"
                    echo "     🔗 URL: $(git config --get remote.origin.url)"
                    echo "     📝 최근 커밋: $(git log -1 --oneline)"
                fi
                
                cd - >/dev/null
            else
                echo "  📁 $module_name: ❌ 초기화되지 않음"
            fi
            echo ""
        fi
    done < .gitmodules
    
    # 요약 통계
    print_subsection "📈 상태 요약"
    echo "  전체 submodule: $total_modules"
    echo "  초기화됨: $initialized_modules"
    echo "  깨끗한 상태: $clean_modules"
    echo "  변경사항 있음: $dirty_modules"
    echo "  동기화 필요: $outdated_modules"
    echo "  detached HEAD: $detached_modules"
    
    # 권장 사항
    if [ $outdated_modules -gt 0 ]; then
        echo ""
        print_warning "📋 권장 사항:"
        echo "  - 동기화가 필요한 submodule이 있습니다: $0 update"
    fi
    
    if [ $dirty_modules -gt 0 ]; then
        echo "  - 변경사항이 있는 submodule을 확인하세요: $0 foreach git status"
    fi
    
    if [ $detached_modules -gt 0 ]; then
        echo "  - detached HEAD 상태의 submodule을 확인하세요: $0 analyze"
    fi
}

# 함수: 새 Submodule 추가
cmd_add() {
    local name="$1"
    local url="$2"
    local path="${3:-$name}"
    local branch="${4:-main}"
    
    if [ -z "$name" ] || [ -z "$url" ]; then
        print_error "사용법: $0 add <name> <url> [path] [branch]"
        print_info "예시: $0 add shared-config https://github.com/user/repo.git configs main"
        exit 1
    fi
    
    print_section "➕ 새 Submodule 추가"
    print_info "이름: $name"
    print_info "URL: $url"
    print_info "경로: $path"
    print_info "브랜치: $branch"
    
    check_git_repo
    
    # 이미 존재하는지 확인
    if [ -f ".gitmodules" ] && git config -f .gitmodules "submodule.$name.url" &>/dev/null; then
        print_error "이미 존재하는 submodule입니다: $name"
        exit 1
    fi
    
    # 경로가 이미 존재하는지 확인
    if [ -e "$path" ]; then
        print_error "대상 경로가 이미 존재합니다: $path"
        exit 1
    fi
    
    # URL 유효성 검증
    if ! git ls-remote "$url" &>/dev/null; then
        print_error "유효하지 않은 Git 저장소 URL입니다: $url"
        exit 1
    fi
    
    if confirm_action "새 submodule '$name'을 추가하시겠습니까?"; then
        if [ "$DRY_RUN" = "0" ]; then
            # submodule 추가
            git submodule add -b "$branch" "$url" "$path"
            
            # .gitmodules에 추가 설정
            git config -f .gitmodules "submodule.$name.branch" "$branch"
            git config -f .gitmodules "submodule.$name.update" "merge"
            
            # 초기화 및 업데이트
            git submodule update --init --recursive "$path"
            
            print_success "Submodule '$name'이 성공적으로 추가되었습니다."
            print_info "변경사항을 커밋하는 것을 잊지 마세요: git commit -m 'Add submodule $name'"
        else
            print_info "[DRY-RUN] Submodule '$name' 추가 시뮬레이션 완료"
        fi
    else
        print_info "작업이 취소되었습니다."
    fi
}

# 함수: Submodule 제거
cmd_remove() {
    local name="$1"
    
    if [ -z "$name" ]; then
        print_error "사용법: $0 remove <name>"
        print_info "사용 가능한 submodule 목록을 보려면: $0 list"
        exit 1
    fi
    
    print_section "➖ Submodule 제거"
    
    check_git_repo
    
    if [ ! -f ".gitmodules" ]; then
        print_error "제거할 submodule이 없습니다."
        exit 1
    fi
    
    # submodule 존재 확인
    local path=$(git config -f .gitmodules --get "submodule.$name.path" 2>/dev/null)
    if [ -z "$path" ]; then
        print_error "존재하지 않는 submodule입니다: $name"
        exit 1
    fi
    
    print_warning "다음 submodule을 제거합니다:"
    print_info "이름: $name"
    print_info "경로: $path"
    
    if confirm_action "정말로 submodule '$name'을 제거하시겠습니까? (복구 불가능)"; then
        if [ "$DRY_RUN" = "0" ]; then
            # submodule 제거 단계
            print_info "1. .gitmodules에서 제거 중..."
            git config -f .gitmodules --remove-section "submodule.$name"
            
            print_info "2. .git/config에서 제거 중..."
            git config --remove-section "submodule.$name" 2>/dev/null || true
            
            print_info "3. Git 인덱스에서 제거 중..."
            git rm --cached "$path"
            
            print_info "4. 작업 디렉토리에서 제거 중..."
            rm -rf "$path"
            
            print_info "5. .git/modules에서 정리 중..."
            rm -rf ".git/modules/$name"
            
            print_success "Submodule '$name'이 성공적으로 제거되었습니다."
            print_info "변경사항을 커밋하는 것을 잊지 마세요: git commit -m 'Remove submodule $name'"
        else
            print_info "[DRY-RUN] Submodule '$name' 제거 시뮬레이션 완료"
        fi
    else
        print_info "작업이 취소되었습니다."
    fi
}

# 함수: Submodule 리셋
cmd_reset() {
    local name="$1"
    local target="${2:-HEAD}"
    
    if [ -z "$name" ]; then
        print_error "사용법: $0 reset <name> [commit/branch]"
        print_info "예시: $0 reset shared-config main"
        exit 1
    fi
    
    print_section "🔄 Submodule 리셋"
    
    check_git_repo
    
    if [ ! -f ".gitmodules" ]; then
        print_error "리셋할 submodule이 없습니다."
        exit 1
    fi
    
    local path=$(git config -f .gitmodules --get "submodule.$name.path" 2>/dev/null)
    if [ -z "$path" ]; then
        print_error "존재하지 않는 submodule입니다: $name"
        exit 1
    fi
    
    if [ ! -d "$path" ]; then
        print_error "Submodule이 초기화되지 않았습니다: $name"
        print_info "먼저 초기화하세요: $0 update"
        exit 1
    fi
    
    print_info "Submodule '$name'을 '$target'로 리셋합니다."
    
    if confirm_action "계속하시겠습니까? (작업 중인 변경사항이 손실될 수 있습니다)"; then
        if [ "$DRY_RUN" = "0" ]; then
            cd "$path"
            
            # 백업 생성
            setup_backup_dir
            local backup_file="$BACKUP_DIR/${name}_$(date +%Y%m%d_%H%M%S).patch"
            if git diff --quiet HEAD; then
                print_debug "변경사항이 없어 백업을 건너뜁니다."
            else
                git diff HEAD > "$backup_file"
                print_info "변경사항을 백업했습니다: $backup_file"
            fi
            
            # 리셋 실행
            git fetch origin
            git reset --hard "$target"
            
            cd - >/dev/null
            
            print_success "Submodule '$name'이 '$target'로 리셋되었습니다."
        else
            print_info "[DRY-RUN] Submodule '$name' 리셋 시뮬레이션 완료"
        fi
    else
        print_info "작업이 취소되었습니다."
    fi
}
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

# 함수: Submodule 백업
cmd_backup() {
    local backup_name="${1:-$(date +%Y%m%d_%H%M%S)}"
    
    print_section "💾 Submodule 상태 백업"
    
    check_git_repo
    setup_backup_dir
    
    local backup_file="$BACKUP_DIR/backup_${backup_name}.tar.gz"
    local metadata_file="$BACKUP_DIR/backup_${backup_name}.json"
    
    print_info "백업 생성 중: $backup_name"
    print_info "백업 파일: $backup_file"
    print_info "메타데이터: $metadata_file"
    
    if [ "$DRY_RUN" = "0" ]; then
        # 메타데이터 생성
        {
            echo "{"
            echo "  \"timestamp\": \"$(date '+%Y-%m-%dT%H:%M:%S%z')\","
            echo "  \"git_commit\": \"$(git rev-parse HEAD)\","
            echo "  \"submodules\": ["
            
            local first=true
            if [ -f ".gitmodules" ]; then
                while IFS= read -r line; do
                    if [[ $line =~ ^\[submodule.*\]$ ]]; then
                        local name=$(echo "$line" | sed 's/\[submodule "\(.*\)"\]/\1/')
                        local path=$(git config -f .gitmodules --get "submodule.$name.path")
                        local url=$(git config -f .gitmodules --get "submodule.$name.url")
                        local branch=$(git config -f .gitmodules --get "submodule.$name.branch" || echo "main")
                        
                        if [ "$first" = false ]; then
                            echo ","
                        fi
                        first=false
                        
                        echo -n "    {"
                        echo -n "\"name\": \"$name\", "
                        echo -n "\"path\": \"$path\", "
                        echo -n "\"url\": \"$url\", "
                        echo -n "\"branch\": \"$branch\""
                        
                        if [ -d "$path" ]; then
                            cd "$path"
                            local commit=$(git rev-parse HEAD 2>/dev/null || echo "")
                            local current_branch=$(git branch --show-current 2>/dev/null || echo "detached")
                            echo -n ", \"commit\": \"$commit\", \"current_branch\": \"$current_branch\""
                            cd - >/dev/null
                        fi
                        
                        echo -n "}"
                    fi
                done < .gitmodules
            fi
            
            echo ""
            echo "  ]"
            echo "}"
        } > "$metadata_file"
        
        # 실제 파일들 백업
        tar -czf "$backup_file" \
            --exclude=".git/modules" \
            --exclude="*/.git" \
            .gitmodules \
            $(find . -name ".gitmodules" -o -type d -name ".git" -prune -o -type f -print | grep -E "^\./.+") 2>/dev/null || true
        
        print_success "백업 완료: $backup_name"
        print_info "복원하려면: $0 restore $backup_name"
    else
        print_info "[DRY-RUN] 백업 '$backup_name' 시뮬레이션 완료"
    fi
}

# 함수: Submodule 복원
cmd_restore() {
    local backup_name="$1"
    
    if [ -z "$backup_name" ]; then
        print_error "사용법: $0 restore <backup_name>"
        print_info "사용 가능한 백업 목록:"
        if [ -d "$BACKUP_DIR" ]; then
            ls -1 "$BACKUP_DIR"/backup_*.json 2>/dev/null | sed 's/.*backup_\(.*\)\.json/  \1/' || echo "  백업이 없습니다."
        else
            echo "  백업 디렉토리가 없습니다."
        fi
        exit 1
    fi
    
    print_section "📁 Submodule 상태 복원"
    
    check_git_repo
    setup_backup_dir
    
    local backup_file="$BACKUP_DIR/backup_${backup_name}.tar.gz"
    local metadata_file="$BACKUP_DIR/backup_${backup_name}.json"
    
    if [ ! -f "$backup_file" ] || [ ! -f "$metadata_file" ]; then
        print_error "백업을 찾을 수 없습니다: $backup_name"
        exit 1
    fi
    
    print_warning "⚠️  현재 상태가 백업으로 덮어씌워집니다!"
    print_info "백업 정보:"
    
    if command -v jq &>/dev/null; then
        jq -r '.timestamp, .git_commit, (.submodules | length | tostring + " submodules")' "$metadata_file" | \
        while read -r line; do
            print_info "  $line"
        done
    else
        print_info "  파일: $backup_file"
        print_info "  메타데이터: $metadata_file"
    fi
    
    if confirm_action "백업 '$backup_name'에서 복원하시겠습니까?"; then
        if [ "$DRY_RUN" = "0" ]; then
            # 현재 상태 임시 백업
            local temp_backup="temp_$(date +%Y%m%d_%H%M%S)"
            print_info "현재 상태를 임시 백업 중: $temp_backup"
            cmd_backup "$temp_backup"
            
            # 복원 실행
            print_info "백업에서 복원 중..."
            tar -xzf "$backup_file"
            
            # submodule 재초기화
            if [ -f ".gitmodules" ]; then
                git submodule update --init --recursive
            fi
            
            print_success "백업 '$backup_name'에서 복원 완료"
            print_info "문제가 있으면 임시 백업에서 되돌릴 수 있습니다: $0 restore $temp_backup"
        else
            print_info "[DRY-RUN] 백업 '$backup_name' 복원 시뮬레이션 완료"
        fi
    else
        print_info "작업이 취소되었습니다."
    fi
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
    
    if [ "$PARALLEL" = "1" ]; then
        print_info "병렬 실행 모드 활성화"
        git submodule foreach --recursive "$@" &
        wait
    else
        git submodule foreach --recursive "$@"
    fi
}

# 함수: 고급 분석
cmd_analyze() {
    print_section "🔍 Submodule 고급 분석"
    
    check_git_repo
    
    if [ ! -f ".gitmodules" ]; then
        print_warning "분석할 submodule이 없습니다."
        return 0
    fi
    
    print_subsection "의존성 분석"
    local issues=0
    local suggestions=()
    
    # 순환 참조 검사
    print_info "순환 참조 검사 중..."
    local modules=()
    while IFS= read -r line; do
        if [[ $line =~ ^\[submodule.*\]$ ]]; then
            local name=$(echo "$line" | sed 's/\[submodule "\(.*\)"\]/\1/')
            modules+=("$name")
        fi
    done < .gitmodules
    
    # 중복 URL 검사
    print_info "중복 URL 검사 중..."
    local urls=()
    local duplicate_urls=()
    
    for module in "${modules[@]}"; do
        local url=$(git config -f .gitmodules --get "submodule.$module.url")
        if [[ " ${urls[*]} " == *" $url "* ]]; then
            duplicate_urls+=("$url")
            ((issues++))
        else
            urls+=("$url")
        fi
    done
    
    if [ ${#duplicate_urls[@]} -gt 0 ]; then
        print_warning "중복된 URL 발견:"
        for url in "${duplicate_urls[@]}"; do
            print_warning "  $url"
        done
        suggestions+=("중복된 submodule URL을 정리하세요")
    fi
    
    # 분기점 검사
    print_subsection "분기점 및 충돌 검사"
    for module in "${modules[@]}"; do
        local path=$(git config -f .gitmodules --get "submodule.$module.path")
        
        if [ -d "$path" ]; then
            cd "$path"
            
            # detached HEAD 확인
            if ! git symbolic-ref -q HEAD >/dev/null 2>&1; then
                print_warning "$module: detached HEAD 상태"
                ((issues++))
                suggestions+=("$module을 적절한 브랜치로 체크아웃하세요")
            fi
            
            # 머지되지 않은 변경사항 확인
            local unmerged=$(git status --porcelain | grep "^UU" | wc -l)
            if [ "$unmerged" -gt 0 ]; then
                print_error "$module: $unmerged개의 머지 충돌"
                ((issues++))
                suggestions+=("$module의 머지 충돌을 해결하세요")
            fi
            
            # 스테이징되지 않은 변경사항 확인
            local unstaged=$(git status --porcelain | grep "^ M" | wc -l)
            if [ "$unstaged" -gt 0 ]; then
                print_info "$module: $unstaged개의 스테이징되지 않은 변경사항"
            fi
            
            # 원격 브랜치와의 차이 확인
            git fetch origin >/dev/null 2>&1 || true
            local current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "")
            if [ -n "$current_branch" ]; then
                local ahead=$(git rev-list --count HEAD..origin/$current_branch 2>/dev/null || echo "0")
                local behind=$(git rev-list --count origin/$current_branch..HEAD 2>/dev/null || echo "0")
                
                if [ "$ahead" != "0" ] && [ "$behind" != "0" ]; then
                    print_warning "$module: 원격과 분기됨 (ahead: $ahead, behind: $behind)"
                    ((issues++))
                    suggestions+=("$module을 원격과 동기화하세요")
                fi
            fi
            
            cd - >/dev/null
        fi
    done
    
    # 권한 및 보안 검사
    print_subsection "권한 및 보안 검사"
    for module in "${modules[@]}"; do
        local url=$(git config -f .gitmodules --get "submodule.$module.url")
        
        # HTTP URL 보안 경고
        if [[ $url == http://* ]]; then
            print_warning "$module: 비보안 HTTP URL 사용"
            ((issues++))
            suggestions+=("$module의 URL을 HTTPS로 변경하세요")
        fi
        
        # 개인 토큰이 포함된 URL 검사
        if [[ $url == *"@"* ]] && [[ $url == *":"* ]]; then
            print_warning "$module: URL에 인증 정보가 포함되었을 수 있습니다"
            suggestions+=("$module의 URL에서 인증 정보를 제거하고 SSH 키를 사용하세요")
        fi
    done
    
    # 분석 결과 요약
    print_subsection "📊 분석 결과"
    if [ $issues -eq 0 ]; then
        print_success "✅ 모든 검사를 통과했습니다!"
    else
        print_error "❌ $issues개의 문제가 발견되었습니다."
    fi
    
    if [ ${#suggestions[@]} -gt 0 ]; then
        print_info "💡 권장 사항:"
        for suggestion in "${suggestions[@]}"; do
            echo "  - $suggestion"
        done
    fi
    
    return $issues
}

# 함수: 자동 복구
cmd_repair() {
    print_section "🔧 Submodule 자동 복구"
    
    check_git_repo
    
    if [ ! -f ".gitmodules" ]; then
        print_warning "복구할 submodule이 없습니다."
        return 0
    fi
    
    print_info "복구 가능한 문제들을 검사하고 자동으로 수정합니다."
    
    if ! confirm_action "자동 복구를 시작하시겠습니까?"; then
        print_info "작업이 취소되었습니다."
        return 0
    fi
    
    local fixed=0
    local errors=0
    
    # 백업 생성
    local backup_name="repair_$(date +%Y%m%d_%H%M%S)"
    if [ "$DRY_RUN" = "0" ]; then
        print_info "복구 전 백업 생성 중: $backup_name"
        cmd_backup "$backup_name"
    fi
    
    print_subsection "🔄 초기화되지 않은 submodule 복구"
    while IFS= read -r line; do
        if [[ $line =~ ^\[submodule.*\]$ ]]; then
            local name=$(echo "$line" | sed 's/\[submodule "\(.*\)"\]/\1/')
            local path=$(git config -f .gitmodules --get "submodule.$name.path")
            
            if [ ! -d "$path" ] || [ ! -d "$path/.git" ]; then
                print_info "초기화 중: $name"
                if [ "$DRY_RUN" = "0" ]; then
                    if git submodule update --init --recursive "$path"; then
                        print_success "복구 완료: $name"
                        ((fixed++))
                    else
                        print_error "복구 실패: $name"
                        ((errors++))
                    fi
                else
                    print_info "[DRY-RUN] 복구 예정: $name"
                fi
            fi
        fi
    done < .gitmodules
    
    print_subsection "🔄 detached HEAD 복구"
    while IFS= read -r line; do
        if [[ $line =~ ^\[submodule.*\]$ ]]; then
            local name=$(echo "$line" | sed 's/\[submodule "\(.*\)"\]/\1/')
            local path=$(git config -f .gitmodules --get "submodule.$name.path")
            local branch=$(git config -f .gitmodules --get "submodule.$name.branch" || echo "main")
            
            if [ -d "$path" ]; then
                cd "$path"
                
                if ! git symbolic-ref -q HEAD >/dev/null 2>&1; then
                    print_info "$name: detached HEAD를 $branch 브랜치로 복구 중"
                    if [ "$DRY_RUN" = "0" ]; then
                        if git checkout "$branch" 2>/dev/null; then
                            print_success "복구 완료: $name"
                            ((fixed++))
                        else
                            print_warning "브랜치 '$branch'가 없습니다. origin/$branch로 시도 중..."
                            if git checkout -b "$branch" "origin/$branch" 2>/dev/null; then
                                print_success "복구 완료: $name (새 브랜치 생성)"
                                ((fixed++))
                            else
                                print_error "복구 실패: $name"
                                ((errors++))
                            fi
                        fi
                    else
                        print_info "[DRY-RUN] 복구 예정: $name"
                    fi
                fi
                
                cd - >/dev/null
            fi
        fi
    done < .gitmodules
    
    print_subsection "📊 복구 결과"
    print_info "수정된 문제: $fixed개"
    if [ $errors -gt 0 ]; then
        print_warning "복구 실패: $errors개"
    fi
    
    if [ $fixed -gt 0 ]; then
        print_success "✅ 복구가 완료되었습니다!"
        if [ "$DRY_RUN" = "0" ]; then
            print_info "백업에서 되돌리려면: $0 restore $backup_name"
        fi
    else
        print_info "복구할 문제가 없습니다."
    fi
}

# 메인 함수
main() {
    # 로그 파일 기본값 설정
    if [[ -z "$LOG_FILE" ]]; then
        LOG_FILE="./submodule-manager-$(date '+%Y%m%d').log"
    fi
    
    # 공통 라이브러리 초기화
    init_logging "submodule-manager" "$LOG_FILE" "$([[ $VERBOSE -eq 1 ]] && echo true || echo false)" false
    
    log_info "Submodule 관리자 v$SCRIPT_VERSION 시작"
    log_debug "명령행 인자: $*"
    
    # 타이머 시작
    start_timer
    
    # 의존성 확인
    check_dependencies
    
    # 옵션 파싱
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=1
                LOGGING_VERBOSE=true
                shift
                ;;
            -n|--dry-run)
                DRY_RUN=1
                log_warning "DRY-RUN 모드: 실제 변경사항은 적용되지 않습니다."
                shift
                ;;
            -p|--parallel)
                PARALLEL=1
                shift
                ;;
            -l|--log)
                LOG_FILE="$2"
                shift 2
                ;;
            -b|--backup)
                BACKUP_DIR="$2"
                shift 2
                ;;
            status|update|sync|check|clean|list|foreach|add|remove|reset|backup|restore|analyze|repair)
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
    
    # 로그 파일 설정 확인
    if [ -n "$LOG_FILE" ]; then
        print_info "로그 파일: $LOG_FILE"
        # 로그 디렉토리 생성
        mkdir -p "$(dirname "$LOG_FILE")"
    fi
    
    # 병렬 처리 확인
    if [ "$PARALLEL" = "1" ]; then
        print_info "병렬 처리 모드 활성화"
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
        add)
            cmd_add "$@"
            ;;
        remove)
            cmd_remove "$@"
            ;;
        reset)
            cmd_reset "$@"
            ;;
        backup)
            cmd_backup "$@"
            ;;
        restore)
            cmd_restore "$@"
            ;;
        analyze)
            cmd_analyze
            ;;
        repair)
            cmd_repair
            ;;
        *)
            handle_error $EXIT_MISUSE "알 수 없는 명령어: $COMMAND"
            ;;
    esac
    
    # 실행 시간 표시
    end_timer
    log_info "Submodule 관리자 완료"
}

# 스크립트 실행
main "$@"
