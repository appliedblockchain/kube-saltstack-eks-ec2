# -*- coding: utf-8 -*-
import logging

from dnsimple import DNSimple, DNSimpleException

log = logging.getLogger(__name__)


class DNSimpleProvider(object):

    def __init__(self, account_id, api_token):
        self.dnsimple_client = DNSimple(api_token=api_token, account_id=account_id)

    def cname_record_exists(self, domain, name):
        records = self.dnsimple_client.records(domain)
        fqdn = "{}.{}".format(name, domain)
        try:
            def rfilter(x):
                return x.get('record').get('type') == "CNAME" and ("{}.{}".format(x.get('record').get('name'), x.get('record').get('zone_id')) == fqdn)
            record = list(filter(rfilter, records))[0]
            return record
        except DNSimpleException as e:
            return {}
        except IndexError as e:
            return {}

    def cname_record_add(self, domain, name, content):
        try:
            return {'result': True, 'data': self.dnsimple_client.add_record(domain, {'type': 'CNAME', 'name': name, 'content': content})}
        except DNSimpleException as e:
            return {'result': False, 'data': str(e)}

    def cname_record_update(self, domain, name, content):
        records = self.dnsimple_client.records(domain)
        fqdn = "{}.{}".format(name, domain)
        try:
            def rfilter(x):
                return x.get('record').get('type') == "CNAME" and ("{}.{}".format(x.get('record').get('name'), x.get('record').get('zone_id')) == fqdn)
            record_id = list(filter(rfilter, records))[0].get('record').get('id')
            log.error(list(filter(rfilter, records))[0].get('record'))
            return {'result': True, 'data': self.dnsimple_client.update_record(domain, record_id, {'content': content})}
        except DNSimpleException as e:
            return {'result': False, 'data': str(e)}
        except IndexError:
            return {'result': False, 'data': 'record not found'}
