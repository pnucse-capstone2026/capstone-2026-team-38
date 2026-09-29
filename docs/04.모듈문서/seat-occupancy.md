# 좌석 점유·폴딩 판정 모듈 (`gtrack_clearance_demo/`)

> 아래 명령은 `gtrack_clearance_demo/` 폴더에서 실행합니다.

> 3D People Tracking 펌웨어(GTRACK)가 주는 **트랙 좌표 + 포인트클라우드** 위에, 호스트에서
> **좌석 존(3D 박스)** 점유를 판정해 시트 폴딩 clearance를 결정한다.
> 존 점유 = 트랙 근거 OR 포인트클라우드 presence 근거. 불확실하면 폴딩을 막는다(fail-safe).

## 전제
- 센서에 **3D People Tracking 펌웨어**(`3D_people_track_6843_demo.bin`)가 플래시돼 있어야 함
- cfg: `chirp_configs/ISK_incabin_tightgate.cfg` (기본값, 연관 게이트를 캐빈 스케일로 축소한 튜닝본)
- 3D 창: PyOpenGL 필요 (`pip install PyOpenGL`). 없으면 `--no-plot` 으로 콘솔만

## 실행
```bash
# 하드웨어 없이 로직 검증
py track_parser.py         # UART 파서 왕복 테스트
py pointcloud_parser.py    # 트랙 + 포인트클라우드 파서 테스트
py clearance_gtrack.py     # 존 점유 상태머신 self-test
py presence_monitor.py     # presence 폴백·멈춘 트랙 필터 self-test

# 센서 (Industrial Visualizer 를 먼저 닫아 COM 포트 해제)
# 포트(COM10, COM11)·cfg 는 생략하면 기본값. 바꿀 때만 옵션보다 앞에 적는다.
py main_presence_clearance.py                                       # 기본 포트·cfg 로 실행
py main_presence_clearance.py --duration 60                         # 60초 후 자동 종료
py main_presence_clearance.py COM5 COM6 "chirp_configs/X.cfg"     # 포트·cfg 를 바꿀 때
```

| 옵션 | 용도 |
|---|---|
| `--duration 초` | 자동 종료 |
| `--no-config` | 비주얼라이저가 이미 cfg 를 보내 스트리밍 중일 때 (측정 때는 쓰지 않음) |
| `--no-plot` | 3D 창 끄기 |
| `--debug` | 진단 출력 (근거·멈춘 트랙 필터 `[frz ]`) |

실행 중 `q` 를 누르면 종료합니다.

판정 설정은 `main_presence_clearance.py` 상단 상수로 고정한다(9/18 채택 구성).

| 상수 | 값 | 의미 |
|---|---|---|
| `PRESENCE_CONFIRM` (K) | 2 | 최근 8프레임 중 2프레임 이상에서 존 안 점 3개 이상이어야 presence 근거 |
| `FREEZE_SEC` (F) | 3.0 | 좌표가 3초 넘게 변하지 않은 트랙은 근거에서 제외 (퇴장 후 유령 트랙 억제) |
| `EMPTY_CONFIRM_SEC` (E) | 3.0 | 근거가 끊긴 뒤 3초가 지나야 EMPTY 확정 |

## 파일
| 파일 | 역할 |
|---|---|
| `main_presence_clearance.py` | 실행 파일. 센서 스트림 → 파서 → 존 판정 → 콘솔·3D 창·트윈 서버·프레임 로그 |
| `track_parser.py` | UART → Target List(TLV 1010) 파싱, 좌표 변환 |
| `pointcloud_parser.py` | 트랙(1010) + 압축 포인트클라우드(1020) 파싱 |
| `clearance_gtrack.py` | 좌석 존 정의 + 존 점유 상태머신 + fold 허용 |
| `presence_monitor.py` | 존 점유 = 트랙 OR presence, 멈춘 트랙 필터(F), 손상 프레임 트랙 제외 |
| `plot_gtrack_clearance_3d.py` | 3D 캐빈 뷰 기본 클래스 (존 박스·트랙·FOLD 배너) |
| `plot_presence_3d.py` | 위 클래스를 상속해 포인트클라우드·존별 근거 표시 |
| `clearance_publisher.py` | digital_twin 서버로 좌석 상태 HTTP 전송 (서버가 꺼져 있으면 무시) |

## 좌석 영역 설정
`clearance_gtrack.py`의 좌석 존은 `placeholder` 세트를 쓴다(`main_presence_clearance.py` 의 `ZONE_SET`).
```python
Zone('Passenger', xmin, xmax, ymin, ymax)   # 센서 좌표 m, X=측방 Y=거리
```
`sensorPosition`(cfg)이 실제 마운트와 맞아야 좌표가 정확하다.

## fail-safe 주의 (실차 적용 시)
- 시작 직후 `WARMUP_BLOCK_SEC`(5초) 동안은 무조건 폴딩 차단.
- fold 허용은 **뒷좌석 전 존 EMPTY 확정 + 워밍업 경과**일 때만 (조수석은 폴딩 판정 제외).
- 정지 승객은 트랙이 멈추거나 끊길 수 있어 포인트클라우드 presence 로 보완한다.
- 측정 중에는 실제 폴딩 장치를 연결하지 않는다.

