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
:: This script sets up LAN cable for use with static IP over a  
:: patch/crossover cable
::

@echo off

echo.
echo.
echo #############################
echo # Pynq - Setting Static IP  #
echo #                           #
echo # Network Configuration     #
echo #############################
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


echo  *** Your network LAN port will be configured for use with a static IP.  ***
echo     This configuration will change your LAN port to a static IP compatible 
echo     with Pynq's Static IP configuration.  
echo.
echo  To revert your LAN port to DHCP settings, please doubleclick 
echo     pynq_disable_static_ip.bat
echo.
echo  If you have non-DHCP LAN settings, please record your settings and 
echo.    manually revert back after static IP use through Windows network manager
echo.
echo  You can cancel by exitting this window.
echo.
pause
echo.
echo.







echo.
echo #############################
echo # Previous Network Settings #
echo #############################
echo.
netsh interface ip show address "Local Area Connection"

echo Setting static IP
call cmd /c netsh interface ip set address name="Local Area Connection" source=static address=192.168.2.98 mask=255.255.255.0 gateway=192.168.2.97
echo   Finished... will now test new network interface (after short wait)
echo.

rem Waiting some time so network configuration can propagate
ping 127.0.0.1 -n 8 -w 1000 > nul
echo ########################
echo # New network settings #
echo ########################
echo.
netsh interface ip show address "Local Area Connection"


echo ########################################
echo # Checking if can communicate to board # 
echo ######################################## 
echo.
echo   if board is turned off or unconnected
echo     the following pings will be answered by Pynq platform
echo.




ping 192.168.2.99

echo.
echo.


pause


