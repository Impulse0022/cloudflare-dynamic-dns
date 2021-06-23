# Cloudflare Dynamic DNS Script
A dynamic DNS updater for use with the Cloudflare API v4

-----

This scripts updates a DNS A record hosted by Cloudflare with your current IP address via the Cloudflare API v4. Also allows you to leverage the Cloudflare "proxied" feature when doing so.

You will need to generate a Cloudflare API Token with Edit DNS Zone permissions.

This script is dependant on the following executables:
`bash`, `curl`,`jq`

Usage
-----
__cloudflare-ddns.bash__ \[-z Zone\] \[-r DNS Record\] \[-t Token\] \[-p Proxy (true/false)\]

The options are as follows:
>__-z__ *Zone*
>> The Cloudflare zone that holds the record

>__-r__ *Record*
>> The Cloudflare DNS A record that will be updated

>__-t__ *Token*
>> Your Cloudflare API Token. Remember token must have Edit Zone DNS authority.

>__-p__ *Proxy (true/false)*
>> Specifies if Cloudflare proxy should be used when updating the DNS A record

Cron
----
You can easily add this to your crontab with an entry like:
```
0 * * * * /path/to/cloudflare-ddns.bash -z ZONE -r RECORD -t TOKEN -p true/false
```
