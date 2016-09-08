#!/bin/sh

echo '
[*] Usage: '$0 '<RET>
[!] 如果hosts未生效，请在路由器插件管理页面手动使用自定义hosts插件提交修改
[*] 请查看/var/log/hosts.log中的debug信息
'

# tests if a cron job has been created already
grep "hosts" /etc/crontabs/root > /dev/null
if [ $? -eq 1 ]; then
    echo `date`": [-] cron job not found" >> /var/log/hosts.log
    echo "*/30 * * * * /etc/hosts.sh" >> /etc/crontabs/root # check for update every 30 min
else
    echo `date`": [+] cron job okay" >> /var/log/hosts.log
fi

# fetch hosts file from github
curl -k -o /tmp/hosts "https://raw.githubusercontent.com/racaljk/hosts/master/hosts"

# append hosts record to a recognized file (if there is an update available)
grep $(date +%Y-%m-%d) /tmp/hosts > /dev/null
if [ $? -eq 1 ]; then
    echo `date`": [-] update not found" >> /var/log/hosts.log # no update
else
    echo `date`": [+] update available" >> /var/log/hosts.log # update available, check if we have it installed already
    grep $(date +%Y-%m-%d) /etc/hosts.d/openapi > /dev/null
    if  [ $? -eq 1 ]; then
        echo `date`": [+] updating..." >> /var/log/hosts.log
        echo "192.168.199.1 client.openapi.hiwifi.com" > /etc/hosts.d/openapi # backup
        cat /tmp/hosts >> /etc/hosts.d/openapi # append new hosts
        /etc/rc.d/S99custmdns restart # restart custom_dns plugin (to restart dnsmasq while preventing deleting our new hosts file)
    fi
fi

# auto start
if ! test -e /etc/hosts.sh; then
    cp  $0 /etc/ && chmod 755 /etc/hosts.sh
    echo `date`": [-] /etc/hosts.sh not found" >> /var/log/hosts.log
else
    echo `date`": [+] /etc/hosts.sh okay" >> /var/log/hosts.log
fi
grep "hosts" /etc/rc.local > /dev/null
if [ $? -eq 1  ]; then
    echo `date`": [-] Auto start not found" >> /var/log/hosts.log
    echo "sh /etc/"$0 > /etc/rc.local && echo "exit 0" >> /etc/rc.local
else
    echo `date`": [+] Auto start okay" >> /var/log/hosts.log
fi
