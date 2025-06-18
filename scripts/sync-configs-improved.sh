#!/bin/bash

# Shared GitHub Configs 동기화 스크립트 (개선된 버전)
# Usage: ./sync-configs.sh [OPTIONS]

set -euo pipefail

# ==============================================================================
# 공통 라이브러리 로드
# ==============================================================================
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common-logging.sh"

# ==============================================================================
# 설정 및 변수
# ==============================================================================

# 버전 정보
readonly SCRIPT_VERSION="2.1.0"
readonly SCRIPT_NAME="$(basename "$0")"

# 기본 설정
DRY_RUN=false
VERBOSE=false
FORCE_MODE=false
BACKUP_ENABLED=true
LOG_FILE=""
CONFIG_TYPE="all"
EXCLUDE_PATTERNS=""

# 디렉토리 설정
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly SHARED_CONFIGS_DIR=".shared-configs"
readonly BACKUP_DIR=".shared-configs-backup"
readonly LOG_DIR=".shared-configs/logs"

# ==============================================================================
# 출력 함수들 (공통 라이브러리 래핑)
# ==============================================================================

print_dry_run() {
    log_warning "[DRY-RUN] $1"
}

# 공통 라이브러리 함수들을 래핑 (기존 코드 호환성)
print_status() {
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
}o pipefail

# ==============================================================================
# 공통 라이브러리 로드
# ==============================================================================
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common-logging.sh"

# ==============================================================================
# 설정 및 변수
# ==============================================================================

# 버전 정보
readonly SCRIPT_VERSION="2.1.0"
readonly SCRIPT_NAME="$(basename "$0")"

# 기본 설정
DRY_RUN=false
VERBOSE=false
FORCE_MODE=false
BACKUP_ENABLED=true
LOG_FILE=""
CONFIG_TYPE="all"
EXCLUDE_PATTERNS=""

# 디렉토리 설정
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly SHARED_CONFIGS_DIR=".shared-configs"
readonly BACKUP_DIR=".shared-configs-backup"
readonly LOG_DIR=".shared-configs/logs"

# ==============================================================================
# 로깅 및 출력 함수
# ==============================================================================

# 로그 파일 초기화
# ==============================================================================
# 도움말 및 버전 정보
# ==============================================================================

show_version() {
    echo "$SCRIPT_NAME v$SCRIPT_VERSION"
    echo "Shared GitHub Configs 동기화 도구"
}

sync_sync_show_help() {
    show_version
    echo ""
    echo "사용법: $0 [OPTIONS] [COMMAND]"
    echo ""
    echo "명령어:"
    echo "  push               로컬 변경사항을 원격 저장소에 푸시"
    echo "  pull, update       원격 저장소에서 최신 변경사항 가져오기"
    echo "  status             동기화 상태 확인"
    echo "  backup             현재 설정 백업"
    echo "  restore            백업에서 설정 복원"
    echo "  validate           설정 파일 유효성 검사"
    echo ""
    echo "옵션:"
    echo "  -d, --dry-run      실제 실행하지 않고 수행될 작업만 표시"
    echo "  -v, --verbose      상세 출력 모드"
    echo "  -f, --force        강제 실행 (충돌 무시)"
    echo "  -t, --type TYPE    동기화할 설정 타입 (github|vscode|all) [기본값: all]"
    echo "  -e, --exclude PATTERN  제외할 파일 패턴 (glob 패턴)"
    echo "  -l, --log FILE     로그 파일 경로"
    echo "  -b, --no-backup    백업 비활성화"
    echo "  -h, --help         이 도움말 표시"
    echo "  --version          버전 정보 표시"
    echo ""
    echo "예시:"
    echo "  $0 status                    # 동기화 상태 확인"
    echo "  $0 pull --dry-run            # 업데이트 미리보기"
    echo "  $0 push --type github        # GitHub 설정만 푸시"
    echo "  $0 backup --log sync.log    # 설정 백업 (로그 기록)"
    echo "  $0 validate --verbose       # 설정 검증 (상세 출력)"
}

