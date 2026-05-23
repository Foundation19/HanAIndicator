# Caticator — Claude Code 지침 (CLAUDE.md)

> 범용 원칙은 `~/CLAUDE.md` 참조. 이 파일은 **Caticator 프로젝트 특화 지침만** 담는다.

---

## 프로젝트 정의

**Caticator** — macOS 메뉴바 앱. 한글/영문 입력 소스 전환 시 텍스트 커서 근처에
플로팅 뱃지(`한` / `A`) 표시. Cat Mode (GIF), 커스텀 이미지, 컬러 커스터마이징 지원.

- **현재 버전**: 0.3.4
- **GitHub**: https://github.com/Foundation19/Caticator
- **Bundle ID**: `local.caticator.app`
- **최소 OS**: macOS 13+
- **구조**: 단일 Swift 파일 (`Sources/Caticator.swift`, ~2,270줄) + `build.sh`
- **라이선스**: 미정 (App Store 출시 검토 중)

---

## 저장소 구조

```
~/Caticator/
├── Sources/
│   └── Caticator.swift              ← 메인 (단일 파일)
├── build.sh                          ← 빌드 + 셀프 코드사인
├── AppIcon.icns                      ← 앱 아이콘
├── README.md
├── HANDOFF_FOR_CLAUDE_CODE.md
├── Caticator-v0.3.*.dmg              ← 배포용 패키지
└── build/Caticator.app              ← 빌드 결과물
```

---

## 빌드 + 배포

```bash
# 빌드
bash build.sh
# → ~/Caticator/build/Caticator.app

# 배포 (로컬 설치)
pkill Caticator 2>/dev/null; sleep 1
rm -rf /Applications/Caticator.app
cp -R ~/Caticator/build/Caticator.app /Applications/
open /Applications/Caticator.app

# DMG 패키징
DMG_DIR=$(mktemp -d)
cp -R ~/Caticator/build/Caticator.app "$DMG_DIR/"
ln -s /Applications "$DMG_DIR/Applications"
hdiutil create -volname "Caticator" -srcfolder "$DMG_DIR" -format UDZO \
  -fs HFS+ -ov ~/Caticator/Caticator-v0.X.Y.dmg
rm -rf "$DMG_DIR"
```

---

## 의존 프레임워크

```swift
import AppKit                  // UI
import Carbon                  // TIS (Text Input Source) 감지
import ApplicationServices     // Accessibility API (AXUIElement)
import ServiceManagement       // Launch at Login
```

---

## 코드 서명

| 항목 | 현재 | 비고 |
|---|---|---|
| 인증서 | `HanAIndicator Local` (셀프서명) | 변경 안 함 (App Store 갈 때 Apple 인증서로 일괄 교체 예정) |
| 권한 | macOS Accessibility 필요 | 셀프서명 유지하면 권한 재요청 없음 |

---

## v0.3.3 핵심 변경 (Allowed Apps)

- **이전**: Excluded Apps (블랙리스트) — 지정된 앱에서만 인디케이터 숨김
- **현재**: Allowed Apps (화이트리스트) — **지정된 앱에서만** 인디케이터 표시
- UserDefaults 키: `allowedApps` (신규), 기존 `excludedApps` 데이터는 무시됨
- 기본값: 빈 목록 (사용자가 `+` 버튼으로 직접 추가)

---

## App Store 출시 계획 (보류)

**현재 막힘**: `AXUIElementCreateApplication`, `kAXFocusedUIElementAttribute`,
`kAXSelectedTextRangeAttribute`, `kAXBoundsForRangeParameterizedAttribute` 등 다른 앱
내부를 들여다보는 Accessibility API 사용 → App Store에서 거의 100% 거부.

**대안**: AX 코드 제거 + 마우스 위치 전용 버전 별도 빌드 (Keyla와 동일 방식).
출시 결정 시 Apple Developer Program 가입 ($99/년) 필요.

---

## 파일 보호 규칙

```
❌ AppIcon.icns 덮어쓰기 (단순한 변경 요청에)
❌ Caticator-v*.dmg 삭제
❌ build.sh 인증서 이름 임의 변경 (권한 재설정 유발)
❌ Sources/Caticator.swift의 GIF base64 블록 (`embeddedBlackCatGif`) 수정
```

---

## 자주 쓰는 명령

```bash
# 실행 중 프로세스 확인
pgrep -la Caticator

# 사용자 설정 확인
defaults read local.caticator.app

# 사용자 설정 리셋 (위험)
defaults delete local.caticator.app

# 크래시 로그
ls -lt ~/Library/Logs/DiagnosticReports/Caticator-*.ips | head -3
```
