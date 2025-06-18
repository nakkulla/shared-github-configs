#!/bin/bash

# VSCode 템플릿 검증 스크립트
# 단순화된 VSCode 설정들이 올바르게 구성되었는지 확인

set -e

echo "🔍 VSCode 템플릿 검증을 시작합니다..."

# 기본 경로 설정
VSCODE_DIR="./vscode-templates"
ERRORS=0

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로그 함수들
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
    ((ERRORS++))
}

# JSON 파일 유효성 검사 함수
validate_json() {
    local file=$1
    local name=$2
    
    if [[ ! -f "$file" ]]; then
        log_error "$name 파일이 존재하지 않습니다: $file"
        return 1
    fi
    
    if ! python3 -m json.tool "$file" > /dev/null 2>&1; then
        log_error "$name JSON 구문이 잘못되었습니다: $file"
        return 1
    fi
    
    log_success "$name JSON 구문이 올바릅니다"
    return 0
}

# settings.json 검증
validate_settings() {
    local file="$VSCODE_DIR/settings.json"
    log_info "settings.json 검증 중..."
    
    if validate_json "$file" "settings.json"; then
        # 필수 설정 확인
        local required_settings=(
            "editor.formatOnSave"
            "editor.tabSize"
            "files.encoding"
            "git.autofetch"
            "github.copilot.enable"
        )
        
        for setting in "${required_settings[@]}"; do
            if grep -q "\"$setting\"" "$file"; then
                log_success "필수 설정 발견: $setting"
            else
                log_warning "필수 설정 누락: $setting"
            fi
        done
        
        # 설정 개수 확인 (단순화 검증)
        local setting_count=$(grep -o '"[^"]*":' "$file" | wc -l)
        log_info "전체 설정 개수: $setting_count (목표: 20개 이하)"
        
        if [[ $setting_count -le 20 ]]; then
            log_success "설정이 적절히 단순화되었습니다"
        else
            log_warning "설정이 여전히 복잡할 수 있습니다"
        fi
    fi
}

# extensions.json 검증
validate_extensions() {
    local file="$VSCODE_DIR/extensions.json"
    log_info "extensions.json 검증 중..."
    
    if validate_json "$file" "extensions.json"; then
        # 필수 확장 프로그램 확인
        local required_extensions=(
            "ms-vscode.vscode-json"
            "github.copilot"
            "esbenp.prettier-vscode"
        )
        
        for ext in "${required_extensions[@]}"; do
            if grep -q "\"$ext\"" "$file"; then
                log_success "필수 확장 프로그램 발견: $ext"
            else
                log_error "필수 확장 프로그램 누락: $ext"
            fi
        done
        
        # 확장 프로그램 개수 확인
        local ext_count=$(grep -o '"[^"]*",' "$file" | wc -l)
        log_info "전체 확장 프로그램 개수: $ext_count (목표: 15개 이하)"
        
        if [[ $ext_count -le 15 ]]; then
            log_success "확장 프로그램이 적절히 선별되었습니다"
        else
            log_warning "확장 프로그램이 여전히 많을 수 있습니다"
        fi
    fi
}

# tasks.json 검증
validate_tasks() {
    local file="$VSCODE_DIR/tasks.json"
    log_info "tasks.json 검증 중..."
    
    if validate_json "$file" "tasks.json"; then
        # 기본 작업 확인
        local basic_tasks=(
            "Install Dependencies"
            "Build"
            "Test"
            "Lint"
        )
        
        for task in "${basic_tasks[@]}"; do
            if grep -q "$task" "$file"; then
                log_success "기본 작업 발견: $task"
            else
                log_warning "기본 작업 누락: $task"
            fi
        done
        
        # 작업 개수 확인
        local task_count=$(grep -o '"label":' "$file" | wc -l)
        log_info "전체 작업 개수: $task_count (목표: 10개 이하)"
        
        if [[ $task_count -le 10 ]]; then
            log_success "작업 목록이 적절히 단순화되었습니다"
        else
            log_warning "작업 목록이 여전히 복잡할 수 있습니다"
        fi
    fi
}

# launch.json 검증
validate_launch() {
    local file="$VSCODE_DIR/launch.json"
    log_info "launch.json 검증 중..."
    
    if validate_json "$file" "launch.json"; then
        # 기본 디버그 설정 확인
        local basic_configs=(
            "Debug Node.js"
            "Launch Chrome"
        )
        
        for config in "${basic_configs[@]}"; do
            if grep -q "$config" "$file"; then
                log_success "기본 디버그 설정 발견: $config"
            else
                log_warning "기본 디버그 설정 누락: $config"
            fi
        done
        
        # 설정 개수 확인
        local config_count=$(grep -o '"name":' "$file" | wc -l)
        log_info "전체 디버그 설정 개수: $config_count (목표: 5개 이하)"
        
        if [[ $config_count -le 5 ]]; then
            log_success "디버그 설정이 적절히 단순화되었습니다"
        else
            log_warning "디버그 설정이 여전히 복잡할 수 있습니다"
        fi
    fi
}

# 메인 검증 실행
main() {
    echo -e "${BLUE}📁 VSCode 템플릿 디렉토리: $VSCODE_DIR${NC}"
    
    if [[ ! -d "$VSCODE_DIR" ]]; then
        log_error "VSCode 템플릿 디렉토리가 존재하지 않습니다: $VSCODE_DIR"
        exit 1
    fi
    
    validate_settings
    echo
    validate_extensions
    echo
    validate_tasks
    echo
    validate_launch
    echo
    
    # 결과 요약
    echo "========================================"
    if [[ $ERRORS -eq 0 ]]; then
        log_success "모든 VSCode 템플릿 검증이 완료되었습니다! 🎉"
        echo -e "${GREEN}✨ VSCode 설정이 성공적으로 표준화되었습니다.${NC}"
    else
        log_error "총 $ERRORS 개의 오류가 발견되었습니다."
        echo -e "${RED}🔧 위 오류들을 수정해주세요.${NC}"
        exit 1
    fi
}

# 스크립트 실행
main "$@"