# ==============================================================================
# 환경 및 의존성 확인
# ==============================================================================

check_dependencies() {
    log_debug "의존성 검사 시작"
    
    # 필수 명령어 확인 (공통 라이브러리 함수 사용)
    validate_command "rsync"
    validate_command "jq"
    validate_command "git"
    
    log_debug "모든 의존성 확인 완료"
}
    local required_commands=("git" "rsync")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    # 선택적 명령어 확인
    local optional_commands=("jq" "curl")
    for cmd in "${optional_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            print_warning "$cmd가 설치되어 있지 않습니다. 일부 기능이 제한될 수 있습니다."
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_error "다음 필수 명령어가 누락되었습니다: ${missing_deps[*]}"
        exit 1
    fi
}

check_environment() {
    print_debug "환경 확인 시작"
    
    # 의존성 확인
    check_dependencies
    
    # 현재 디렉토리가 Git 저장소인지 확인
    if ! git rev-parse --git-dir &> /dev/null; then
        print_error "현재 디렉토리가 Git 저장소가 아닙니다."
        exit 1
    fi
    
    # .shared-configs 디렉토리 확인
    if [[ ! -d "$SHARED_CONFIGS_DIR" ]]; then
        print_error "$SHARED_CONFIGS_DIR 디렉토리가 없습니다."
        print_error "먼저 setup-new-project.sh를 실행하여 프로젝트를 설정하세요."
        exit 1
    fi
    
    # Submodule 상태 확인
    if ! git submodule status "$SHARED_CONFIGS_DIR" &> /dev/null; then
        print_warning "$SHARED_CONFIGS_DIR가 Git submodule로 설정되지 않았습니다."
    fi
    
    print_debug "환경 확인 완료"
}

# ==============================================================================
# 백업 및 복원 함수
# ==============================================================================

create_backup() {
    if [[ "$BACKUP_ENABLED" != true ]]; then
        print_debug "백업이 비활성화되어 있습니다."
        return 0
    fi
    
    local backup_name="backup-$(date '+%Y%m%d-%H%M%S')"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    print_status "설정 백업 생성 중: $backup_path"
    
    if [[ "$DRY_RUN" == true ]]; then
        print_dry_run "백업 생성: $backup_path"
        return 0
    fi
    
    mkdir -p "$BACKUP_DIR"
    
    # 현재 설정 백업
    if [[ -d "$SHARED_CONFIGS_DIR" ]]; then
        cp -r "$SHARED_CONFIGS_DIR" "$backup_path"
        print_success "백업 생성 완료: $backup_path"
        
        # 백업 메타데이터 저장
        cat > "$backup_path/backup-info.json" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "version": "$SCRIPT_VERSION",
  "project": "$(basename "$(pwd)")",
  "git_commit": "$(cd "$SHARED_CONFIGS_DIR" && git rev-parse HEAD 2>/dev/null || echo 'unknown')"
}
EOF
    else
        print_warning "백업할 설정 디렉토리가 없습니다."
    fi
}

list_backups() {
    print_status "사용 가능한 백업 목록:"
    
    if [[ ! -d "$BACKUP_DIR" ]]; then
        print_warning "백업 디렉토리가 없습니다."
        return 0
    fi
    
    local count=0
    for backup in "$BACKUP_DIR"/backup-*; do
        if [[ -d "$backup" ]]; then
            local backup_name
            backup_name=$(basename "$backup")
            local backup_info="$backup/backup-info.json"
            
            if [[ -f "$backup_info" ]] && command -v jq >/dev/null 2>&1; then
                local timestamp
                local commit
                timestamp=$(jq -r '.timestamp' "$backup_info" 2>/dev/null || echo "unknown")
                commit=$(jq -r '.git_commit' "$backup_info" 2>/dev/null || echo "unknown")
                echo "  $backup_name (시간: $timestamp, 커밋: ${commit:0:8})"
            else
                echo "  $backup_name"
            fi
            ((count++))
        fi
    done
    
    if [[ $count -eq 0 ]]; then
        print_warning "백업이 없습니다."
    else
        print_success "총 $count개의 백업을 찾았습니다."
    fi
}

