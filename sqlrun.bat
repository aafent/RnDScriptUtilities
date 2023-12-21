@echo off
rem ***********************************************
rem **** SQLRUN run many scripts                ***
rem ****                                        ***
rem **** Relational R&D Department              ***
rem **** Last modification: 2023-12-07          ***
rem ***********************************************
title SQLRUN run many scripts
cls
setlocal enableDelayedExpansion
rem enableextensions

rem Greedings
echo SQLRUN Utility v23.12.7
echo .

rem init. variables
set SCRIPTLIST=script-list.txt
set PARAMFILE=sqlrun-param.txt
set LOGFILE=log.txt
set PAUSE=N
set SERVER=
set DATABASE=
set USER=
set PASSWORD=
set CMD=
set BCPCODEPAGE=
set TMP=$$$.$$$



if [%1%]==[-run] set CMD=RUN& goto check
if [%1%]==[-export] set CMD=EXP& goto check
if [%1%]==[-import] set CMD=IMP& goto check
if [%1%]==[-test] set CMD=TST& goto check
if [%1%]==[-sqlfiles] set CMD=SQLFILES& goto check
if [%1%]==[-tablelist] set CMD=TABLIST& goto check
if [%1%]==[-snippet] set CMD=SNIPPET& goto check


rem create the necessary file and goto usage
if not exist "%SCRIPTLIST%" (
 copy /y NUL %SCRIPTLIST% >NUL 
    )
if not exist "%PARAMFILE%" (
 echo SERVER=host.domaim.com> %PARAMFILE%
 echo DATABASE=xxx>> %PARAMFILE%
 echo USER=uuu>> %PARAMFILE%
 echo PASSWORD=ppp>> %PARAMFILE%
 echo PAUSE=N>> %PARAMFILE%
 echo #BCPCODEPAGE=>> %PARAMFILE%
    )
goto usage


:check
echo Checking for the working environment...
if not exist "%SCRIPTLIST%" goto usage
if not exist "%PARAMFILE%" goto usage
echo Retrieving parameters from %PARAMFILE% file 

rem remove all the .$$$ files
del *.$$$ >nul 2>&1

for /f "eol=: tokens=1,2 delims==" %%a in ('find /v ":" ^< %PARAMFILE%  ') do (
    if "%%a"=="SERVER" set SERVER=%%b
	if "%%a"=="DATABASE" set DATABASE=%%b
	if "%%a"=="USER" set USER=%%b
	if "%%a"=="PASSWORD" set PASSWORD=%%b
	if "%%a"=="PAUSE" set PAUSE=%%b
	if "%%a"=="BCPCODEPAGE" set BCPCODEPAGE=-C %%b
)

set SSO=FALSE
if "%USER%%PASSWORD%"=="" set SSO=TRUE

if "%SERVER%"=="" echo ERROR: No server name defined & goto end
echo SERVER is: %SERVER%

if "%DATABASE%"=="" echo ERROR: No Database defined & goto end

if "%SSO%"=="TRUE" goto runsso

echo DATABASE is: %DATABASE%
if "%USER%"=="" echo ERROR: No user name defined & goto end

echo User name is: %USER%
if "%PASSWORD%"=="" echo WARNING: No password specified

:runsso
if "%SSO%"=="TRUE" echo Running windows authentication (SSO)
goto main

rem *********************************************************************
rem *********************************************************************
rem *********************************************************************

:main
echo BEGIN %CMD%: [%DATE% :: %TIME%]  > %LOGFILE%
echo . >> %LOGFILE%
set MYDIR=.
type %LOGFILE%

if "%CMD%"=="RUN" goto run
if "%CMD%"=="EXP" goto export
if "%CMD%"=="IMP" goto import
if "%CMD%"=="TST" goto end
if "%CMD%"=="SQLFILES" goto sqlfiles
if "%CMD%"=="TABLIST" goto tableslist
if "%CMD%"=="SNIPPET" goto snippets

echo ERROR: Wrong command (%CMD%)
goto exit-end

rem *********************************************************************
rem *********************************************************************
rem *********************************************************************
:snippets
set ARG2=%2%
set ARG3=%3%
set ARG4=%4%
if NOT [%3%]==[] goto snippetCreate
echo .
echo .
echo Usage of -snippet:
echo Syntax is: sqlrun -snippet snippet_type object_list file_name
echo    snippet_type :: drop ^| grantpublic 
echo    object_list  :: V,U,TR,P 
echo                    It is a comma seperated list of object types (U for user tables etc)
echo    file_name    :: if the script file name to create
goto end

:snippetCreate
echo Create a snippet


set list=%~ARG3

echo Objects: %list%
FOR /F "tokens=1* delims=;" %%a IN (!list!) do (
    echo X: %%a
	echo ..
 )


goto end

rem *********************************************************************
rem *********************************************************************
rem *********************************************************************

:tableslist
echo Creating file: %SCRIPTLIST% with all user table names of database: %DATABASE%
echo .
  echo use %DATABASE% > %TMP%
  echo go >> %TMP%
  echo set nocount on >> %TMP%
  echo go >> %TMP%
  echo select name from sysobjects where type='U' order by name >> %TMP%
  echo go >> %TMP%
  
  call :runscript %TMP% NUL %SCRIPTLIST%

echo done.
echo Now you can use the file: %SCRIPTLIST% as objects list (-import or -export)
echo IMPORTANT: Edit the script and remove headers from the top and empty lines at the bottom
goto end

