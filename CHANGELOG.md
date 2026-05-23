# Caticator — Changelog

---

## v0.3.4 (2026-05-23) — 터미널 지원 + 안정성 수정

### 버그 수정
- **[크래시]** `bestTextElement(from:)` AX 트리 순환 참조 시 무한 재귀 → 스택 오버플로우(SIGSEGV) 수정. 재귀 깊이 8로 제한.
- **[Hyper 위치]** 터미널 앱에서 AX `elementRect` fallback이 엉뚱한 위치(요소 상단) 반환 → 터미널은 AX 캐럿 완전히 건너뛰고 윈도우 하단 좌측 고정 위치 사용.
- **[Hyper 위치]** 배지가 터미널 프롬프트 클릭 위치(dock 근처)를 따라 dock 영역에 나타나던 문제 수정. 터미널은 click 위치 대신 항상 윈도우 기반 위치 사용.
- **[마우스 따라가기]** 한글 모드 중 클릭 시 `lastClickPoint` 업데이트되어 배지가 클릭 위치로 점프하던 문제 수정. 한글 모드에서는 클릭 위치 추적 차단.
- **[keepVisible]** `blackCatMode` 활성화 시 영어 모드에서 `keepVisible=true`여도 배지가 숨겨지던 문제 수정. `blackCatMode && !cachedIsKorean && !keepVisible` 조건으로 변경.
- **[배지 사라짐]** 한글 타이핑 중 `hideAt` 만료로 배지가 사라지던 문제 수정. `keyDown` 이벤트마다 `hideAt` 2초 연장.
- **[허용 앱 즉시 반영]** Settings에서 앱 추가 후 해당 앱으로 전환 시 바로 배지가 나타나지 않던 문제 수정. 앱 전환 시 `hideAt` 갱신.
- **[흰 고양이]** `NSAppearance.current` → `NSApp.effectiveAppearance`로 교체, 다크모드 감지 정확도 개선.
- **[흰 고양이]** 수동 `invertColors` 설정이 `updateInvertForBackground()`의 자동 감지값으로 매 tick마다 덮어씌워지던 문제 수정. `shouldInvert = invertColors || isTerminal || isDarkMode`.
- **[클릭 모니터]** `NSEvent.addGlobalMonitorForEvents` 반환값 미저장으로 클릭 모니터가 즉시 해제되던 버그 수정. `clickMonitor` 프로퍼티에 저장.

### 개선
- 터미널 앱(`knownDarkAppIDs`)에서 `preferCaret` 모드일 때 AX 캐럿 감지를 건너뛰어 성능 개선 및 잘못된 위치 표시 방지.
- 배지 Y 위치 계산: `anchor=bottomLeft` + `offsetY=-10` + `windowHeight=40` 기준으로 커서 라인 수준에 정확히 배치 (`appKitBottom + 70`).

---

## v0.3.3 (2026-05-22) — Allowed Apps (화이트리스트)

### 변경
- **Excluded Apps(블랙리스트) → Allowed Apps(화이트리스트)** 방식으로 전환.
  - 이전: 지정된 앱에서만 인디케이터 숨김
  - 현재: 지정된 앱에서만 인디케이터 표시
- UserDefaults 키: `allowedApps` (신규). 기존 `excludedApps` 데이터 무시.
- 기본값: 빈 목록 (사용자가 직접 추가).

---

## v0.3.2 (2026-05-21) — Launch at Login

### 추가
- **Launch at Login** 옵션 (ServiceManagement 프레임워크).
- Settings에 체크박스 추가.

---

## v0.3.1 (2026-05-20) — UI 폴리시 + Cat Mode

### 추가
- **Cat Mode** (구 Black Cat Mode 리네임): 한글 입력 시 GIF 애니메이션 표시, 영어 시 숨김.
- 커스텀 GIF 경로 지정 가능.
- 다크/라이트 배경 자동 감지 → 흰/검 고양이 자동 전환 (`invertColors`).
- 메뉴바 아이콘 동적 전환 (한글/영문 상태 반영).
- 배지 앵커 위치 5종 선택 (bottomLeft/bottomRight/topLeft/topRight/centered).
- 오프셋 X/Y 수동 조정.

### 수정
- Velocity filter: AX 오류 좌표(Y 200px 이상 점프) 필터링으로 배지 떨림 방지.
- Excluded Apps UI 개선.
- 메뉴바 아이콘 안정화.

---

## v0.3.0 (2026-05-18) — Caticator 리네임 + 메뉴바 고양이

### 변경
- 프로젝트명 **HanAIndicator → Caticator**.
- 메뉴바에 고양이 아이콘 추가.

---

## v0.2.x (이전) — HanAIndicator 초기 개발

### 주요 이력
- `ab6724f` 초기 HanAIndicator 앱 (한/영 전환 시 텍스트 배지 표시).
- `2b547e5` 설정 카테고리화, 배지 커스터마이징 (색상, 크기, 레이블).
- `ef9ff9c` 배지 화면 밖 clipping 방지.
- `f229142` 부드러운 배지 커서 추적.
- `b2ada88` 커서 기준 배지 위치.
- `6426269` 텍스트 커서 감지 개선 (AX API).
- `9d1b2d9` caret 모드에서 마우스 fallback 방지.
- `3242e14` 보이는 배지 fallback 복원.
- `e78d736` 배지 스타일 및 idle opacity 개선.
- `d5c28e2` Keyla 스타일 라이트 배지.
- `a68a6e6` 배지 렌더링 선명도 개선.
- `d62eedf` 언어별 개별 색상 설정.
