# vitaliygut_infra
vitaliygut Infra repository

HW3
=========================================
bastion = 178.154.227.202
someinternalhost = 10.130.0.14

Cпособ подключения к someinternalhost в одну команду

ssh -t -i ~/.ssh/key -A appuser@public_ip_bastion 'ssh ip_someinternalhost'


Подключение из консоли при помощи команды вида ssh someinternalhost:


Host *
ForwardAgent yes

	Host bastion
	IdentityFile ~/.ssh/key
	HostName ip_bastion
	User appuser

        Host someinternalhost
        IdentityFile ~/.ssh/key
        HostName ip_someinternalhost
        User appuser
	ProxyJump bastion

После запуска vpn сервера в логах были ошибки связанные с неудачной попыткой добыить правила в iptables, дополнително установил iptable и рестрарт службы pritunl
SSL

В настройках сервера указал домен  pritunl.178.154.227.202.sslip.io
