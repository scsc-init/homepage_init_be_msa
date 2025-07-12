@echo off
for /f "tokens=*" %%b in ('git branch --show-current') do set branch=%%b
git push origin %branch%