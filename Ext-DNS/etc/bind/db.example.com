;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;Shortcuts and the zone name
;   The zone name defined by the reference to this file from named.conf.local 
;     is really important. In this case it is 'cyber.test'
;   * Where there is no trailing '.' (eg 'm1' NOT 'm1.') then the zone name 
;     is appended to the name so 'm1' becomes 'm1.cyber.test'
;   * The '@' symbol represents the the zone name
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TTL	8h
@	IN	SOA     Ext-DNS.example.com.    root.example.com. (
		6 ; serial
		8h         ; refresh
		2h         ; retry
		1w         ; expire
		0          ; negative cache ttl
		)
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; nameserver(s)
@	IN	NS	Ext-DNS.example.com.
@	IN	A	8.8.8.8

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; hosts
Int-DNS	IN	A	172.26.0.4
Ext-DNS	IN	A	8.8.8.8

this.test.com. IN A 201.224.19.7
faceybooky.com. IN A 201.224.19.7
Ext-WWW.com. IN A 80.64.157.250
Ext-Office.com. IN A 22.39.224.18

