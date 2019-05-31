import logging

log = logging.getLogger(__name__)


def __virtual__():
    return 'dnsimple'


def cname_present(client_id, domain, name, content_file):
    content = open(content_file, "r").read()

    def result_dict(result):
        return {
            'name': 'cname_present',
            'result': result.get('result'),
            'changes': result.get('data') if result.get('result') else {},
            'comment': result.get('data') if not result.get('result') else ''}

    def exists():
        return __salt__['dns_dnsimple.cname_record_exists'](client_id=client_id, domain=domain, name=name)

    def execute(op):
        return result_dict(__salt__['dns_dnsimple.cname_record_{0}'.format(op)](client_id=client_id, domain=domain, name=name, content=content))

    return execute('update') if exists() else execute('add')
