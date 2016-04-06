@cd /d %~dp0
@echo start (%date% %time%)...

caller.exe -calltype split_psssound

@echo done (%date% %time%).
pause
