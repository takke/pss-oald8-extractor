@cd /d %~dp0
@echo start (%date% %time%)...

caller.exe -calltype psstool

@echo done (%date% %time%).
pause
