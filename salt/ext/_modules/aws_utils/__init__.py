from aws_utils.efs import EFSUtils
from aws_utils.rds import RDSUtils

__virtualname__ = 'aws_utils'


def _confs(client_id):
    return {
        'key_id': __salt__.pillar.get("{0}:authentication:aws:saltstack:aws_access_key_id".format(client_id)),
        'secret_key': __salt__.pillar.get("{0}:authentication:aws:saltstack:aws_secret_access_key".format(client_id)),
    }


def get_efs_system_id(creation_token, client_id, region):
    return EFSUtils(
        key_id=_confs(client_id).get('key_id'), secret_key=_confs(client_id).get('secret_key'),
        region=region
    ).get_system_id(creation_token=creation_token)


def get_rds_endpoint(db_identifier, client_id, region):
    return RDSUtils(
        key_id=_confs(client_id).get('key_id'), secret_key=_confs(client_id).get('secret_key'),
        region=region
    ).get_rds_endpoint(db_identifier=db_identifier)