restore_backup() {
    local backup_name="$1"
    
    if [[ -z "$backup_name" ]]; then
        print_error "복원할 백업 이름을 지정해주세요."
        list_backups
        return 1
    fi
    
    local backup_path="$BACKUP_DIR/$backup_name"
    
    if [[ ! -d "$backup_path" ]]; then
        print_error "백업을 찾을 수 없습니다: $backup_name"
        list_backups
        return 1
    fi
    
    print_status "백업에서 설정 복원 중: $backup_name"
    
    if [[ "$DRY_RUN" == true ]]; then
        print_dry_run "백업 복원: $backup_path -> $SHARED_CONFIGS_DIR"
        return 0
    fi
    
    # 현재 설정 백업 (복원 전 안전장치)
    if [[ -d "$SHARED_CONFIGS_DIR" ]]; then
        create_backup
    fi
    
    # 백업 복원
    rm -rf "$SHARED_CONFIGS_DIR"
    cp -r "$backup_path" "$SHARED_CONFIGS_DIR"
    
    # 백업 메타데이터 제거
    rm -f "$SHARED_CONFIGS_DIR/backup-info.json"
    
    print_success "백업 복원 완료: $backup_name"
}

# ==============================================================================
# 설정 검증 함수
# ==============================================================================

validate_config_files() {
    print_status "설정 파일 유효성 검사 중..."
    
    local error_count=0
    local warning_count=0
    
    # JSON 파일 검증
    while IFS= read -r -d '' json_file; do
        print_debug "JSON 검증: $json_file"
        if ! python3 -m json.tool "$json_file" >/dev/null 2>&1; then
            print_error "JSON 구문 오류: $json_file"
            ((error_count++))
        fi
    done < <(find "$SHARED_CONFIGS_DIR" -name "*.json" -print0 2>/dev/null)
    
    # YAML 파일 검증 (yq가 있는 경우)
    if command -v yq >/dev/null 2>&1; then
        while IFS= read -r -d '' yaml_file; do
            print_debug "YAML 검증: $yaml_file"
            if ! yq eval . "$yaml_file" >/dev/null 2>&1; then
                print_error "YAML 구문 오류: $yaml_file"
                ((error_count++))
            fi
        done < <(find "$SHARED_CONFIGS_DIR" -name "*.yml" -o -name "*.yaml" -print0 2>/dev/null)
    fi
    
    # 실행 권한 확인
    while IFS= read -r -d '' script_file; do
        if [[ ! -x "$script_file" ]]; then
            print_warning "실행 권한 없음: $script_file"
            ((warning_count++))
        fi
    done < <(find "$SHARED_CONFIGS_DIR" -name "*.sh" -print0 2>/dev/null)
    
    # 결과 출력
    if [[ $error_count -eq 0 && $warning_count -eq 0 ]]; then
        print_success "모든 설정 파일이 유효합니다."
    else
        if [[ $error_count -gt 0 ]]; then
            print_error "총 $error_count개의 오류가 발견되었습니다."
        fi
        if [[ $warning_count -gt 0 ]]; then
            print_warning "총 $warning_count개의 경고가 발견되었습니다."
        fi
    fi
    
    return $error_count
}

# ==============================================================================
# Git 작업 함수들
# ==============================================================================

