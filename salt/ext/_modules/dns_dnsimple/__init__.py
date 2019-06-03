from dns_dnsimple.provider import DNSimpleProvider

__virtualname__ = 'dnsimple'


def _confs(client_id):
    return {
        'account_id': __salt__.pillar.get("{0}:authentication:dnsimple:account_id".format(client_id)),
        'api_token': __salt__.pillar.get("{0}:authentication:dnsimple:api_token".format(client_id)),
    }


def cname_record_exists(client_id, domain, name):
    return DNSimpleProvider(account_id=_confs(client_id).get('account_id'), api_token=_confs(client_id).get('api_token')).cname_record_exists(domain=domain, name=name)


def cname_record_add(client_id, domain, name, content):
    return DNSimpleProvider(account_id=_confs(client_id).get('account_id'), api_token=_confs(client_id).get('api_token')).cname_record_add(domain=domain, name=name, content=content)


def cname_record_update(client_id, domain, name, content):
    return DNSimpleProvider(account_id=_confs(client_id).get('account_id'), api_token=_confs(client_id).get('api_token')).cname_record_update(domain=domain, name=name, content=content)
