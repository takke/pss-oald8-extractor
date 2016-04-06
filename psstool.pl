#!/usr/bin/perl

use strict;

use Win32::Registry;
use File::Copy;


#
# P-Study System のインストール先取得
#
my $reg = $HKEY_CURRENT_USER;
my $key = "Software\\Halts Presents\\PSS7\\settings\\1";
my $item;
$reg->Open($key, $item)
  or die "P-Study Systemのインストール先が不明です(1)。現在ログインしているユーザで P-Study System がインストールされていることを確認してください";

my $type;
my $wavvoice_folder;
$item->QueryValueEx("wav-voice-folder", $type, $wavvoice_folder)
  or die "P-Study Systemのインストール先が不明です(2)";
# "C:\Documents and Settings\xxx\My Documents\P-Study System\wavvoice"

print "P-Study System wavvoice フォルダ: [${wavvoice_folder}]\n";

#
# コピー
#

# コピー先パス生成
my $dest_path = $wavvoice_folder . "\\OALD8";

if (-d $dest_path) {
  print "$dest_path が既に存在します\n";
} else {
  mkdir $dest_path or die "$dest_path を作成することができません。 : $!";
  print "$dest_path を作成しました\n"
}

my @dirs = ("sound-uk", "sound-us");
foreach my $dir (@dirs) {
  print "▼${dir} のコピー\n";

  copy "${dir}_tag.txt", $dest_path;

  my $dest_dir = "${dest_path}\\${dir}";
  if (!-d $dest_dir) {
    mkdir $dest_dir or die "$dest_dir を作成することができません。 : $!";
  }

  my @files = glob "${dir}\\*.wav";
  my $count = $#files +1;
  for (my $i=0; $i<$count; $i++) {
    my $file = $files[$i];
    
    my $n = $i+1;
    if ($n % 10 == 0 || $n==$count) {
        my $mini_name = substr($file, 0, 35);
        printf("%-78s\r", "[$n/$count:$mini_name]");
    }
    
    if (!-e "$dest_path\\$file") {
      copy $file, $dest_dir;
    }
  }
  printf("%-78s\r", "");
  print "\n";
}

print "【コピー完了】\n";
