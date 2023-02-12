#! user/bin/env python3
import os, sys

'''
mtob = 'message to bytes'
Takes a string and creates a byte array with
the general structure:<str len (8 bytes)> <actual string>
byte_array[0:8] = str len in bytes
byte_array[8:] = str
returns a byte-array with the encoded message
'''
def mtob(message, size):
    data = bytearray()
    data += bytearray(size.to_bytes(8, 'big'))
    data += bytearray(message.encode())
    
    return data

'''
btom = 'bytes to message'
Takes an array and extracts data where the
general structure is:<str len (8 bytes)> <actual string>
metadata:
     (0) message
     (1) <metadata> + message
     (2) <metadata> + <metadata> + message
Essentially, metadata tells you how many 'pieces' of
the string there are. A filename (for instance) would
consist of: filename + contents
returns an array: [metadata, metadata, ... , message]
'''
def btom(data, metadata=0):
    if len(byte_array) == 0:
        return ''
    
    message = []
    
    for i in range(metadata+1):
        size = int.from_bytes(data[0:8], 'big')
        message[i] = data[8:8+size].decode()
        data = data[8+size:]

    return message

'''
function to archive files
input:
     files = array of files to be archived
     output_file = name of newly archived file
output: a single file
'''
def arch(files, output_file):
    arch_file = open(output_file, 'wb')                      # 'wb' = 'write binary'
    
    for file in files:                                       # process each file
        try:
            f = open(file, 'r')                              # open the file
            data = bytearray()                               # create byte array
            
            metadata = mtob(file, len(file.encode()))        # use message-to-bytes function
            data += metadata                                 # add filename to byte array
            message = mtob(f.read(), os.path.getsize(file))  # use message-to-bytes function
            data += message                                  # add file contents to byte array

            arch_file.write(data)                            # add byte array to archive
            f.close()                                        # done with file
        except:
            print('File does not exist')

    arch_file.close()

def unarch(file):
    try:
        arch_file = open(file, 'rb')                          # 'rb' = 'read binary'
        data = arch_file.read()

        while len(data) > 0:                                  # continue through entire file
            fname_len = int.from_bytes(data[:8], 'big')       # len of filename
            fname = data[8:8+fname_len]                       # actual name of file (in bytes)
            data = data[8+fname_len:]                         # remove fname_len and fname

            fcontents_len = int.from_bytes(data[:8], 'big')   # len of fcontents
            fcontents = data[8:8+fcontents_len]               # actual file contents (in bytes)
            data = data[8+fcontents_len:]                     # remove fcontents_len and fcontents

            new_file = open(fname.decode(), 'wb')             # create new file
            new_file.write(fcontents)                         # write the extracted file contents
            new_file.close()

            """
            alternatively, you can just open the file 
            with 'w' and instead decode fcontents first.

            new_file = open(fname.decode(), 'w')
            new_file.write(fcontents.decode())
            """

        arch_file.close()                                     # done with the archived file
            
    except FileNotFoundError:
        os.write(1, f'{file}: File not found. Exiting...'.encode())
        
    
if sys.argv[1] == '-help':
    print('To archive: arch <file1> [file2] <output_file>.arch')
    print('To unarchive: unarch <file>.arch')

elif sys.argv[1] == 'arch':    
    print('archiving files...')
    files = sys.argv[2:-1]
    output = sys.argv[-1]
    arch(files, output)
    print('files have been archived to {}'.format(sys.argv[-1]))

elif sys.argv[1] == 'unarch':
    print('extracting files...')
    file = sys.argv[-1]
    unarch(file)
    print('files have been extracted')

else:
    print('unable to use archiver. Type -help to check syntax.')
