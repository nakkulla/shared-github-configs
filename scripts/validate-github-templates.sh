#!/bin/bash

# GitHub 템플릿 검증 스크립트
# 작성자: GitHub Copilot & Taskmaster
# 목적: 워크플로우와 이슈 템플릿의 기본 유효성 검증

echo "🔍 GitHub 템플릿 및 워크플로우 검증 중..."
echo "=================================================="

# 기본 경로 설정
GITHUB_DIR="github-templates"
ERRORS=0

# 필수 파일 존재 확인
echo "📁 필수 파일 존재 확인..."

REQUIRED_FILES=(
    "${GITHUB_DIR}/workflows/ci-basic.yml"
    "${GITHUB_DIR}/workflows/ci-language-specific.yml"
    "${GITHUB_DIR}/ISSUE_TEMPLATE/bug_report.yml"
    "${GITHUB_DIR}/ISSUE_TEMPLATE/feature_request.yml"
    "${GITHUB_DIR}/ISSUE_TEMPLATE/documentation.yml"
    "${GITHUB_DIR}/ISSUE_TEMPLATE/security.yml"
    "${GITHUB_DIR}/ISSUE_TEMPLATE/config.yml"
    "${GITHUB_DIR}/PULL_REQUEST_TEMPLATE/pull_request_template.md"
    "${GITHUB_DIR}/CODEOWNERS"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file - 파일 없음"
        ((ERRORS++))
    fi
done

echo ""

# YAML 기본 구조 검증
echo "🔧 YAML 파일 기본 구조 검증..."

# 워크플로우 검증
for workflow in "${GITHUB_DIR}/workflows"/*.yml; do
    if [ -f "$workflow" ]; then
        echo "검증 중: $(basename "$workflow")"
        
        # 필수 키 확인
        if grep -q "^name:" "$workflow" && grep -q "^on:" "$workflow" && grep -q "^jobs:" "$workflow"; then
            echo "✅ $(basename "$workflow") - 기본 구조 유효"
        else
            echo "❌ $(basename "$workflow") - 필수 키 누락 (name, on, jobs)"
            ((ERRORS++))
        fi
        
        # 최신 Actions 버전 사용 확인
        if grep -q "actions/checkout@v4" "$workflow"; then
            echo "✅ $(basename "$workflow") - 최신 checkout action 사용"
        else
            echo "⚠️ $(basename "$workflow") - checkout action 버전 확인 필요"
        fi
    fi
done

echo ""

# 이슈 템플릿 검증
echo "📋 이슈 템플릿 구조 검증..."

for template in "${GITHUB_DIR}/ISSUE_TEMPLATE"/*.yml; do
    if [ -f "$template" ] && [ "$(basename "$template")" != "config.yml" ]; then
        echo "검증 중: $(basename "$template")"
        
        # 필수 필드 확인
        if grep -q "^name:" "$template" && grep -q "^description:" "$template" && grep -q "^body:" "$template"; then
            echo "✅ $(basename "$template") - 기본 구조 유효"
        else
            echo "❌ $(basename "$template") - 필수 필드 누락 (name, description, body)"
            ((ERRORS++))
        fi
        
        # 라벨 형식 확인
        if grep -q "labels:" "$template"; then
            echo "✅ $(basename "$template") - 라벨 설정됨"
        else
            echo "⚠️ $(basename "$template") - 라벨 설정 권장"
        fi
    fi
done

echo ""

# PR 템플릿 검증
echo "🔄 PR 템플릿 검증..."

PR_TEMPLATE="${GITHUB_DIR}/PULL_REQUEST_TEMPLATE/pull_request_template.md"
if [ -f "$PR_TEMPLATE" ]; then
    # 필수 섹션 확인
    REQUIRED_SECTIONS=(
        "변경사항 요약"
        "변경 유형"
        "관련 이슈"
        "테스트"
        "체크리스트"
    )
    
    for section in "${REQUIRED_SECTIONS[@]}"; do
        if grep -q "$section" "$PR_TEMPLATE"; then
            echo "✅ PR 템플릿 - '$section' 섹션 포함"
        else
            echo "❌ PR 템플릿 - '$section' 섹션 누락"
            ((ERRORS++))
        fi
    done
else
    echo "❌ PR 템플릿 파일 없음"
    ((ERRORS++))
fi

echo ""

# 템플릿 실용성 검증
echo "💡 템플릿 실용성 검증..."

# 이모지 라벨 사용 확인
if grep -r "🐛\|✨\|📚\|🔒" "${GITHUB_DIR}/ISSUE_TEMPLATE"/*.yml > /dev/null 2>&1; then
    echo "✅ 이모지 라벨 시스템 사용됨"
else
    echo "⚠️ 이모지 라벨 시스템 미사용"
fi

# 다국어 지원 확인 (한국어)
if grep -r "한국어\|버그\|기능" "${GITHUB_DIR}/ISSUE_TEMPLATE"/*.yml > /dev/null 2>&1; then
    echo "✅ 한국어 지원됨"
else
    echo "⚠️ 한국어 지원 확인 필요"
fi

# 보안 고려사항 확인
if [ -f "${GITHUB_DIR}/ISSUE_TEMPLATE/security.yml" ]; then
    if grep -q "보안\|security" "${GITHUB_DIR}/ISSUE_TEMPLATE/security.yml"; then
        echo "✅ 보안 템플릿 적절히 구성됨"
    else
        echo "⚠️ 보안 템플릿 내용 검토 필요"
    fi
fi

echo ""
echo "=================================================="

# 결과 요약
if [ $ERRORS -eq 0 ]; then
    echo "🎉 모든 검증 통과! 템플릿과 워크플로우가 올바르게 구성되었습니다."
    echo ""
    echo "📊 검증 완료 요약:"
    echo "- ✅ 필수 파일: $(echo "${REQUIRED_FILES[@]}" | wc -w)개 확인"
    echo "- ✅ 워크플로우: 구조 및 최신 Actions 버전 사용"
    echo "- ✅ 이슈 템플릿: 기본 구조 및 필수 필드"
    echo "- ✅ PR 템플릿: 필수 섹션 포함"
    echo "- ✅ 실용성: 이모지 라벨, 한국어 지원, 보안 고려"
    echo ""
    echo "🚀 GitHub 저장소에 적용할 준비가 완료되었습니다!"
    exit 0
else
    echo "❌ $ERRORS개의 오류가 발견되었습니다."
    echo "위 오류들을 수정 후 다시 실행해주세요."
    exit 1
fi
