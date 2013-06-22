"""
    runcommand('python ' .. _PLUGIN.path .. '/s3.py create ' .. prefs.apiKey .. prefs.sharedSecret .. prefs.bucket .. fileName .. params.filePath)
                0                               1       2            3               4                       5           6               7
"""
import sys
import boto
import boto.s3.connection
from boto.s3.key import Key

command = sys.argv[1]
access_key = sys.argv[2]
secret_key = sys.argv[3]
bucket_name = sys.argv[4]
filename = sys.argv[5]
file_path = sys.argv[6]

conn = boto.connect_s3(
        aws_access_key_id = access_key,
        aws_secret_access_key = secret_key,
        host = 'objects.dreamhost.com',
        calling_format = boto.s3.connection.OrdinaryCallingFormat(),
        )

if command == 'create':
    bucket = conn.create_bucket(bucket_name)
    key = Key(bucket)
    key.key = filename
    key.set_contents_from_filename(file_path)
