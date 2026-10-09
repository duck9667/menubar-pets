# menubar-pets

맥 메뉴바에 상주하는 작은 픽셀 캐릭터 앱 9종. 런캣(RunCat)류의 "메뉴바 펫" 모음.
공용 픽셀 아트 엔진 하나(`Shared/`)에 앱마다 `main.swift` 한 파일. 서버 없음, 외부 라이브러리 없음.

## 앱 목록

| 타겟 | 이름 | 하는 일 |
|---|---|---|
| BearWalker | 곰 산책러 | 뽀모도로(25/50분) 타이머. 곰 걷는 속도 = 오늘 집중 시간. 세션 끝나면 간식 + 알림 |
| BatteryPlant | 배터리 식물 | 배터리 잔량이 식물 5단계로. 충전 중이면 자라고 20% 아래면 시듦 |
| TypingPulse | 키보드 심박계 | 최근 10초 타자 속도(WPM)에 따라 토끼가 달림. 손쉬운 사용 권한 필요 |
| WeatherWindow | 날씨 창문 | 창 밖 풍경이 지금 날씨·시간대(맑음/흐림/비/눈/뇌우, 낮/노을/밤)로 바뀜. Open-Meteo, 키 불필요 |
| WaterTank | 물 어항 | 왼쪽 클릭 = 물 한 잔. 2시간 안 마시면 물이 탁해지고 물고기가 흐려짐 |
| PostureTurtle | 자세 거북이 | N분(25/45/60/90)마다 거북이가 목을 빼고 쳐다봄. 클릭하면 "허리 폈어요" 기록 |
| WorkdaySun | 퇴근 해 | 출근~퇴근 사이 해가 떠서 짐. 퇴근 시각 지나면 달이 뜨고 +야근 시간 표시 |
| FamilyBar | 가족 메뉴바 | 사진 폴더에서 하루 한 장 동그란 아이콘으로. 기념일 D-30부터 표시 |
| SharedPet | 공유 펫 | 둘이 같은 햄스터를 키움. iCloud Drive 등 공유 폴더의 `pet.json`을 양쪽이 감시해 동기화 |

## 빌드

```bash
./build.sh            # 전체, 결과는 build/<타겟>.app
./build.sh BearWalker # 하나만
```

요구: Xcode, `brew install xcodegen`. ad-hoc 서명이라 본인 맥에서 바로 실행 가능. 배포하려면 Developer ID 서명 + 공증 필요.

## 구조

```
Shared/PixelArt.swift            문자 그리드 → NSImage (18pt, 라이트/다크 자동)
Shared/StatusBarController.swift 상태바 아이템 + 프레임 타이머 + 블록 메뉴 + 공용 진입점
Apps/<Target>/main.swift         앱 하나당 파일 하나
project.yml                      xcodegen (타겟 9개, macOS 14+)
```

새 캐릭터 추가: `Apps/`에 폴더 만들고 `project.yml`에 타겟 한 블록 복사. 스프라이트는 문자 배열로 그린다
(`#` 본체, `o` 그림자, `r g b y w k n p c d` 색, `.` 투명).

## 메모

- 메뉴바가 꽉 찬 맥(노치)은 넘치는 아이템을 숨긴다. 전부 띄우려면 Bartender류가 필요하다.
- 공유 펫 기본 경로는 `~/Library/Mobile Documents/com~apple~CloudDocs/MenubarPet/pet.json`. 메뉴에서 바꿀 수 있다.
