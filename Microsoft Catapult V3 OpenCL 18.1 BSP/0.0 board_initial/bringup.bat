@ REM ######################################
@ REM # Variable to ignore <CR> in DOS
@ REM # line endings
@ set SHELLOPTS=igncr

@ REM ######################################
@ REM # Variable to ignore mixed paths
@ REM # i.e. G:/$SOPC_KIT_NIOS2/bin
@ set CYGWIN=nodosfilewarning

 set project.sof=top.sof
 set project.jic=top.jic
 set device_sfl.sof=Catapult_v3_sfl.sof
 
@set QUARTUS_BIN=%QUARTUS_ROOTDIR%\\bin
@if exist %QUARTUS_BIN%\\quartus_pgm.exe (goto DownLoad)

@set QUARTUS_BIN=%QUARTUS_ROOTDIR%\\bin64
@if exist %QUARTUS_BIN%\\quartus_pgm.exe (goto DownLoad)

:: Prepare for future use (if exes are in bin32)
@set QUARTUS_BIN=%QUARTUS_ROOTDIR%\\bin32

:DownLoad
%QUARTUS_BIN%\\quartus_cpf -c -d EPCQL1024 -s 10AXF40AA -m ASx4 %project.sof% %project.jic%
%QUARTUS_BIN%\\quartus_pgm.exe -m jtag -c 1 -o "p;%device_sfl.sof%"
%QUARTUS_BIN%\\quartus_pgm.exe -m jtag -c 1 -o "p;%project.jic%"
pause
