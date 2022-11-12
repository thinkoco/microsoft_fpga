@echo +------------------------------------------------------+
@echo + Performing initial checks...                         +
@echo +------------------------------------------------------+
@echo.
@for /f %%a in ('aocl board-name') do set board_name=%%a
@set inf_basename=acl_boards_%board_name%
@if exist "%inf_basename%.inf" goto after_check
@echo "Failed to find %inf_basename%.inf"
@echo "  Your BSP is incomplete, please create %inf_basename%.inf"
@echo "  using aclboards.inf as reference.  Ensure the DeviceList's are"
@echo "  configured with your full hardware IDs to avoid aliasing"
@echo "  with other BSPs."
@set errorlevel=2
@pause
@exit /B %errorlevel%
:after_check

@echo +------------------------------------------------------+
@echo + Installing kernel driver module...                   +
@echo +------------------------------------------------------+
@echo.
@wdreg -log install_windrvr6.log -inf windrvr6.inf install
@if not %errorlevel%==0 exit /B %errorlevel%
@echo.
@echo +------------------------------------------------------+
@echo + Installing board drivers...                          +
@echo +------------------------------------------------------+
@echo.
@wdreg -log install_%inf_basename%.log -inf %inf_basename%.inf install
@if not %errorlevel%==0 exit /B %errorlevel%
@echo.
@echo +------------------------------------------------------+
@echo + ****** SUCCESS!            +
@echo +------------------------------------------------------+
@pause

