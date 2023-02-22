#! user/bin/env python3
import os, sys

def framed_write(data):
    '''
    function: framed_write()
    input: data is a byte array
       fdata[0:8] = data length in bytes
       fdata[8:] = data contents
    returns a byte-array
    ''' 
    fdata = bytearray()                              # byte-array for framed data
    size = len(data)                                 # len of data as byte-array
    fdata += bytearray(size.to_bytes(8, 'big'))      # uses big-endian byte order
    fdata += bytearray(data)                         # converts the message to bytes

    return fdata


def framed_read(fdata):
    '''
    function: framed_read()
    input: Takes a framed msg, fdata, as a byte-array and extracts data where the
    general structure is
        fdata[0:8] = data length in bytes
        fdata[8:] = data contents
        fnum is number of framed pieces to read
    returns an array: [data1, data2, ... , ] and sliced framed-data
    '''    
    if len(fdata) == 0:
        return [], byte_array()
    
    data = ['', bytearray()]
    
    # read the filename
    size = int.from_bytes(fdata[0:8], 'big')      # get fdata size as bytes
    contents = fdata[8:8+size].decode()
    data[0] = contents
    fdata = fdata[8+size:]                        # update fdata with the next slice

    # read the file contents
    size = int.from_bytes(fdata[0:8], 'big')
    contents = fdata[8:8+size]
    data[1] += contents
    fdata = fdata[8+size:]
    
    return data, fdata


def read_from_fd(fd, n=100):
    '''
    purpose: read n bytes (at a time) from open file descriptor, fd
    input: 
      fd = file descriptor
      n = num bytes to read at a time
    output: contents from file descriptor as byte array 
    '''   
    contents = bytearray()

    print(f'reading from fd = {fd}')
    while True: 
        buf = os.read(fd, n)
        # print(f'buffer\'s contents are {buf}')
        if not len(buf): break
        contents += buf

    print(f'contents reading from fd = {fd} are {contents.decode()}')    
    return contents


def c(files, ofd=1):
    '''
    name: c is the "create" function similar to tar\'s'
    input:
      files = array of files to be archived
      fd = file descriptor to write to. default is stdout
    output: a single file
    '''
    print(f'files to print are {files}')
    print(f'file descriptor to print to is fd = {ofd}')
    
    for file in files:                                        # names of files to process
        try:
            fdata = bytearray()
            ifd = os.open(file, os.O_RDONLY)                  # open file (read-only)
           
            fmetadata = framed_write(file.encode())           # frame filename
            fdata += fmetadata                                # add framed metadata (filename) to byte array
            
            contents = read_from_fd(ifd, 10)                  # read 10 bytes (at a time) from open fd
            fcontents = framed_write(contents)                # frame contents from input fd
            fdata += fcontents                                # add framed contents to byte array

            os.write(ofd, fdata)                              # send data to output fd
            os.close(ifd)                                     # done with input file descriptor

        except:
            print('File does not exist')

    os.close(ofd)                                             # close output stream

    
def x(file):
    '''
    input: ifd is input file descriptor (default 0)
        data from ifd should be framed data
    output: ofd is output file descriptor (default 1)
    '''
    try:

        ifd = os.open(file, os.O_RDONLY)
        fdata = read_from_fd(ifd)

        while len(fdata) > 0:

            data, fdata = framed_read(fdata)               # read 2 pieces of framed data (filename, contents)

            ofd = os.open(data[0], os.O_WRONLY | os.O_CREAT)  # create file to write to if necessary
            os.write(ofd, data[1])
            os.close(ofd)

        os.close(ifd)                                         # done with the archived file
            
    except FileNotFoundError:
        os.write(1, f'{file}: File not found. Exiting...'.encode())
        
    
if sys.argv[1] == '-help':
    print('To archive: c <file1> [file2] [output.tar]')
    print('To unarchive: x < input.tar')

elif sys.argv[1] == 'c':    
    print('archiving files...')
    files = sys.argv[2:-1]
    output = sys.argv[-1]
    fd = os.open(output, os.O_WRONLY | os.O_CREAT)
    c(files, fd)
    print('files have been archived to {}'.format(sys.argv[-1]))

elif sys.argv[1] == 'x':
    print('extracting files...')
    file = sys.argv[-1]
    x(file)
    print('files have been extracted')

else:
    print('unable to use archiver. Type -help to check syntax.')
