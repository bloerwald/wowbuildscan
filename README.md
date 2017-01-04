Example `config.inc`:

``` 
telegram_api=api_token
telegram_chat=channel
irc_account_PASS=$USER:myfirstownpassword
irc_nick=wowbuildcheck
irc_USER="aaron ignored ignored :Aaron"
irc_channel="#mudcraft"
irc_host=myfreebouncer.com
irc_port=5556
mail_receiver="$USER"

build_scan_dir="$HOME/wowbuildscan"
lua_casc_dir="${build_scan_dir}/luacasc"
output_dir="${build_scan_dir}/crawled"
cache_dir="${output_dir}/cache"

silent=true
``` 
