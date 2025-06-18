---
description: "ntfy MCP 도구 사용 가이드 - 간결한 핵심 버전"
applyTo: "**"
---

# 📱 ntfy MCP 도구 핵심 가이드

## 🎯 핵심 규칙 (필수)

### 1. 언어 규칙
- **taskTitle**: 반드시 영어 (헤더 인코딩 문제 방지)
- **taskSummary**: 한국어 상세 설명

### 2. 알림 빈도
- **일일 최대**: 10개 이내
- **High 우선순위**: 진짜 중요할 때만

### 3. 알림 시점
✅ **완료 + 피드백 필요시**
🚨 **오류/막힘 발생시**  
📋 **중요 결정 필요시**

---

## 🔧 기본 사용법

```javascript
ntfy_me({
  taskTitle: "Task Complete",              // 필수, 영어만
  taskSummary: "작업이 완료되었습니다.",     // 필수, 한국어
  priority: "high|default",               // 선택, 기본값: default
  tags: ["complete", "review"],           // 선택
  markdown: true                          // 선택
})
```

---

## 📋 핵심 예시

### 1. ✅ 작업 완료 (피드백 필요)
```javascript
ntfy_me({
  taskTitle: "Task Complete - Review Needed",
  taskSummary: `작업 "${taskName}"이 완료되었습니다.

✅ **완료 내용**: ${completedWork}
🎯 **다음 단계**: ${nextStep}

계속 진행하시겠습니까?`,
  priority: "high",
  tags: ["complete", "review-needed"],
  markdown: true
})
```

### 2. 🚨 오류 발생
```javascript
ntfy_me({
  taskTitle: "Error - Help Needed",
  taskSummary: `작업 중 문제가 발생했습니다.

🚨 **문제**: ${errorDescription}
🔍 **시도한 해결책**: ${attemptedSolutions}
🆘 **필요한 도움**: ${helpNeeded}`,
  priority: "high",
  tags: ["error", "help-needed"],
  markdown: true
})
```

### 3. 📊 분석 완료 (결정 필요)
```javascript
ntfy_me({
  taskTitle: "Analysis Complete",
  taskSummary: `분석이 완료되었습니다.

📊 **결과 요약**: ${analysisResults}
💡 **추천 방향**: ${recommendation}

결정해주시면 진행하겠습니다.`,
  priority: "high",
  tags: ["analysis", "decision-needed"],
  markdown: true
})
```

---

## ⚡ 우선순위 가이드

### 🔴 High Priority (즉시 확인)
- 피드백/결정이 필요한 상황
- 오류로 작업이 막힌 상황
- 중요한 마일스톤 완료

### 🟡 Default Priority (일반 보고)
- 일반적인 작업 진행 상황
- 정보 공유 목적

---

## 🏷️ 자주 쓰는 태그

```javascript
// 상황별
["complete", "error", "blocked", "review-needed", "decision-needed"]

// 단계별  
["planning", "development", "testing", "deploy"]

// 중요도
["urgent", "important", "normal"]
```

---

## ✅ 체크리스트

알림 발송 전 확인:
- [ ] taskTitle이 영어인가?
- [ ] taskSummary가 구체적인가?
- [ ] priority가 적절한가?
- [ ] 하루 10개 이내인가?

---

이 가이드로 효율적인 알림 시스템을 구축하세요! 🚀