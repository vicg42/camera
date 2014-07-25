rem Ищем каталог core_gen и копируем из нее все файлы (*.ngc,*.mif ) в каталог проекта ISE(..\ise\prj)

cd d:\Work\Yansar\camera\ise\core_gen\
for /R  %%f in ( *.ngc *.mif) do xcopy "%%f" ..\prj /y

dir