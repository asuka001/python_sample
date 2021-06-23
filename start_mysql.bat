@echo off

@rem 変数
set DRIVE=D:
set FOLDER=D:\mysql\bin

@rem 対象フォルダに移動
%DRIVE%
cd %FOLDER%

@rem Mysql起動
mysqld --defaults-file="D:\mysql\my.ini" --console

pause