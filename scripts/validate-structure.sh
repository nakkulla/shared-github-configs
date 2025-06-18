#!/bin/bash

# 공유 GitHub 설정 저장소 구조 검증 스크립트
# 모든 필수 파일과 폴더가 올바르게 구성되었는지 확인

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
    echo -e "${CYAN}=== $1 ===${NC}"
}

# 카운터 변수
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

# 함수: 검증 결과 기록
record_check() {
    local status=$1
    local message=$2
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    case $status in
        "PASS")
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
            print_success "$message"
            ;;
        "FAIL")
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
            print_error "$message"
            ;;
        "WARN")
            WARNING_CHECKS=$((WARNING_CHECKS + 1))
            print_warning "$message"
            ;;
    esac
}

# 함수: 파일 존재 확인
check_file_exists() {
    local file=$1
    local description=$2
    
    if [ -f "$file" ]; then
        record_check "PASS" "$description: $file"
        return 0
    else
        record_check "FAIL" "$description: $file (파일 없음)"
        return 1
    fi
}

# 함수: 디렉토리 존재 확인
check_directory_exists() {
    local dir=$1
    local description=$2
    
    if [ -d "$dir" ]; then
        record_check "PASS" "$description: $dir"
        return 0
    else
        record_check "FAIL" "$description: $dir (디렉토리 없음)"
        return 1
    fi
}

# 함수: 파일 내용 확인
check_file_content() {
    local file=$1
    local pattern=$2
    local description=$3
    
    if [ ! -f "$file" ]; then
        record_check "FAIL" "$description: $file (파일 없음)"
        return 1
    fi
    
    if grep -q "$pattern" "$file" 2>/dev/null; then
        record_check "PASS" "$description: 필수 내용 포함"
        return 0
    else
        record_check "WARN" "$description: 패턴 '$pattern' 찾을 수 없음"
        return 1
    fi
}

# 함수: 실행 권한 확인
check_executable() {
    local file=$1
    local description=$2
    
    if [ ! -f "$file" ]; then
        record_check "FAIL" "$description: $file (파일 없음)"
        return 1
    fi
    
    if [ -x "$file" ]; then
        record_check "PASS" "$description: 실행 권한 OK"
        return 0
    else
        record_check "WARN" "$description: 실행 권한 없음"
        return 1
    fi
}

