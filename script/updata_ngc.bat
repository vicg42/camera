rem ���� ������� core_gen � �������� �� ��� ��� ����� (*.ngc,*.mif ) � ������� ������� ISE(..\ise\prj)

cd d:\Work\Yansar\camera\ise\core_gen\
for /R  %%f in ( *.ngc *.mif) do xcopy "%%f" ..\ise\prj /y

dir