rem *********************************************************************
rem *********************************************************************
rem *********************************************************************
:sqlfiles
echo Creating file: %SCRIPTLIST% with *.sql files of the current directory
echo .
dir /b /l *.sql | sort > %SCRIPTLIST%
echo done.
echo Now you can use the file: %SCRIPTLIST% as scripts list (-run)
goto end

rem *********************************************************************
rem *********************************************************************
rem *********************************************************************

:export
for /F "tokens=*" %%x in (%SCRIPTLIST%) do (
  echo NEXT TABLE IS: %%x
  echo NEXT TABLE IS: %%x >> %LOGFILE%
  call :bcp out %%x

  type %%x.$$$  >> %LOGFILE%
  echo LAST TABLE WAS: %%x
  echo LAST TABLE WAS: %%x >> %LOGFILE%
  echo . 
  echo .
) 
goto end

rem *********************************************************************
rem *********************************************************************
rem *********************************************************************

:import
for /F "tokens=*" %%x in (%SCRIPTLIST%) do (
  echo NEXT TABLE IS: %%x
  echo NEXT TABLE IS: %%x >> %LOGFILE%

  echo USE %DATABASE% > %TMP%
  echo GO >> %TMP%
  echo TRUNCATE TABLE %%x >> %TMP%
  echo GO >> %TMP%
  
  call :runscript %TMP% %LOGFILE%
  
  call :bcp in %%x
  type %%x.$$$  >> %LOGFILE%
   
  echo LAST TABLE WAS: %%x
  echo LAST TABLE WAS: %%x >> %LOGFILE%
  echo . 
  echo .
) 
goto end
rem *********************************************************************
rem *********************************************************************
rem *********************************************************************
:run 
for /F "tokens=*" %%x in (%SCRIPTLIST%) do (
  echo NEXT SCRIPT IS: %%x
  echo NEXT SCRIPT IS: %%x >> %LOGFILE%

  copy NUL %LOGFILE%.$$$ /A /Y > NUL
  call :runscript %%x %LOGFILE%.$$$
  
  type %LOGFILE%.$$$  >> %LOGFILE%
  type %LOGFILE%.$$$
  echo LAST SCRIPT WAS: %%x
  echo LAST SCRIPT WAS: %%x >> %LOGFILE%
  echo . 
  echo .
  echo .  >> %LOGFILE%
  echo .  >> %LOGFILE%
) 
goto endOfRun





:endOfRun
echo END: [%DATE% :: %TIME%]  >> %LOGFILE%
goto end

:usage
echo Usage:
echo Step A. Run command script without any arguments.
echo         This will create (if are missing) parameters, and file-list files
echo   	     Parameters file name: %PARAMFILE%
echo         DB objects or scripts list file name: %SCRIPTLIST%
echo Step B. Edit the parameters file 
echo Step C. Prepare the table-list file (one table per line)
echo         Example of how to create the script list: 
echo           for files:  dir /b /l *.sql | sort ^> %SCRIPTLIST%
echo           for tables: select name from sysobjects where type='U' order by name
echo               save the result to the file: %SCRIPTLIST%
echo Step D. Run the command script using the argument:
echo           -run        :: to run scripts
echo           -export     :: to import DATABASE
echo           -import     :: to import DATABASE
echo           -sqlfiles   :: to create %SCRIPTLIST% file with the *.sql files
echo           -tablelist  :: to create %SCRIPTLIST% file with all the table names
rem echo           -snippet    :: to create snipet script. Without 2nd parameter will give the snippet usage.

goto exit-end

:end
rem remove all the .$$$ files
del *.$$$ >nul 2>&1
if "%PAUSE%"=="Y" pause
exit /B 0


:exit-end
if "%PAUSE%"=="Y" pause
exit /B 1


rem *********************************************************************
rem *********************************************************************
rem *** SUBROUTINES                                                   ***
rem *********************************************************************
rem *********************************************************************
rem *********************************************************************

:bcp
rem 
rem Syntax: CALL :bcp in|out objectName  
rem
set operation=%~1
set obj=%~2

if "%SSO%"=="TRUE" (
bcp  %DATABASE%..%obj% %operation% %obj%.dat -T -S %SERVER% %BCPCODEPAGE% -e %obj%.$$$ -t "\t" -r "\n" -c 
) else (
bcp  %DATABASE%..%obj% %operation% %obj%.dat -U %USER% -P %PASSWORD% -S %SERVER% %BCPCODEPAGE% -e %obj%.$$$ -t "\t" -r "\n" -c
)
goto :EOF

rem *********************************************************************
rem *********************************************************************

:runscript
rem 
rem Syntax: CALL :runscript sqlScriptToRun logFileName [outputFileName]
rem      or CALL :runscript sqlScriptToRun NUL [outputFileName]
rem
set scriptfilename=%~1
set logfilename=%~2
set outfilename=%~3
if not "%outfilename%"=="" set outfilename=-o %outfilename%

if "%SSO%"=="TRUE" (
sqlcmd -S %SERVER% -d %DATABASE%  -i %scriptfilename% %outfilename% -W >> %logfilename%
) else (
sqlcmd -S %SERVER% -U %USER% -P %PASSWORD% -d %DATABASE%  -i %scriptfilename% %outfilename% -W >> %logfilename%
) 
goto :EOF

rem *********************************************************************
rem *********************************************************************



