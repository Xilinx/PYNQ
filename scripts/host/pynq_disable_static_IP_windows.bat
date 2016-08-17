::   Copyright (c) 2016, Xilinx, Inc.
::   All rights reserved.
:: 
::   Redistribution and use in source and binary forms, with or without 
::   modification, are permitted provided that the following conditions are met:
::
::   1.  Redistributions of source code must retain the above copyright notice, 
::       this list of conditions and the following disclaimer.
::
::   2.  Redistributions in binary form must reproduce the above copyright 
::       notice, this list of conditions and the following disclaimer in the 
::       documentation and/or other materials provided with the distribution.
::
::   3.  Neither the name of the copyright holder nor the names of its 
::       contributors may be used to endorse or promote products derived from 
::       this software without specific prior written permission.
::
::   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
::   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
::   THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
::   PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR 
::   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
::   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
::   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
::   OR BUSINESS INTERRUPTION). HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
::   WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
::   OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
::   ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
::
:: DESCRIPTION
:: This script reverts LAN cable to use to a DHCP config
::

@echo off

echo.
echo.
echo  Pynq - Restoring DHCP Configuration    
echo.


rem Checking for Admin Privileges
AT > NUL
IF %ERRORLEVEL% EQU 0 (
  echo.
) ELSE (
  ECHO Please "Run as administrator"
  echo    this is required to change LAN settings
pause
exit /b 1
)





netsh interface ipv4 show interfaces

echo enter the idx of the LAN from list above
set /p idx="Enter idx: "



echo.
echo #############################
echo # Previous Network Settings #
echo #############################
echo.
netsh interface ip show address %idx%

echo Setting DHCP IP and flushing DNS
netsh interface ip set address %idx% source=dhcp   		       
call cmd /c ipconfig /flushdns

echo   Finished... will now display new settings (after short wait)

rem Waiting some time so network configuration can propagate
ping 127.0.0.1 -n 10 -w 1000 > nul
echo ########################
echo # New network settings #
echo ########################
echo.
netsh interface ip show address %idx%
pause
