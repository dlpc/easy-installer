firewall-cmd --get-active-zones

firewall-cmd --permanent --zone=public --add-port 80/tcp

firewall-cmd --reload

firewall-cmd --list-all
