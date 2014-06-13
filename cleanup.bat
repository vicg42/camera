rem call D:\Work\Linkos\veresk_m\common\script\glob_cleanup.bat
rem // Ищу везде каталог core_gen и удаляю в нем следующие каталоги:
for /R  %%f in ( core_gen\doc core_gen\implement core_gen\simulation ) do rmdir /s /q "%%f"

rem // Ищу везде каталог core_gen и удаляю в нем следующие файлы:
for /R  %%f in ( core_gen\*.prj core_gen\*.xise core_gen\*.ise core_gen\*.gise core_gen\*.asy core_gen\*.vho core_gen\*.tcl core_gen\*.txt core_gen\*.pdf core_gen\*.veo core_gen\*.lso core_gen\*.xrpt ) do del "%%f"

rem // Ищу везде каталог core_gen\core_pciexp_ep_blk_plus и удаляю в нем следующие файлы и каталоги:
for /R  %%f in ( core_gen\core_pciexp_ep_blk_plus\doc core_gen\core_pciexp_ep_blk_plus\example_design  core_gen\core_pciexp_ep_blk_plus\simulation  core_gen\core_pciexp_ep_blk_plus\implement) do rmdir /s /q "%%f"
for /R  %%f in ( core_gen\core_pciexp_ep_blk_plus\*.txt ) do del "%%f"

rem // Ищу везде каталог core_gen\emac и удаляю в нем следующие файлы и каталоги:
for /R  %%f in ( core_gen\emac_core\doc core_gen\emac_core\simulation  core_gen\emac_core\implement) do rmdir /s /q "%%f"
for /R  %%f in ( core_gen\emac_core\*.txt ) do del "%%f"

rem // Ищу везде каталог core_gen\emac_core_rgmii и удаляю в нем следующие файлы и каталоги:
for /R  %%f in ( core_gen\emac_core_rgmii\doc core_gen\emac_core_rgmii\simulation  core_gen\emac_core_rgmii\implement) do rmdir /s /q "%%f"
for /R  %%f in ( core_gen\emac_core_rgmii\*.txt ) do del "%%f"

rem // Ищу везде каталог core_gen\mem_achcount3 и удаляю в нем следующие файлы и каталоги:
for /R  %%f in ( core_gen\mem_achcount3\doc core_gen\mem_achcount3\simulation  core_gen\mem_achcount3\implement) do rmdir /s /q "%%f"
for /R  %%f in ( core_gen\mem_achcount3\*.txt ) do del "%%f"

rem // Ищу везде каталог core_gen\mem_achcount4 и удаляю в нем следующие файлы и каталоги:
for /R  %%f in ( core_gen\mem_achcount4\doc core_gen\mem_achcount4\simulation  core_gen\mem_achcount4\implement) do rmdir /s /q "%%f"
for /R  %%f in ( core_gen\mem_achcount4\*.txt ) do del "%%f"

rem // Ищу везде каталог core_gen\mem_ctrl_core_axi и удаляю в нем следующие файлы и каталоги:
for /R  %%f in ( core_gen\mem_ctrl_core_axi\docs core_gen\mem_ctrl_core_axi\simulation  core_gen\mem_ctrl_core_axi\implement) do rmdir /s /q "%%f"
for /R  %%f in ( core_gen\mem_ctrl_core_axi\*.txt ) do del "%%f"

rem // Ищу везде каталог matlab и удаляю в нем следующие файлы:
for /R  %%f in ( matlab\*.asv ) do del "%%f"


rem // Ищу везде каталог mscript и удаляю в нем следующие каталоги:
for /R  %%f in ( mscript\work mscript\plxsim ) do rmdir /s /q "%%f"

rem // Ищу везде каталог mscript и удаляю в нем следующие файлы:
for /R  %%f in ( mscript\tcl_stacktrace.txt mscript\*.bmm mscript\*.vstf mscript\*.wlf ) do del "%%f"

rem // Удаляю во всех подкаталогах следующие файлы
del /s /q AlphaData_Session.log
del /s /q _impactbatch.log