# 운전자 바이탈·각성도 모듈 (`vital_signs/`)

TI 공식 **Vital Signs with People Tracking** 펌웨어의 UART 출력을 받아, 호흡 상태와 각성도를 판정하고 디지털 트윈으로 보냅니다.

## 실행

```bash
python vital_signs/run_twin.py                      # 기본 COM4(CLI) / COM3(DATA)
python vital_signs/run_twin.py COM4 COM3 --no-serve
```

| 인자·옵션 | 설명 |
|---|---|
| `cli`, `data` | CLI(115200 bps)·DATA(921600 bps) COM 포트. 생략하면 기본값 |
| `cfg` | 공식 cfg 경로. 기본값 `chirp_configs/vital_signs_ISK_rearview.cfg` |
| `--no-serve` | 트윈 서버를 이 프로세스에서 켜지 않음 (서버를 따로 실행할 때 사용) |
| `--twin-url` | 이벤트를 보낼 주소. 기본값 `http://127.0.0.1:8766/event` |

- 보드에 공식 `vital_signs_tracking_6843ISK_demo.bin`이 올라가 있어야 합니다. TI Radar Toolbox에서 받아 UniFlash로 플래시합니다(Device `IWR6843`, Enhanced COM, Meta Image 1).
- 실행 전에 Industrial Visualizer를 닫아 COM 포트를 비워 주세요. 좌석 판정 모듈과는 **다른 보드**를 사용합니다.
- 실행하면 스크립트가 cfg를 보냅니다. 보드 NRST 직후에 실행하면 안정적입니다.
- 앉아서 가슴을 센서 쪽으로 향하고 **20초 이상 정지**해야 트랙이 잡히고 바이탈이 나옵니다.

## 콘솔 출력

```text
[ 1234] BREATHING   HR= 72  RR= 14  hold= 0.0s  tracks=1
```

맨 앞은 수신 프레임 수입니다. 이 값이 0에서 멈춰 있으면 COM 포트나 펌웨어를 확인하세요.

## 호흡 상태 전이

| 상태 | 의미 | 트윈 화면 |
|---|---|---|
| `SEARCHING` | 트랙 없음 | 검색 중 |
| `BREATHING` | 정상 호흡 | 정상 주행 |
| `HOLD` | 호흡 변동이 기준 이하 | 무호흡 시간 증가 |
| `WARNING` | Hold 10초 지속 | 5초 뒤 확인창 |
| `DANGER` | 확인창 미응답 5초 | 갓길 정차 (시뮬레이션) |
| `MOTION` | 움직임 구간 | 판정 보류 |

## 각성도 저하 모니터 (`drowsiness_judge.py`)

- 20초 창의 심박 표준편차를 5분 평활한 뒤 개인 기준선으로 z-정규화합니다.
- 세션 시작 후 약 **11분(660초)** 은 보정 구간(`CALIB`)이며, 이후 `NORMAL` / `DEVIATED`를 판정합니다.
- z ≥ 1.5가 연속 4회(약 40초) 이어져야 이탈로 확정합니다.
- 졸음 확정 경보가 아니라 **개인 기준선 이탈 모니터**이며, 판정 결과는 트윈에 별도 필드로 전달됩니다.

## 설치 위치와 cfg

- 룸미러 부근 장착 기준 cfg는 `vital_signs_ISK_rearview.cfg`, 근거리 착석 기준은 `vital_signs_ISK_2m.cfg`입니다.
- cfg의 `sensorPosition` 첫 숫자는 장착 높이(m), 마지막은 하향 틸트(도)입니다. 실제 장착에 맞춰 조정합니다. TI 권장은 높이 1~1.5 m, 틸트 0~15°입니다.

## 파일

| 파일 | 역할 |
|---|---|
| `run_twin.py` | 실행 진입점 |
| `twin_bridge.py` | UART 파싱, 호흡 상태 판정, 트윈 전송 |
| `drowsiness_judge.py` | 각성도 저하 판정 |
| `paths.py` | 툴박스·cfg 경로 정의 |
| `flash_isk.py` | 펌웨어 플래시 보조 스크립트 |
| `chirp_configs/` | 공식 cfg 2종 |
