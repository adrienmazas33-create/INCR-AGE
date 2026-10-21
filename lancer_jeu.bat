@echo off
rem Lance le prototype. Ajouter "editeur" en argument pour ouvrir l'éditeur Godot à la place.
setlocal
set "GODOT="
for /d %%d in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_*") do (
	for %%f in ("%%d\Godot_v4*_win64.exe") do set "GODOT=%%f"
)
if not defined GODOT (
	where godot >nul 2>nul && set "GODOT=godot"
)
if not defined GODOT (
	echo Godot 4 introuvable. Installer avec : winget install GodotEngine.GodotEngine
	pause
	exit /b 1
)
rem Premier lancement : import des ressources (dossier .godot absent, il n'est pas versionné).
if not exist "%~dp0.godot\imported" "%GODOT%" --headless --path "%~dp0." --import
if /i "%~1"=="editeur" (
	start "" "%GODOT%" --path "%~dp0." -e
) else (
	start "" "%GODOT%" --path "%~dp0."
)
