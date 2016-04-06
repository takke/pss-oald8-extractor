# OALD8 音声抽出スクリプト

本プログラムは、オックスフォード現代英英辞典 第８版（旺文社）（以下OALD8）に
付属のDVD-ROMの辞書から音声データを抽出し、英単語学習ソフト P-Study System で
利用するために転送する機能を備えています。


## 環境

開発時は下記のような環境で動作を確認しました。

- Windows 7 Professional (64bit)
- ActivePerl x86 5.14.4.1405 (*)
- PAR::Packer (*)

(*) は本ツール利用時には不要


## 使い方

 1. オックスフォード現代英英辞典 第８版 付属のDVD-ROMをインストールする
 2. OALD8 インストール先の設定を行う
   - OALD8 を標準以外の場所にインストールしている場合は、
     oald8_config.conf の先頭にある「OALD8のインストール先へのパス」を変更してください。
 3. 抽出スクリプトの実行
   - 下記コマンドを実行してください。
     (マシン性能によりますがおおむね1時間～数時間程度かかります)
```
extract_psssound.bat
```
 4. P-Study System 用にコピーする

   - 下記のコマンドを実行して 音声ファイルを P-Study System のディレクトリにコピーしてください。
```
copytopss.bat
```
   - 【注意】右クリックメニューから「管理者として実行」してください。
   - 【注意】Windows Vista以降の場合、標準ユーザ(一般ユーザ)では実行できません。
     管理者アカウントでログインしてください。
   - コピー完了 と表示されれば終了です。
 5. ファイル削除
   - 本スクリプトを展開したディレクトリは削除してかまいません。


## ライセンス
本プログラムのライセンスはGPL 2に従うこととします。


## ファイル構成

| ファイル | 説明 |
|--------|--------|
| README.md            | このファイル
| oald8_config.conf    | 設定ファイル
| extract_psssound.bat | 音声抽出バッチファイル(split_psssound.pl)
| copytopss.bat        | PSS用コピーバッチファイル(psstool.pl)
| split_psssound.pl    | 音声抽出スクリプト
| psstool.pl           | PSS用コピースクリプト
| caller.pl            | 各スクリプトをまとめて PAR 化する(※)ために一元的に呼び出すスクリプト
| caller.exe           | 各種Perlスクリプトのラッパー
| clean.bat            | 不要ファイル削除バッチ
| makepp.bat           | PAR::Packerによる*.exeの生成バッチ


## 謝辞

本スクリプトは隆さん作の「EPWING形式変換スクリプト for LDOCE5」(*1)の
音声抽出スクリプト split.pl をベースに作成しました。

同スクリプトは、takさん作成の ldoce5-fpw-20100111 (*2)を元に作成されています。

また、mp3のwav変換は、kazuhiroさんのoald7sound (*3) を参考に作成されています。

先駆者の方々に敬意を表します。

 - (*1) http://www.geocities.jp/taka_depo/
 - (*2) http://www.geocities.co.jp/tak492/
 - (*3) 
    - http://ikazuhiro.s206.xrea.com/staticpages/index.php/oald7-fpw
    - http://ikazuhiro.s206.xrea.com/article.php/200912261656263


## 更新履歴
 - 2016-04-06
    - github に配置
    - readme.txt を README.md に変換
 - 2013-04-26
    - LDOCE5対応版をベースにOALD8の音声抽出スクリプトを作成
