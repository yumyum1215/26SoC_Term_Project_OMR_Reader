param(
    [string]$SdkRoot = 'C:/Xilinx/SDK/2019.1',
    [string]$HardwareDefinition = (Join-Path $PSScriptRoot 'OMR_state_change.sdk/system_wrapper.hdf')
)

$ErrorActionPreference = 'Stop'
$ArmBin = Join-Path $SdkRoot 'gnu/aarch32/nt/gcc-arm-none-eabi/bin'
$SdkTools = Join-Path $SdkRoot 'gnuwin/bin'
$App = Join-Path $PSScriptRoot 'OMR_state_change.sdk/OMR_state_change_app'
$Source = Join-Path $App 'src'
$Output = Join-Path $App 'Debug'
$Bsp = Join-Path $Output 'bsp'
$Processor = Join-Path $Bsp 'ps7_cortexa9_0'
$Elf = Join-Path $Output 'OMR_state_change_app.elf'

New-Item -ItemType Directory -Force $Output | Out-Null
$PathBeforeBuild = $env:Path
$PlatformBeforeBuild = $env:RDI_PLATFORM
try {
    $env:Path = "$SdkTools;$ArmBin;$PathBeforeBuild"
    $env:RDI_PLATFORM = 'win64'
    & (Join-Path $SdkRoot 'bin/xsct.bat') (Join-Path $PSScriptRoot 'build_bsp.tcl') $Bsp $HardwareDefinition
    if ($LASTEXITCODE -ne 0) { throw "BSP generation failed ($LASTEXITCODE)" }
    & (Join-Path $SdkTools 'make.exe') -C $Bsp
    if ($LASTEXITCODE -ne 0) { throw "BSP compilation failed ($LASTEXITCODE)" }

    $Args = @(
        '-mcpu=cortex-a9', '-mfpu=vfpv3', '-mfloat-abi=hard', "-specs=$Source/Xilinx.spec",
        '-Wall', '-Wextra', '-Werror', '-O2', "-I$Processor/include", "-L$Processor/lib",
        "-Wl,-T,$Source/lscript.ld", '-Wl,--build-id=none'
    )
    $Args += @(Get-ChildItem -LiteralPath $Source -Filter '*.c' | ForEach-Object FullName)
    $Args += @('-Wl,--start-group', '-lxilffs', '-lxil', '-lgcc', '-lc', '-Wl,--end-group', '-o', $Elf)
    & (Join-Path $ArmBin 'arm-none-eabi-gcc.exe') @Args
    if ($LASTEXITCODE -ne 0) { throw "ARM application compilation failed ($LASTEXITCODE)" }
    & (Join-Path $ArmBin 'arm-none-eabi-size.exe') $Elf
} finally {
    $env:Path = $PathBeforeBuild
    $env:RDI_PLATFORM = $PlatformBeforeBuild
}
