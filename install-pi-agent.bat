@echo off
setlocal

echo ============================================
echo Instalacion de pi-coding-agent
echo ============================================

rem Directorio donde vive este script (contiene settings.json, mcp.json,
rem auth.json, skills\ y wireshark-mcp-install.bat de referencia).
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
rem Version con backslashes escapados para insertar en JSON.
set "SCRIPT_DIR_JSON=%SCRIPT_DIR:\=\\%"

set "PI_DIR=%USERPROFILE%\.pi"
set "PI_AGENT_DIR=%PI_DIR%\agent"
set "SKILLS_SRC=%SCRIPT_DIR%\skills"
set "SKILLS_DST=%PI_AGENT_DIR%\skills"
set "WIRESHARK_DIR=%SCRIPT_DIR%\wireshark-mcp"

echo.
echo [1/6] Instalando @earendil-works/pi-coding-agent (npm, --ignore-scripts)...
call npm install -g --ignore-scripts @earendil-works/pi-coding-agent
if errorlevel 1 (
    echo ERROR: fallo la instalacion de pi-coding-agent via npm.
    exit /b 1
)

echo.
echo [2/6] Instalando pi-mcp-adapter (declarado en settings.json, npm, --ignore-scripts)...
call npm install -g --ignore-scripts pi-mcp-adapter
if errorlevel 1 (
    echo ERROR: fallo la instalacion de pi-mcp-adapter via npm.
    exit /b 1
)

echo.
echo [3/6] Creando estructura en "%PI_AGENT_DIR%"...
if not exist "%PI_DIR%" mkdir "%PI_DIR%"
if not exist "%PI_AGENT_DIR%" mkdir "%PI_AGENT_DIR%"
if not exist "%SKILLS_DST%" mkdir "%SKILLS_DST%"

echo.
echo [4/6] Copiando skills desde "%SKILLS_SRC%" a "%SKILLS_DST%"...
if exist "%SKILLS_SRC%" (
    xcopy "%SKILLS_SRC%" "%SKILLS_DST%" /E /I /Y >nul
    if errorlevel 1 (
        echo ERROR: fallo la copia de skills.
        exit /b 1
    )
) else (
    echo AVISO: no se encontro la carpeta de skills en "%SKILLS_SRC%".
)

echo.
echo [5/6] Escribiendo settings.json, auth.json y mcp.json en "%PI_AGENT_DIR%"...

copy /Y "%SCRIPT_DIR%\settings.json" "%PI_AGENT_DIR%\settings.json" >nul
copy /Y "%SCRIPT_DIR%\auth.json" "%PI_AGENT_DIR%\auth.json" >nul

rem mcp.json es una plantilla con el placeholder {{WIRESHARK_PYTHON}}; se
rem sustituye aqui por la ruta real (dependiente del usuario/ubicacion
rem actual) antes de escribirlo en el destino, para no dejar hardcodeada
rem la ruta de quien genero originalmente el archivo.
set "WIRESHARK_PYTHON_JSON=%SCRIPT_DIR_JSON%\\wireshark-mcp\\.venv\\Scripts\\python.exe"
powershell -NoProfile -Command "(Get-Content -Raw -LiteralPath '%SCRIPT_DIR%\mcp.json') -replace '\{\{WIRESHARK_PYTHON\}\}', '%WIRESHARK_PYTHON_JSON%' | Set-Content -NoNewline -LiteralPath '%PI_AGENT_DIR%\mcp.json'"
if errorlevel 1 (
    echo ERROR: fallo la generacion de mcp.json.
    exit /b 1
)

echo.
echo [6/6] Desplegando el MCP de wireshark en "%WIRESHARK_DIR%"...
if not exist "%WIRESHARK_DIR%" mkdir "%WIRESHARK_DIR%"
pushd "%WIRESHARK_DIR%"

python -m venv .venv
if errorlevel 1 (
    echo ERROR: fallo la creacion del entorno virtual de Python.
    popd
    exit /b 1
)

call .venv\Scripts\activate.bat
pip install wireshark-mcp
if errorlevel 1 (
    echo ERROR: fallo "pip install wireshark-mcp".
    popd
    exit /b 1
)

popd

echo.
echo ============================================
echo Instalacion completada.
echo   - Config pi:      %PI_AGENT_DIR%
echo   - Skills:         %SKILLS_DST%
echo   - Wireshark MCP:  %WIRESHARK_DIR%
echo ============================================

endlocal
