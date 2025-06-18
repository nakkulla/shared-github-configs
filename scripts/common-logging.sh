#!/bin/bash

# 공통 로깅 및 오류 처리 라이브러리
# 모든 스크립트에서 일관된 로깅 및 오류 처리를 위한 공통 함수들
# 
# 사용법:
#   source "$(dirname "$0")/common-logging.sh"
#   init_logging "script-name" "/path/to/log/file"
#   log_info "정보 메시지"
#   log_error "오류 메시지"
#   handle_error "오류 코드" "오류 메시지"
#
# 작성자: GitHub Copilot
# 버전: 1.0.0

# 기본 설정이 되어있지 않은 경우에만 설정
if [[ -z "${COMMON_LOGGING_LOADED:-}" ]]; then
    readonly COMMON_LOGGING_LOADED=true
    readonly COMMON_LOGGING_VERSION="1.0.0"

    # ==============================================================================
    # 색상 및 스타일 상수
    # ==============================================================================
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    readonly PURPLE='\033[0;35m'
    readonly CYAN='\033[0;36m'
    readonly WHITE='\033[1;37m'
    readonly BOLD='\033[1m'
    readonly DIM='\033[2m'
    readonly NC='\033[0m'

    # ==============================================================================
    # 로깅 설정 변수
    # ==============================================================================
    LOGGING_SCRIPT_NAME=""
    LOGGING_LOG_FILE=""
    LOGGING_VERBOSE=false
    LOGGING_QUIET=false
    LOGGING_TIMESTAMP_FORMAT='+%Y-%m-%d %H:%M:%S'
    LOGGING_MAX_LOG_SIZE=$((10 * 1024 * 1024))  # 10MB
    LOGGING_MAX_LOG_FILES=5

    # 표준 종료 코드
    readonly EXIT_SUCCESS=0
    readonly EXIT_GENERAL_ERROR=1
    readonly EXIT_MISUSE=2
    readonly EXIT_CANNOT_EXECUTE=126
    readonly EXIT_COMMAND_NOT_FOUND=127
    readonly EXIT_INVALID_EXIT_ARGUMENT=128
    readonly EXIT_SIGNAL_BASE=128

    # 커스텀 종료 코드
    readonly EXIT_CONFIG_ERROR=10
    readonly EXIT_DEPENDENCY_ERROR=11
    readonly EXIT_NETWORK_ERROR=12
    readonly EXIT_PERMISSION_ERROR=13
    readonly EXIT_DISK_SPACE_ERROR=14
    readonly EXIT_VALIDATION_ERROR=15
    readonly EXIT_BACKUP_ERROR=16
    readonly EXIT_RESTORE_ERROR=17
    readonly EXIT_SYNC_ERROR=18
    readonly EXIT_SUBMODULE_ERROR=19

    # ==============================================================================
    # 로깅 초기화 함수
    # ==============================================================================
    init_logging() {
        local script_name="${1:-$(basename "$0")}"
        local log_file="${2:-}"
        local verbose="${3:-false}"
        local quiet="${4:-false}"

        LOGGING_SCRIPT_NAME="$script_name"
        LOGGING_LOG_FILE="$log_file"
        LOGGING_VERBOSE="$verbose"
        LOGGING_QUIET="$quiet"

        # 로그 파일 설정
        if [[ -n "$LOGGING_LOG_FILE" ]]; then
            local log_dir
            log_dir="$(dirname "$LOGGING_LOG_FILE")"
            
            # 로그 디렉토리 생성
            if ! mkdir -p "$log_dir" 2>/dev/null; then
                echo -e "${RED}[ERROR]${NC} 로그 디렉토리 생성 실패: $log_dir" >&2
                return $EXIT_PERMISSION_ERROR
            fi

            # 로그 파일 로테이션 확인
            rotate_log_if_needed

            # 로그 파일 초기화
            {
                echo "# =============================================================================="
                echo "# 로그 시작: $(date "$LOGGING_TIMESTAMP_FORMAT")"
                echo "# 스크립트: $LOGGING_SCRIPT_NAME"
                echo "# PID: $$"
                echo "# PWD: $(pwd)"
                echo "# USER: ${USER:-$(whoami)}"
                echo "# =============================================================================="
            } >> "$LOGGING_LOG_FILE"

            log_debug "로깅 시스템 초기화됨 - 로그 파일: $LOGGING_LOG_FILE"
        fi

        # 시그널 핸들러 설정
        trap 'handle_signal INT' INT
        trap 'handle_signal TERM' TERM
        trap 'handle_signal EXIT' EXIT
    }

    # ==============================================================================
    # 로그 로테이션 함수
    # ==============================================================================
    rotate_log_if_needed() {
        if [[ ! -f "$LOGGING_LOG_FILE" ]]; then
            return 0
        fi

        local file_size
        file_size=$(stat -f%z "$LOGGING_LOG_FILE" 2>/dev/null || stat -c%s "$LOGGING_LOG_FILE" 2>/dev/null || echo 0)

        if (( file_size > LOGGING_MAX_LOG_SIZE )); then
            log_info "로그 파일 크기 초과 (${file_size} bytes), 로테이션 수행"
            
            # 기존 로그 파일들 이동
            for ((i=LOGGING_MAX_LOG_FILES-1; i>=1; i--)); do
                local old_file="${LOGGING_LOG_FILE}.${i}"
                local new_file="${LOGGING_LOG_FILE}.$((i+1))"
                
                if [[ -f "$old_file" ]]; then
                    mv "$old_file" "$new_file"
                fi
            done

            # 현재 로그 파일을 .1로 이동
            mv "$LOGGING_LOG_FILE" "${LOGGING_LOG_FILE}.1"
            
            # 가장 오래된 로그 파일 삭제
            local oldest_file="${LOGGING_LOG_FILE}.$((LOGGING_MAX_LOG_FILES+1))"
            [[ -f "$oldest_file" ]] && rm -f "$oldest_file"
        fi
    }

    # ==============================================================================
    # 로깅 함수들
    # ==============================================================================
    log_with_level() {
        local level="$1"
        local message="$2"
        local color="$3"
        local timestamp
        timestamp=$(date "$LOGGING_TIMESTAMP_FORMAT")

        # 로그 파일에 기록
        if [[ -n "$LOGGING_LOG_FILE" ]]; then
            echo "[$timestamp] [$LOGGING_SCRIPT_NAME] [$level] $message" >> "$LOGGING_LOG_FILE"
        fi

        # 콘솔 출력 (quiet 모드가 아닌 경우)
        if [[ "$LOGGING_QUIET" != true ]]; then
            echo -e "${color}[${level}]${NC} $message" >&2
        fi
    }

    log_debug() {
        if [[ "$LOGGING_VERBOSE" == true ]]; then
            log_with_level "DEBUG" "$1" "$PURPLE"
        elif [[ -n "$LOGGING_LOG_FILE" ]]; then
            # verbose가 아니어도 로그 파일에는 기록
            local timestamp
            timestamp=$(date "$LOGGING_TIMESTAMP_FORMAT")
            echo "[$timestamp] [$LOGGING_SCRIPT_NAME] [DEBUG] $1" >> "$LOGGING_LOG_FILE"
        fi
    }

    log_info() {
        log_with_level "INFO" "$1" "$BLUE"
    }

    log_success() {
        log_with_level "SUCCESS" "$1" "$GREEN"
    }

    log_warning() {
        log_with_level "WARNING" "$1" "$YELLOW"
    }

    log_error() {
        log_with_level "ERROR" "$1" "$RED"
    }

    log_critical() {
        log_with_level "CRITICAL" "$1" "${RED}${BOLD}"
    }

    # ==============================================================================
    # 오류 처리 함수들
    # ==============================================================================
    handle_error() {
        local exit_code="${1:-$EXIT_GENERAL_ERROR}"
        local error_message="${2:-알 수 없는 오류가 발생했습니다}"
        local line_number="${3:-${LINENO}}"
        local function_name="${4:-${FUNCNAME[1]:-main}}"

        log_error "오류 발생 - 함수: $function_name, 라인: $line_number"
        log_error "오류 메시지: $error_message"
        log_error "종료 코드: $exit_code"

        # 스택 트레이스 출력 (verbose 모드)
        if [[ "$LOGGING_VERBOSE" == true ]]; then
            log_debug "스택 트레이스:"
            local i=1
            while [[ ${FUNCNAME[$i]:-} ]]; do
                log_debug "  $i: ${FUNCNAME[$i]} (${BASH_SOURCE[$i]:-}:${BASH_LINENO[$((i-1))]})"
                ((i++))
            done
        fi

        exit "$exit_code"
    }

    # 시그널 핸들러
    handle_signal() {
        local signal="$1"
        case "$signal" in
            INT)
                log_warning "인터럽트 시그널 받음 (Ctrl+C)"
                exit $((EXIT_SIGNAL_BASE + 2))
                ;;
            TERM)
                log_warning "종료 시그널 받음"
                exit $((EXIT_SIGNAL_BASE + 15))
                ;;
            EXIT)
                local exit_code=$?
                if (( exit_code != 0 )); then
                    log_error "스크립트가 오류 코드 $exit_code 로 종료됨"
                else
                    log_debug "스크립트가 정상 종료됨"
                fi
                ;;
        esac
    }

    # ==============================================================================
    # 유틸리티 함수들
    # ==============================================================================
    validate_command() {
        local command="$1"
        local package="${2:-$command}"
        
        if ! command -v "$command" &> /dev/null; then
            log_error "필수 명령어 '$command'를 찾을 수 없습니다"
            log_info "설치 방법: brew install $package (macOS) 또는 적절한 패키지 매니저 사용"
            handle_error $EXIT_DEPENDENCY_ERROR "필수 의존성 누락: $command"
        fi
    }

    validate_file() {
        local file_path="$1"
        local required="${2:-true}"
        
        if [[ ! -f "$file_path" ]]; then
            if [[ "$required" == true ]]; then
                handle_error $EXIT_CONFIG_ERROR "필수 파일을 찾을 수 없습니다: $file_path"
            else
                log_warning "파일을 찾을 수 없습니다: $file_path"
                return 1
            fi
        fi
        return 0
    }

    validate_directory() {
        local dir_path="$1"
        local required="${2:-true}"
        
        if [[ ! -d "$dir_path" ]]; then
            if [[ "$required" == true ]]; then
                handle_error $EXIT_CONFIG_ERROR "필수 디렉토리를 찾을 수 없습니다: $dir_path"
            else
                log_warning "디렉토리를 찾을 수 없습니다: $dir_path"
                return 1
            fi
        fi
        return 0
    }

    check_disk_space() {
        local required_space_mb="${1:-100}"
        local target_path="${2:-.}"
        
        local available_space
        available_space=$(df -m "$target_path" | tail -1 | awk '{print $4}')
        
        if (( available_space < required_space_mb )); then
            handle_error $EXIT_DISK_SPACE_ERROR "디스크 공간이 부족합니다. 필요: ${required_space_mb}MB, 사용가능: ${available_space}MB"
        fi
    }

    # 실행 시간 측정
    start_timer() {
        TIMER_START=$(date +%s)
    }

    end_timer() {
        local timer_end
        timer_end=$(date +%s)
        local duration=$((timer_end - ${TIMER_START:-$timer_end}))
        
        if (( duration > 60 )); then
            log_info "실행 시간: $((duration / 60))분 $((duration % 60))초"
        else
            log_info "실행 시간: ${duration}초"
        fi
    }

    # 진행률 표시
    show_progress() {
        local current="$1"
        local total="$2"
        local message="${3:-진행 중}"
        
        local percentage=$((current * 100 / total))
        local filled=$((percentage / 2))
        local empty=$((50 - filled))
        
        local bar=""
        for ((i=0; i<filled; i++)); do bar+="█"; done
        for ((i=0; i<empty; i++)); do bar+="░"; done
        
        printf "\r${CYAN}[%s]${NC} %s (%d/%d) %d%%" "$bar" "$message" "$current" "$total" "$percentage"
        
        if (( current == total )); then
            echo  # 새 줄 추가
            log_info "$message 완료 ($current/$total)"
        fi
    }

    # JSON 로그 형식으로 구조화된 로그 출력
    log_json() {
        local level="$1"
        local message="$2"
        local metadata="${3:-{}}"
        
        if [[ -n "$LOGGING_LOG_FILE" ]]; then
            local timestamp
            timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
            
            local json_log
            json_log=$(cat <<EOF
{
  "timestamp": "$timestamp",
  "level": "$level",
  "script": "$LOGGING_SCRIPT_NAME",
  "pid": $$,
  "message": "$message",
  "metadata": $metadata
}
EOF
)
            echo "$json_log" >> "${LOGGING_LOG_FILE}.json"
        fi
    }

    # ==============================================================================
    # 초기화 완료 메시지
    # ==============================================================================
    log_debug "공통 로깅 라이브러리 v$COMMON_LOGGING_VERSION 로드됨"

fi # COMMON_LOGGING_LOADED 체크 종료
