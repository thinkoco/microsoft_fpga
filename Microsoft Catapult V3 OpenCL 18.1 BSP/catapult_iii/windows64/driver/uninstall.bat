@echo +------------------------------------------------------+
@echo + Performing initial checks...                         +
@echo +------------------------------------------------------+
@echo.
@for /f %%a in ('aocl board-name') do set board_name=%%a
@set inf_basename=acl_boards_%board_name%
@if exist "%inf_basename%.inf" goto after_check
@echo "Failed to find %inf_basename%.inf"
@echo "  Your BSP is incomplete, please create %inf_basename%.inf"
@echo "  using aclboars.inf as reference.  Ensure the DeviceList's are"
@echo "  configured with your hardware IDs and board_name"
@set errorlevel=2
@pause
@exit /B %errorlevel%
:after_check

@echo +------------------------------------------------------+
@echo + Uninstalling board drivers...                          +
@echo +------------------------------------------------------+
@echo.
@wdreg -delete_files -log uninstall_%inf_basename%.log -inf %inf_basename%.inf uninstall
@if not %errorlevel%==0 exit /B %errorlevel%
@echo +------------------------------------------------------+
@echo + Uninstalling kernel driver module...                   +
@echo +------------------------------------------------------+
@echo.
@wdreg -delete_files -log uninstall_windrvr6.log -inf windrvr6.inf uninstall
@if not %errorlevel%==0 exit /B %errorlevel%
@echo.
@pause
