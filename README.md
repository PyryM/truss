# truss
successor to plinth

Miscellaneous tips:

Compiling dx11 shaders:
shaderc -f source_fs_file.sc -o output_fs_file.bin --type f -i common\ --platform windows -p ps_4_0 -O 3
For vertex shader change ps_4_0 to vs_4_0
(for dx9 use ps_3_0 and vs_3_0)