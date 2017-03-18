+++
date = "2011-11-09T11:35:21+02:00"
title = "iptables in a hurry"

+++

Accepting incoming connections to a port only from specific hosts in the middle of the night:

    iptables -I INPUT -p tcp --dport $dport -j REJECT
    for ip in $ips; do
        iptables -I INPUT -p tcp --dport $dport --source $ip -j ACCEPT

We have to do it in the above order, since -I **inserts** the rule at the head of the list of rules.
