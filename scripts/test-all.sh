#!/bin/bash

# 통합 테스트 스크립트
# 모든 핵심 기능을 자동으로 테스트합니다.

set -euo pipefail

# 색상 설정
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_LOG="$SCRIPT_DIR/test-results-$(date +%Y%m%d-%H%M%S).log"

# 테스트 결과 카운터
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# 테스트 함수
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expect_success="${3:-true}"
    
    ((TESTS_TOTAL++))
    echo -e "${BLUE}[TEST $TESTS_TOTAL]${NC} $test_name"
    echo "명령어: $test_command" >> "$TEST_LOG"
    
    if eval "$test_command" >> "$TEST_LOG" 2>&1; then
        if [[ "$expect_success" == "true" ]]; then
            echo -e "${GREEN}✅ PASS${NC}"
            ((TESTS_PASSED++))
        else
            echo -e "${RED}❌ FAIL (예상된 실패가 성공함)${NC}"
            ((TESTS_FAILED++))
        fi
    else
        if [[ "$expect_success" == "false" ]]; then
            echo -e "${GREEN}✅ PASS (예상된 실패)${NC}"
            ((TESTS_PASSED++))
        else
            echo -e "${RED}❌ FAIL${NC}"
            ((TESTS_FAILED++))
        fi
    fi
    echo "---" >> "$TEST_LOG"
}

echo "🧪 Shared GitHub Configs 통합 테스트 시작"
echo "테스트 로그: $TEST_LOG"
echo ""

# 1. 기본 도움말 테스트
echo -e "${YELLOW}== 기본 기능 테스트 ==${NC}"
run_test "sync-configs-improved.sh 도움말" "./scripts/sync-configs-improved.sh --help"
run_test "submodule-manager.sh 도움말" "./scripts/submodule-manager.sh --help"

# 2. 상태 확인 테스트
echo -e "${YELLOW}== 상태 확인 테스트 ==${NC}"
run_test "동기화 상태 확인" "./scripts/sync-configs-improved.sh status"
run_test "submodule 상태 확인" "./scripts/submodule-manager.sh status"

# 3. 검증 테스트
echo -e "${YELLOW}== 검증 테스트 ==${NC}"
run_test "설정 파일 검증" "./scripts/sync-configs-improved.sh validate"
run_test "submodule 분석" "./scripts/submodule-manager.sh analyze"

# 4. Dry-run 테스트
echo -e "${YELLOW}== Dry-run 테스트 ==${NC}"
run_test "동기화 dry-run" "./scripts/sync-configs-improved.sh pull --dry-run"
run_test "GitHub 설정 dry-run" "./scripts/sync-configs-improved.sh push --dry-run --type github"

# 5. 백업 테스트
echo -e "${YELLOW}== 백업 테스트 ==${NC}"
run_test "설정 백업 생성" "./scripts/sync-configs-improved.sh backup"
run_test "submodule 백업 생성" "./scripts/submodule-manager.sh backup"

# 6. 오류 시나리오 테스트
echo -e "${YELLOW}== 오류 처리 테스트 ==${NC}"
run_test "잘못된 옵션 처리" "./scripts/sync-configs-improved.sh --invalid-option" false
run_test "잘못된 명령어 처리" "./scripts/submodule-manager.sh invalid_command" false

# 7. 로그 파일 테스트
echo -e "${YELLOW}== 로깅 테스트 ==${NC}"
LOG_FILE="test-sync.log"
run_test "로그 파일 생성" "./scripts/sync-configs-improved.sh status --log $LOG_FILE"
run_test "로그 파일 존재 확인" "test -f $LOG_FILE"

# 정리
[[ -f "$LOG_FILE" ]] && rm -f "$LOG_FILE"

# 결과 출력
echo ""
echo "🏁 테스트 완료"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "총 테스트: ${BLUE}$TESTS_TOTAL${NC}"
echo -e "성공: ${GREEN}$TESTS_PASSED${NC}"
echo -e "실패: ${RED}$TESTS_FAILED${NC}"

if (( TESTS_FAILED == 0 )); then
    echo -e "${GREEN}✅ 모든 테스트 통과!${NC}"
    echo "상세 로그: $TEST_LOG"
    exit 0
else
    echo -e "${RED}❌ $TESTS_FAILED 개 테스트 실패${NC}"
    echo "상세 로그: $TEST_LOG"
    exit 1
fi
