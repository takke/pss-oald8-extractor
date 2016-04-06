echo caller.exe
call pp -o caller.exe ^
   -M English ^
   -M FileHandle ^
   -M Compress::Raw::Zlib ^
   -M Win32::Registry ^
   -M File::Copy ^
   caller.pl
