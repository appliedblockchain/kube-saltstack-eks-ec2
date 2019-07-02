# -*- coding: utf-8 -*-
import logging

import boto3

log = logging.getLogger(__name__)


class RDSUtils(object):

    def __init__(self, key_id, secret_key, region):
        self.rds_client = boto3.client(
            'rds',
            aws_access_key_id=key_id,
            aws_secret_access_key=secret_key,
            region_name=region,
        )

    def get_rds_endpoint(self, db_identifier):
        return self.rds_client.describe_db_instances(
            DBInstanceIdentifier=db_identifier,
            MaxRecords=20,
        ).get('DBInstances', [])[0].get('Endpoint', '').get('Address', '')
