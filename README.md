# sendmail_conv
A wrapper of sendmail with transcoding

Asterisk の voicemail.conf の mailcmd に指定するための sendmail のラッパーです。
デフォルトでは
mailcmd=/usr/sbin/sendmail -t
が設定されているところを、sendmail_conv.sh に変更してメールを送信します。
添付データがWAVである場合、それをm4aに変換して送信します。

wavではサイズが無駄に大きいし、wav47ではメーラーが再生してくれないので、m4aに変換します。

最初のバージョンは
https://gist.github.com/dougbtv/3d820a597347396a6e8d
からのフォークです。
