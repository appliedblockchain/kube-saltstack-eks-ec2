# -*- coding: utf-8 -*-
import logging

import boto3

log = logging.getLogger(__name__)


class EFSUtils(object):

    def __init__(self, key_id, secret_key, region):
        region = 'eu-west-1'
        self.efs_client = boto3.client(
            'efs',
            aws_access_key_id=key_id,
            aws_secret_access_key=secret_key,
            region_name=region,
        )

    def get_system_id(self, creation_token):
        response = self.efs_client.describe_file_systems()
        for fs in response['FileSystems']:
            if fs['CreationToken'] == creation_token:
                return fs['FileSystemId']
