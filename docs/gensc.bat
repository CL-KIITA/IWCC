@echo off
cd script
rem dart compile js dinamic.dart -o dinamic.dt.js
for %%f in (*.e.dart) do (
  echo;
  echo %%~nf.dart to %%~nf.dt.js
  echo;
  dart compile js %%~nf.dart -o %%~nf.dt.js
  echo;
)