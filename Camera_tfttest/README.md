# OV5640 → TFT-LCD 미리보기

RPS-Z7020-TK의 OV5640 카메라와 480×272 TFT를 확인하는 Vivado 2019.1 예제다.
PL에서 카메라 초기화, RGB565 캡처, BRAM 저장, TFT 출력을 처리한다.

## 보드에서 실행

1. 보드 전원을 끈 상태에서 실습용 OV5640 모듈을 CAMERA1에 연결하고 TFT를 연결한다.
2. 보드를 켜고 Vivado Hardware Manager에서 Open Target → Auto Connect를 선택한다.
3. Program Device에서 이 폴더의 `camera_tfttest.bit`를 선택해 다운로드한다.
4. 카메라가 초기화되고 프레임을 수신하면 TFT의 파란 화면이 라이브 영상으로 바뀐다.

라이브 영상 테스트에는 위 비트스트림 하나만 사용한다.

## 다시 빌드

이 폴더에서 PowerShell로 실행한다.

```powershell
& C:/Xilinx/Vivado/2019.1/bin/vivado.bat -mode batch -source build.tcl
& C:/Xilinx/Vivado/2019.1/bin/vivado.bat -mode batch -source build.tcl -tclargs bars
```

일반 빌드는 `build_upright/camera_tfttest.xpr`와 `camera_tfttest.bit`를 만든다.
색 막대 빌드는 `build_bars/camera_tfttest.xpr`와 `tft_color_bars.bit`를 만든다.

## 영상 경로

- 실습 자료 `Education.zip`의 `1_End/ch13_pl_cis`에서 카메라 초기화 VHDL과 핀 매핑을 가져왔다. 핀 매핑은 CAMERA1과 TFT에 해당한다.
- OV5640 초기화 ROM이 설정하는 영상은 640×480이다. 센서 출력의 센서의 좌우 반전을 끄고 중앙 480×272 영역을 잘라 TFT에 표시한다.
- 카메라는 PCLK에 맞춰 DVP 데이터의 상위·하위 바이트를 받아 RGB565 픽셀을 만든다. M19의 25 MHz를 MMCM으로 50 MHz로 변환하고, 12.5 MHz TFT 픽셀 클록을 만든다. TFT는 이 타이밍으로 같은 BRAM을 읽고, 실습 예제와 같은 순서로 빨강과 파랑 채널을 교환해 출력한다.
- 미리보기는 단일 프레임 버퍼를 사용하므로 움직이는 장면에서는 프레임 경계가 한 화면에 섞일 수 있다.
