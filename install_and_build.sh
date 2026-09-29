#!/bin/sh
# Non-Vision 기반 차량 내부 위험 감지 시스템 - 설치 및 실행
# 자세한 내용은 README.md 5장을 참고하세요.

echo '1. Installation'
python -m pip install pyserial numpy pyqtgraph PyOpenGL

echo '2. Self-test (하드웨어 없이 판정 로직 검증)'
python gtrack_clearance_demo/track_parser.py
python gtrack_clearance_demo/clearance_gtrack.py
python gtrack_clearance_demo/presence_monitor.py

echo '3. Run (터미널 3개에서 각각 실행, 포트 번호는 환경에 맞게 변경)'
echo '  python computer_GUI/digital_twin/server.py                      # 디지털 트윈 서버 (http://127.0.0.1:8766)'
echo '  python vital_signs/run_twin.py COM4 COM3 --no-serve             # 운전자 바이탈·각성도'
echo '  python gtrack_clearance_demo/main_presence_clearance.py         # 좌석 점유·폴딩 (기본 COM10 / COM11)'