get_git_status() {
    local target_dir="${1:-$SHARED_CONFIGS_DIR}"
    
    if [[ ! -d "$target_dir/.git" ]]; then
        return 1
    fi
    
    cd "$target_dir"
    
    # 작업 디렉토리 상태
    local has_changes=false
    if [[ -n "$(git status --porcelain)" ]]; then
        has_changes=true
    fi
    
    # 원격과의 차이
    git fetch origin &>/dev/null || true
    
    local local_commit
    local remote_commit
    local base_commit
    
    local_commit=$(git rev-parse HEAD 2>/dev/null || echo "")
    remote_commit=$(git rev-parse origin/main 2>/dev/null || echo "")
    base_commit=$(git merge-base HEAD origin/main 2>/dev/null || echo "")
    
    # 상태 분석
    local sync_status="unknown"
    if [[ "$local_commit" == "$remote_commit" ]]; then
        sync_status="synced"
    elif [[ "$local_commit" == "$base_commit" ]]; then
        sync_status="behind"
    elif [[ "$remote_commit" == "$base_commit" ]]; then
        sync_status="ahead"
    else
        sync_status="diverged"
    fi
    
    # 결과 출력 (JSON 형태)
    cat << EOF
{
  "has_changes": $has_changes,
  "sync_status": "$sync_status",
  "local_commit": "$local_commit",
  "remote_commit": "$remote_commit",
  "base_commit": "$base_commit"
}
EOF
    
    cd - >/dev/null
}

# ==============================================================================
# 메인 동기화 함수들
# ==============================================================================

show_status() {
    print_status "🔍 동기화 상태 확인 중..."
    echo ""
    
    # 프로젝트 기본 정보
    print_status "📁 프로젝트 정보:"
    echo "  경로: $(pwd)"
    echo "  이름: $(basename "$(pwd)")"
    echo ""
    
    # 메인 프로젝트 상태
    print_status "📋 메인 프로젝트 상태:"
    if [[ -n "$(git status --porcelain)" ]]; then
        echo "  ❌ 커밋되지 않은 변경사항이 있습니다."
        if [[ "$VERBOSE" == true ]]; then
            git status --short | head -10 | sed 's/^/    /'
        fi
    else
        echo "  ✅ 깨끗한 상태입니다."
    fi
    echo ""
    
    # Shared configs 상태
    print_status "📦 Shared Configs 상태:"
    if [[ ! -d "$SHARED_CONFIGS_DIR" ]]; then
        echo "  ❌ Shared configs 디렉토리가 없습니다."
        return 1
    fi
    
    local status_json
    status_json=$(get_git_status "$SHARED_CONFIGS_DIR")
    
    if command -v jq >/dev/null 2>&1; then
        local has_changes
        local sync_status
        local local_commit
        local remote_commit
        
        has_changes=$(echo "$status_json" | jq -r '.has_changes')
        sync_status=$(echo "$status_json" | jq -r '.sync_status')
        local_commit=$(echo "$status_json" | jq -r '.local_commit')
        remote_commit=$(echo "$status_json" | jq -r '.remote_commit')
        
        # 로컬 변경사항
        if [[ "$has_changes" == "true" ]]; then
            echo "  ❌ 커밋되지 않은 변경사항이 있습니다."
            if [[ "$VERBOSE" == true ]]; then
                cd "$SHARED_CONFIGS_DIR"
                git status --short | head -10 | sed 's/^/    /'
                cd - >/dev/null
            fi
        else
            echo "  ✅ 로컬 변경사항 없음"
        fi
        
        # 동기화 상태
        case "$sync_status" in
            "synced")
                echo "  ✅ 원격 저장소와 동기화됨"
                ;;
            "behind")
                echo "  ⬆️  원격에 새로운 커밋이 있습니다. (업데이트 필요)"
                ;;
            "ahead")
                echo "  ⬇️  로컬에 새로운 커밋이 있습니다. (푸시 필요)"
                ;;
            "diverged")
                echo "  ⚠️  로컬과 원격이 분기되었습니다. (수동 해결 필요)"
                ;;
            *)
                echo "  ❓ 동기화 상태를 확인할 수 없습니다."
                ;;
        esac
        
        # 커밋 정보
        if [[ "$VERBOSE" == true ]]; then
            echo "  로컬 커밋: ${local_commit:0:8}"
            echo "  원격 커밋: ${remote_commit:0:8}"
        fi
    else
        echo "  ⚠️  jq가 설치되지 않아 상세 상태를 확인할 수 없습니다."
    fi
    
    echo ""
}

