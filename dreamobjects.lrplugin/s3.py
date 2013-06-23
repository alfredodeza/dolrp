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
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
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
