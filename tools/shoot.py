"""각 앱을 하나씩 띄워 메뉴바 아이콘만 잘라 docs/screenshots/<Target>.png 로 저장.
빈 메뉴바(baseline)와 픽셀 차이가 나는 x 구간을 찾아 자른다. 시계 영역은 제외."""
import subprocess, time, sys, numpy as np
from PIL import Image
APPS = sys.argv[1:] or "BearWalker BatteryPlant TypingPulse WeatherWindow WaterTank PostureTurtle WorkdaySun FamilyBar SharedPet".split()
REGION = "500,0,900,26"   # 논리 px. 오른쪽 고정 아이콘·시계 제외
def shot(path):
    subprocess.run(["screencapture","-x","-R",REGION,path],check=True)
    return np.asarray(Image.open(path).convert("RGB")).astype(int)
def kill(t): subprocess.run(["pkill","-x",t])
for t in APPS: kill(t)
time.sleep(1.5)
base = shot("/tmp/mb_base.png")
for t in APPS:
    subprocess.run(["open",f"build/{t}.app"]); time.sleep(4)
    # 애니메이션 2프레임 평균 대신 첫 프레임 사용
    cur = shot(f"/tmp/mb_{t}.png"); kill(t); time.sleep(1)
    diff = np.abs(cur-base).sum(axis=2).max(axis=0) > 40
    xs = np.where(diff)[0]
    if len(xs)==0: print("no diff", t); continue
    # 가장 오른쪽 덩어리(새 아이템은 기존 아이템 왼쪽에 끼며 기존 것들이 왼쪽으로 밀림 → 변화 구간이 넓음)
    # 그래서 변화 구간 전체를 자르되, 좌우 패딩 8px(레티나 16)
    x0, x1 = max(0, xs.min()-16), min(cur.shape[1], xs.max()+16)
    img = Image.open(f"/tmp/mb_{t}.png").crop((x0, 0, x1, cur.shape[0]))
    img.save(f"docs/screenshots/{t}.png"); print("saved", t, x1-x0)