# 메인 검증 함수
main_validation() {
    echo "🔍 Shared GitHub Configs 저장소 구조 검증"
    echo "=============================================="
    echo ""
    
    # 1. 기본 파일 확인
    print_section "기본 파일 확인"
    check_file_exists "README.md" "README 파일"
    check_file_exists "LICENSE" "라이센스 파일"
    check_file_exists ".gitignore" "Git ignore 파일"
    check_file_exists ".gitmodules.template" "Git submodule 템플릿"
    
    # README 내용 확인
    check_file_content "README.md" "Shared GitHub Configs" "README 제목"
    check_file_content "README.md" "submodule" "Submodule 관련 내용"
    check_file_content "README.md" "scripts/" "스크립트 관련 내용"
    
    echo ""
    
    # 2. GitHub 템플릿 확인
    print_section "GitHub 템플릿 확인"
    check_directory_exists "github-templates" "GitHub 템플릿 디렉토리"
    check_directory_exists "github-templates/workflows" "GitHub Actions 워크플로우"
    check_directory_exists "github-templates/ISSUE_TEMPLATE" "이슈 템플릿"
    check_directory_exists "github-templates/PULL_REQUEST_TEMPLATE" "PR 템플릿"
    
    check_file_exists "github-templates/CODEOWNERS" "코드 소유자 파일"
    check_file_exists "github-templates/workflows/ci-basic.yml" "기본 CI 워크플로우"
    check_file_exists "github-templates/ISSUE_TEMPLATE/bug_report.yml" "버그 리포트 템플릿"
    check_file_exists "github-templates/ISSUE_TEMPLATE/feature_request.yml" "기능 요청 템플릿"
    check_file_exists "github-templates/PULL_REQUEST_TEMPLATE/pull_request_template.md" "PR 템플릿"
    
    echo ""
    
    # 3. VSCode 템플릿 확인
    print_section "VSCode 템플릿 확인"
    check_directory_exists "vscode-templates" "VSCode 템플릿 디렉토리"
    check_directory_exists "vscode-templates/snippets" "VSCode 스니펫"
    
    check_file_exists "vscode-templates/settings.json" "VSCode 설정"
    check_file_exists "vscode-templates/extensions.json" "VSCode 확장 프로그램"
    check_file_exists "vscode-templates/tasks.json" "VSCode 작업"
    check_file_exists "vscode-templates/launch.json" "VSCode 디버그 설정"
    check_file_exists "vscode-templates/snippets/korean-dev.code-snippets" "한국어 개발 스니펫"
    
    # JSON 파일 유효성 검사
    for json_file in "vscode-templates/settings.json" "vscode-templates/extensions.json" "vscode-templates/tasks.json" "vscode-templates/launch.json"; do
        if [ -f "$json_file" ]; then
            if python3 -m json.tool "$json_file" >/dev/null 2>&1; then
                record_check "PASS" "JSON 유효성: $json_file"
            else
                record_check "FAIL" "JSON 유효성: $json_file (잘못된 JSON)"
            fi
        fi
    done
    
    echo ""
    
    # 4. Instructions 확인
    print_section "Instructions 확인"
    check_directory_exists "instructions" "Instructions 디렉토리"
    
    check_file_exists "instructions/taskmaster.instructions.md" "Taskmaster 가이드"
    check_file_exists "instructions/github-taskmaster.instructions.md" "GitHub-Taskmaster 가이드"
    check_file_exists "instructions/ntfy-notification.instructions.md" "알림 가이드"
    check_file_exists "instructions/instruction-formatting.instructions.md" "Instruction 포맷 가이드"
    
    echo ""
    
    # 5. 스크립트 확인
    print_section "스크립트 확인"
    check_directory_exists "scripts" "스크립트 디렉토리"
    
    check_file_exists "scripts/setup-new-project.sh" "새 프로젝트 설정 스크립트"
    check_file_exists "scripts/sync-configs.sh" "설정 동기화 스크립트"
    check_file_exists "scripts/submodule-manager.sh" "Submodule 관리 스크립트"
    
    # 실행 권한 확인
    check_executable "scripts/setup-new-project.sh" "setup-new-project.sh"
    check_executable "scripts/sync-configs.sh" "sync-configs.sh"
    check_executable "scripts/submodule-manager.sh" "submodule-manager.sh"
    
    # 스크립트 구문 확인
    for script in scripts/*.sh; do
        if [ -f "$script" ]; then
            if bash -n "$script" 2>/dev/null; then
                record_check "PASS" "구문 확인: $(basename $script)"
            else
                record_check "FAIL" "구문 확인: $(basename $script) (구문 오류)"
            fi
        fi
    done
    
    echo ""
    
    # 6. 문서 확인
    print_section "문서 확인"
    check_directory_exists "docs" "문서 디렉토리"
    check_file_exists "docs/git-submodule-guide.md" "Git Submodule 가이드"
    
    echo ""
    
    # 7. Git 설정 확인
    print_section "Git 설정 확인"
    
    if [ -d ".git" ]; then
        record_check "PASS" "Git 저장소 초기화"
        
        # 리모트 확인
        if git remote get-url origin >/dev/null 2>&1; then
            remote_url=$(git remote get-url origin)
            record_check "PASS" "Git 리모트 설정: $remote_url"
        else
            record_check "WARN" "Git 리모트가 설정되지 않았습니다"
        fi
        
        # 커밋 확인
        if git log --oneline -1 >/dev/null 2>&1; then
            last_commit=$(git log --oneline -1)
            record_check "PASS" "최근 커밋: $last_commit"
        else
            record_check "WARN" "커밋이 없습니다"
        fi
        
    else
        record_check "FAIL" "Git 저장소가 초기화되지 않았습니다"
    fi
    
    echo ""
}

# 함수: 최종 결과 출력
print_summary() {
    print_section "검증 결과 요약"
    
    echo "총 검사 항목: $TOTAL_CHECKS"
    echo -e "통과: ${GREEN}$PASSED_CHECKS${NC}"
    echo -e "경고: ${YELLOW}$WARNING_CHECKS${NC}"
    echo -e "실패: ${RED}$FAILED_CHECKS${NC}"
    
    echo ""
    
    if [ $FAILED_CHECKS -eq 0 ]; then
        if [ $WARNING_CHECKS -eq 0 ]; then
            print_success "🎉 모든 검증을 완벽하게 통과했습니다!"
            echo "저장소가 프로덕션 사용 준비가 완료되었습니다."
        else
            print_success "✅ 주요 검증을 통과했습니다. (경고 $WARNING_CHECKS개)"
            echo "경고 사항을 검토한 후 사용하시기 바랍니다."
        fi
        return 0
    else
        print_error "❌ $FAILED_CHECKS개의 중요한 문제가 발견되었습니다."
        echo "문제를 해결한 후 다시 검증하시기 바랍니다."
        return 1
    fi
}

# 함수: 문제 해결 제안
suggest_fixes() {
    echo ""
    print_section "문제 해결 제안"
    
    if [ $FAILED_CHECKS -gt 0 ]; then
        echo "다음 명령어로 일부 문제를 해결할 수 있습니다:"
        echo ""
        echo "1. 실행 권한 부여:"
        echo "   chmod +x scripts/*.sh"
        echo ""
        echo "2. 누락된 파일 생성:"
        echo "   touch 누락된파일명"
        echo ""
        echo "3. Git 저장소 초기화 (필요한 경우):"
        echo "   git init"
        echo "   git add ."
        echo "   git commit -m 'Initial commit'"
        echo ""
    fi
    
    if [ $WARNING_CHECKS -gt 0 ]; then
        echo "경고 사항들은 선택사항이지만, 완성도를 위해 해결하는 것을 권장합니다."
    fi
}

# 메인 함수
main() {
    # 현재 디렉토리가 올바른지 확인
    if [ ! -f "README.md" ] || [ ! -d "github-templates" ]; then
        print_error "현재 디렉토리가 shared-github-configs 저장소가 아닙니다."
        print_info "shared-github-configs 디렉토리에서 스크립트를 실행하세요."
        exit 1
    fi
    
    # 검증 실행
    main_validation
    
    # 결과 출력
    print_summary
    validation_result=$?
    
    # 문제 해결 제안
    if [ $validation_result -ne 0 ] || [ $WARNING_CHECKS -gt 0 ]; then
        suggest_fixes
    fi
    
    exit $validation_result
}

# 스크립트 실행
main "$@"