sync_pull() {
    print_status "⬇️  원격 저장소에서 최신 변경사항 가져오는 중..."
    
    # 백업 생성
    create_backup
    
    cd "$SHARED_CONFIGS_DIR"
    
    # 로컬 변경사항 확인
    if [[ -n "$(git status --porcelain)" ]] && [[ "$FORCE_MODE" != true ]]; then
        print_error "커밋되지 않은 변경사항이 있습니다."
        print_error "먼저 변경사항을 커밋하거나 --force 옵션을 사용하세요."
        if [[ "$VERBOSE" == true ]]; then
            git status --short
        fi
        cd - >/dev/null
        return 1
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        print_dry_run "git fetch origin"
        print_dry_run "git rebase origin/main"
        cd - >/dev/null
        return 0
    fi
    
    # 강제 모드에서 로컬 변경사항 처리
    if [[ -n "$(git status --porcelain)" ]] && [[ "$FORCE_MODE" == true ]]; then
        print_warning "로컬 변경사항을 stash에 백업합니다."
        git stash push -m "Auto-backup before force update $(date '+%Y-%m-%d %H:%M:%S')"
    fi
    
    # 원격 변경사항 가져오기
    print_debug "Fetching remote changes..."
    git fetch origin
    
    # 현재 브랜치 확인 및 main으로 전환
    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD)
    if [[ "$current_branch" != "main" ]]; then
        print_warning "현재 브랜치가 main이 아닙니다: $current_branch"
        git checkout main
    fi
    
    # 업데이트 실행
    if [[ "$FORCE_MODE" == true ]]; then
        print_debug "Force reset to origin/main"
        git reset --hard origin/main
        print_warning "강제 업데이트가 완료되었습니다."
    else
        print_debug "Rebasing on origin/main"
        git rebase origin/main
    fi
    
    print_success "최신 변경사항 가져오기 완료"
    
    # 부모 프로젝트에서 submodule 업데이트
    cd - >/dev/null
    if [[ "$DRY_RUN" != true ]]; then
        git submodule update --init --recursive
        print_success "Submodule 업데이트 완료"
    else
        print_dry_run "git submodule update --init --recursive"
    fi
}

sync_push() {
    print_status "⬆️  로컬 변경사항을 원격 저장소에 푸시 중..."
    
    cd "$SHARED_CONFIGS_DIR"
    
    # 변경사항 확인
    if [[ -z "$(git status --porcelain)" ]]; then
        print_warning "푸시할 변경사항이 없습니다."
        cd - >/dev/null
        return 0
    fi
    
    # 변경사항 표시
    print_status "다음 변경사항을 푸시합니다:"
    git status --short
    echo ""
    
    if [[ "$DRY_RUN" == true ]]; then
        print_dry_run "git add ."
        print_dry_run "git commit -m '[커밋 메시지]'"
        print_dry_run "git push origin main"
        cd - >/dev/null
        return 0
    fi
    
    # 커밋 메시지 생성
    local project_name
    project_name=$(basename "$(dirname "$PWD")")
    local default_msg="Update shared configs from $project_name"
    local commit_msg
    
    if [[ -t 0 ]]; then  # 대화형 터미널인 경우
        echo "커밋 메시지를 입력하세요 (Enter: 기본 메시지 사용):"
        echo "기본값: $default_msg"
        read -r commit_msg
    fi
    
    if [[ -z "$commit_msg" ]]; then
        commit_msg="$default_msg"
    fi
    
    # 커밋 및 푸시
    git add .
    git commit -m "$commit_msg"
    git push origin main
    
    print_success "푸시 완료: $commit_msg"
    
    # 부모 프로젝트에서 submodule 업데이트
    cd - >/dev/null
    git add "$SHARED_CONFIGS_DIR"
    git commit -m "Update shared configs submodule" || true
    
    print_success "Submodule 참조 업데이트 완료"
}

