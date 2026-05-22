# Caticator — Claude Code 인계 문서
> 기준 버전: v0.2.7  
> 작성: Claude Sonnet (claude.ai)  
> 경로: ~/Caticator/HANDOFF_FOR_CLAUDE_CODE.md

---

## 프로젝트 개요

**Caticator** — macOS 메뉴바 앱.  
한글/영문 입력 소스 전환 시 커서 근처에 배지를 플로팅 표시.  
단일 Swift 파일 + shell 빌드로 동작.

- **Repo:** https://github.com/Foundation19/Caticator
- **구조:** `Sources/Caticator.swift` (단일 파일 ~1,400줄) + `build.sh`
- **빌드:** `bash build.sh` → `/Applications/Caticator.app`
- **환경:** macOS 13+, Swift 5.9+

---

## 현재 상태

GitHub에는 **v0.2.4까지만 푸시**되어 있음.  
v0.2.5 ~ v0.2.7 변경은 로컬 파일에만 반영됨.

### 첫 번째 할 일 — 푸시

```bash
cd ~/Caticator
git add Sources/Caticator.swift
git commit -m "Add dim delay, size field, GIF animation, label hide fix; v0.2.7"
git tag v0.2.7
git push origin main --tags
```

---

## 버전별 변경 내역

### v0.2.5
- Icon size 수동 입력: 슬라이더 옆 텍스트 필드 (14–72px)
- Dim delay: General 탭 입력 필드 (0.1–10.0초, UserDefaults 저장)
- Reset Options에 idleDimDelay 초기화 포함

### v0.2.6
- import ImageIO 추가
- BadgeView.loadGIF(from:): ImageIO로 프레임 분해
- scheduleNextFrame(): 프레임별 타이머 재귀 스케줄
- draw() 우선순위: GIF → 정적이미지 → 색상배지
- applyAppearanceOptions(): .gif 감지 시 loadGIF() 호출

### v0.2.7 (최신)
- GIF 미동작 버그 수정: Timer() 생성 후 RunLoop.main.add() 한 번만 등록
- 레이블 겹침 수정: 이미지/GIF 사용 중 한/A 레이블 드로잉 스킵

---

## 코드 구조

```
Caticator.swift
├── 상수: appVersion="0.2.7", defaultBadgeSize, defaultIdleDimDelay=1.0
├── SettingKey: keepVisible, preferCaret, badgeSize, labels,
│              customImagePath, anchor, offsets, colors, idleDimDelay
├── BadgeAnchor (enum: 5종)
├── NSColor extension (hex)
├── BadgeView: NSView
│   ├── GIF: gifFrames[(CGImage,TimeInterval)], currentFrameIndex, gifTimer
│   ├── loadGIF(), stopGIFAnimation(), scheduleNextFrame()
│   └── draw(): GIF→이미지→색상배지, 이미지있으면 레이블 스킵
├── BadgeWindow: NSPanel + applyBadgeSize()
├── SettingsWindowController
│   ├── General: keepVisible, preferCaret, dimDelayField
│   ├── Indicator: sizeSlider+sizeField, 색상wells, 앵커, 이미지
│   └── Advanced: Reset, Open Project Folder
└── AppDelegate
    ├── idleDimDelay: TimeInterval (UserDefaults 연동)
    └── applyAppearanceOptions(): gif/image/nil 분기
```

---

## 현재 사용 GIF

- blackcat_walk.gif: 6프레임, 360ms/frame, 64×64, 투명배경
- 검은 고양이 픽셀아트 걷기 애니메이션

---

## 작업 규칙

- 한국어 소통, 영문 기술 용어 혼용
- 요청 범위만 수정 (인접 코드 임의 개선 금지)
- 비가역적 액션 전 반드시 확인
- 버전 태그는 커밋과 함께 push
- 방법론 제안 시 3가지 선택지 + 추천 명시

---

## 다음 작업 후보

1. 한글/영문 각각 다른 GIF 지정 (koreanImagePath / englishImagePath 분리)
2. WebP 지원
3. 앱 아이콘 교체 (고양이 캐릭터 AppIcon.icns)
