#!/bin/zsh
# 사용: ./build.sh [타겟명...]  (생략 시 전체). 결과는 build/<타겟>.app
set -e
cd "$(dirname "$0")"
xcodegen generate >/dev/null
TARGETS=("$@"); [[ ${#TARGETS} -eq 0 ]] && TARGETS=(BearWalker BatteryPlant TypingPulse WeatherWindow WaterTank PostureTurtle WorkdaySun FamilyBar SharedPet)
mkdir -p build
for t in $TARGETS; do
  xcodebuild -project MenubarPets.xcodeproj -scheme $t -configuration Release -derivedDataPath build/dd \
    CODE_SIGN_IDENTITY="-" CODE_SIGNING_ALLOWED=YES -quiet build
  rm -rf build/$t.app && cp -R build/dd/Build/Products/Release/$t.app build/
  echo "✓ build/$t.app"
done