# ==============================================================================
# 파라미터 파싱
# ==============================================================================

parse_args() {
    local command=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            push)
                command="push"
                shift
                ;;
            pull|update)
                command="pull"
                shift
                ;;
            status)
                command="status"
                shift
                ;;
            backup)
                command="backup"
                shift
                ;;
            restore)
                command="restore"
                if [[ -n "${2:-}" && ! "$2" =~ ^- ]]; then
                    RESTORE_BACKUP="$2"
                    shift
                fi
                shift
                ;;
            validate)
                command="validate"
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -f|--force)
                FORCE_MODE=true
                shift
                ;;
            -t|--type)
                if [[ -n "${2:-}" ]]; then
                    CONFIG_TYPE="$2"
                    shift 2
                else
                    print_error "--type 옵션에 값이 필요합니다."
                    exit 1
                fi
                ;;
            -e|--exclude)
                if [[ -n "${2:-}" ]]; then
                    EXCLUDE_PATTERNS="$2"
                    shift 2
                else
                    print_error "--exclude 옵션에 값이 필요합니다."
                    exit 1
                fi
                ;;
            -l|--log)
                if [[ -n "${2:-}" ]]; then
                    LOG_FILE="$2"
                    shift 2
                else
                    print_error "--log 옵션에 값이 필요합니다."
                    exit 1
                fi
                ;;
            -b|--no-backup)
                BACKUP_ENABLED=false
                shift
                ;;
            -h|--help)
                sync_sync_show_help
                exit 0
                ;;
            --version)
                show_version
                exit 0
                ;;
            *)
                print_error "알 수 없는 옵션: $1"
                sync_sync_show_help
                exit 1
                ;;
        esac
    done
    
    echo "$command"
}

# ==============================================================================
# 메인 함수
# ==============================================================================

main() {
    # 기본 로그 파일 설정
    if [[ -z "$LOG_FILE" ]]; then
        LOG_FILE="$LOG_DIR/sync-$(date '+%Y%m%d').log"
    fi
    
    # 공통 라이브러리 로깅 초기화
    init_logging "$SCRIPT_NAME" "$LOG_FILE" "$VERBOSE" false
    
    log_info "스크립트 시작: $SCRIPT_NAME v$SCRIPT_VERSION"
    log_debug "명령행 인자: $*"
    
    echo "🔄 Shared GitHub Configs 동기화 도구 v$SCRIPT_VERSION"
    echo "=============================================="
    echo ""
    
    # 타이머 시작
    start_timer
    
    # 인자 파싱
    local command
    command=$(parse_args "$@")
    
    # 인자가 없으면 도움말 표시
    if [[ -z "$command" ]]; then
        sync_sync_show_help
        exit 0
    fi
    
    # 환경 확인
    check_environment
    
    # Dry-run 모드 표시
    if [[ "$DRY_RUN" == true ]]; then
        log_warning "DRY-RUN 모드: 실제로 변경사항을 적용하지 않습니다."
        echo ""
    fi
    
    # 명령어 실행
    case "$command" in
        status)
            show_status
            ;;
        pull)
            sync_pull
            ;;
        push)
            sync_push
            ;;
        backup)
            create_backup
            ;;
        restore)
            restore_backup "${RESTORE_BACKUP:-}"
            ;;
        validate)
            validate_config_files
            ;;
        *)
            handle_error $EXIT_MISUSE "알 수 없는 명령어: $command"
            ;;
    esac
    
    # 실행 시간 표시
    end_timer
    log_info "스크립트 완료"
}

# 스크립트 실행
main "$@"
