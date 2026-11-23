# RPS-Z7020-TK 양면 OMR

Vivado 2019.1과 Xilinx SDK 2019.1로 빌드한다. 카메라는 실습용 OV5640 모듈을 CAMERA1 커넥터에 연결한다. 카메라 초기화용 VHDL은 실습 자료 `Education.zip`의 `1_End/ch13_pl_cis`에서 가져왔다.

## 빌드와 준비

```powershell
vivado -mode batch -source .\OMR_state_change\build_servo.tcl
.\OMR_state_change\build_sdk.ps1
```

- Vivado는 `OMR_state_change.runs/impl_1/system_wrapper.bit`와 `OMR_state_change.sdk/system_wrapper.hdf`를 생성한다.
- SDK 스크립트는 `OMR_state_change.sdk/OMR_state_change_app/Debug/OMR_state_change_app.elf`를 생성한다. JTAG에서 HDF로 PS 초기화를 수행하고, 해당 비트스트림과 ELF를 같은 세션에서 실행한다.
- FAT32 SD 카드 루트에 공통 과목코드 위치를 담은 `KEY.TXT`와 과목별 `KEY01.TXT`~`KEY06.TXT` 중 사용할 파일을 넣는다. 예를 들어 코드 `02`는 `KEY02.TXT`를 읽는다.
- UART 115200, 8N1에서 `TOTAL 30`과 `ID 20221139 HYEONSEO` 같은 명령을 보낸다. 학번은 숫자 1~8자리, 이름은 ASCII 1~32자다.

## 조작 순서

[실제 OMR 카드 사진과 판독 영역](../docs/omr-card.md)

1. 검은 막대가 위로 오도록 OMR 앞면을 어두운 무광 배경 위에 놓고, 카드 전체를 TFT 네모 가이드 안에 맞춘다.
2. 가이드가 초록색이고 `READY - PRESS 1`이 표시되면 1번 버튼(PB0)을 누른다. 앞면의 과목코드 두 자리를 읽고 해당 정답 파일을 연다. 유효한 정답지를 읽고 객관식을 판독하면 서보에 뒷면 위치 명령을 보낸다.
3. 안정화 후 뒷면이 다시 가이드 안으로 들어오도록 정렬한다. `READY - PRESS 2`가 표시된 뒤 2번 버튼(PB1)을 눌러 뒷면을 촬영한다. 뒷면 대기 중 4번 버튼(PB3)으로 취소할 수 있다.
4. IDLE에서 3번 버튼(PB2)은 집계, 4번 버튼(PB3)은 새 회차 시작이다. 완료 기록은 `R0000001/<학번>/FRONT.BMP`, `BACK.BMP`, `RESULT.TXT`에 저장한다. 모호한 판독은 `REVIEW.TXT`에 기록하고 인원 집계에서 제외한다.

## SD 카드 정답지

| 코드 | 과목 | SD 카드 정답 파일 |
| --- | --- | --- |
| `01` | 국어 | `KEY01.TXT` |
| `02` | 수학 | `KEY02.TXT` |
| `03` | 영어 | `KEY03.TXT` |
| `04` | 한국사 | `KEY04.TXT` |
| `05` | 통합과학 | `KEY05.TXT` |
| `06` | 통합사회 | `KEY06.TXT` |

`KEY.TXT`에는 과목코드 0행 위치와 행 간격을 천분율로 적는다. 기본값은 `4200 1220`이다. 기존 `KEY.example.txt`를 공통 `KEY.TXT`로 복사해도 첫 두 숫자만 사용한다.

`KEY.example.txt`를 사용할 과목코드에 맞춰 `KEY02.TXT` 같은 이름으로 한 번 더 복사하고, 아래 형식대로 과목별 정답을 설정한다. 두 자리 파일명을 사용한다. 과목 파일은 앞면을 촬영할 때마다 읽으며, 로드한 설정은 뒷면 채점까지 적용된다. 과목코드가 비어 있거나 복수로 마킹됐거나 코드가 `01`~`06` 범위 밖이거나 파일이 없거나 손상됐으면 뒤집기 전에 오류를 표시한다. `RESULT.TXT`와 `REVIEW.TXT`에 `SUBJECT=02` 형태로 저장한다.

### 과목별 `KEYnn.TXT` 형식

| 줄 | 값 |
| --- | --- |
| 1 | 앞면 첫 행 오프셋과 행 간격. 검은 막대 피치의 천분율 |
| 2, 3 | 뒷면 두 답란의 `left top right bottom`. 480×272 좌표로, 답란 테두리를 피한 내부 좌표. right와 bottom은 제외 |
| 4 | 객관식 10개와 주관식 2개의 정답 |
| 5 | 같은 순서의 배점 12개 |

앞면 기본값은 제공된 카드 사진에서 구했다. 객관식은 사진의 상단 검은 막대 27개 중 8~12번째에 해당하는 1~10번 구역을 읽는다. 뒷면 예시 좌표는 사진의 왼쪽 답란 첫째 줄과 둘째 줄을 기준으로 잡았다. 실제 촬영 프레임에서 맞춰야 할 영역은 [뒷면 답란 사진](../docs/omr-card.md#뒷면-주관식-답란)을 참고한다. 주관식은 ARM에서 정수 CNN을 실행한다. 모델 학습 코드는 `OMR_state_change/train_digits.py`에 있으며 [UCI Optdigits](https://doi.org/10.24432/C50P49) 학습·시험 데이터를 사용한다.

서보는 J14 14번(GPIO6, P20)에 PWM을 출력한다. J14 13번과 서보 전원 GND를 공유한다. 앞면 1400 µs, 뒷면 1600 µs, 안정화 800 ms는 시험용 초기값이다. 서보를 연결하지 않고 손으로 뒤집어 나머지 흐름을 검증할 수 있다.
