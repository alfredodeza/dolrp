# The MIT License (MIT)
# Copyright (c) 2013 Alfredo Deza
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
# OR OTHER DEALINGS IN THE SOFTWARE.

"""
Oh lua, you look so ugly::

    runcommand('python ' .. _PLUGIN.path .. '/s3.py create ' .. prefs.apiKey .. prefs.sharedSecret .. prefs.bucket .. fileName .. params.filePath)

"""
import sys
import boto
import boto.s3.connection
from boto.s3.key import Key


def errors():
    return {
        400: 1,
        403: 2,
        405: 3,
        409: 4,
        411: 5,
        412: 6,
        416: 7,
        501: 8,
        503: 9,
    }


def parse_args(args):
    arguments = {'file_path': ''}
    args_map = {0: 'script', 1: 'command', 2: 'access_key', 3: 'secret_key', 4: 'bucket_name', 5: 'filename', 6: 'file_path'}
    for number, item in enumerate(args):
        arguments[args_map[number]] = item
    return arguments

args = parse_args(sys.argv)

conn = boto.connect_s3(
        aws_access_key_id = args['access_key'],
        aws_secret_access_key = args['secret_key'],
        host = 'objects.dreamhost.com',
        calling_format = boto.s3.connection.OrdinaryCallingFormat(),
        )

try:
    if args['command'] == 'create':
        bucket = conn.create_bucket(args['bucket_name'])
        key = Key(bucket)
        key.key = args['filename']
        key.set_contents_from_filename(args['file_path'])

    if args['command'] == 'delete':
        bucket = conn.create_bucket(args['bucket_name'])
        bucket.delete_key(args['filename'])
except Exception as err:
    if hasattr(err, 'status'):
        raise SystemExit(errors().get(err.status))
    raise
