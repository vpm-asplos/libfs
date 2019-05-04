# libfs

A user space library file system based on p-heap interface. 

# Important to users:
 * Starting from the root address, the p-heap will be entirely used by the LFS. In other words, users cannot use root_addr + size, where size is non-negative number, to store non-libfs data. Also, you should not be further touching the brk. Doing so will likely lead to mysterious bugs!
 * Limit the file name to 60 chars (including the trailing '\0')
 * Currently fixed the maximum number of inodes (100)
 * You will need to disable address space randomization: run your program with $ setarch `uname -m` -R program [args ...]

# Notes to libfs developers:
 * Library functions, e.g., libc, can change brk. This should only be a problem when using original heap instead of p-heap.
   Check BRK is not changed at the entry of each library call!

# Interesting design issues unique to libfs:
 * We put the struct file table, the structures describing the features of an open-file (e.g., offset), in the persistent
   heap (p-heap). This allows libfs to keep the semantic of fd across parent/child process, and dup, easily.
 * Need to wrap fork(), to update f_count in struct file table!
 * All of the pointers stored in pheap are relative addresses, relative to root. Therefore in libfs code there are two types
   of pointers: relative address pointers (rptr_t) and absolute address pointers.

# Table of contents
* [lfs_init](#lfs_init)
* [lfs_open](#lfs_open)
* [lfs_write](#lfs_write)
* [lfs_read](#lfs_read)
* [lfs_link](#lfs_link)
* [lfs_unlink](#lfs_unlink)
* [lfs_rmdir](#lfs_rmdir)
* [lfs_rename](#lfs_rename)
* [lfs_readdir](#lfs_readdir)
* [lfs_opendir](#lfs_opendir)
* [lfs_closedir](#lfs_closedir)
* [lfs_mkdir](#lfs_mkdir)
* [lfs_chdir](#lfs_chdir)
* [lfs_getcwd](#lfs_getcwd)
* [lfs_lseek](#lfs_lseek)
* [lfs_stat and lfs_fstat](#lfs_stat)
* [lfs_access](#lfs_access)

# lfs_init<a name="lfs_init"></a>

Initialize the library file system. 

## Synopsis

```C
#include <lfs.h>
int lfs_init (void *addr, int flag);
```

## Description

`lfs_init` is used to initialize the library file system (FS). The root of the FS is specified in `addr`. Depending on the value of `flag`, it either creates a new FS (when `flag` is set to `LFS_FORMAT`), or simply remembers the root `addr` (when `flag` is set `LFS_READONLY`), assuming that the FS is already properly created by prior sessions. 

After `lfs_init` is invoked, future use of the library FS will not need to provide the root again. `lfs_init` should be invoked once per process. 

Valid values for `flag` are:

* `LFS_FORMAT`: used to create (and format) a new FS.
* `LFS_READONLY`: used when the FS is already created, just to inform the future use of the library of the location of the root.

## Return values:

On success it returns 0. On error, -1 is returned, and `errno` is set appropriately.

## Errors:

* `LFS_EINVAL` when `flag` is neither `LFS_READONLY` or `LfS_FORMAT`
* `LFS_EFAULT` when `addr` is not a valid address. This could occur when it cannot find the root at `addr` (when `flag` equals `LFS_READONLY`) or it cannot create an FS on `addr`.
* `LFS_EALREADY` when `lfs_init` is already invoked for this process.

# lfs_open<a name="lfs_open"></a>

open a file.

## Synopsis

```C
int lfs_open (const char *pathname, int flags);
```

## Description

Given a pathname for a file, open() returns a file descriptor, a small, nonnegative integer for use in subsequent system calls. The file descriptor returned by a successful call will be the lowest-numbered file descriptor not currently open for the process.

A call to open() creates a new open file description, an entry in the process-wide table of open files. This entry records the file offset and the file status flags (modifiable via the fcntl(2) F_SETFL operation). A file descriptor is a reference to one of these entries; this reference is unaffected if pathname is subsequently removed or modified to refer to a different file. The new open file description is initially not shared with any other process, but sharing may arise via fork(2).

The argument flags must include one of the following access modes: `O_RDONLY`, `O_WRONLY`, or `O_RDWR`. These request opening the file read-only, write-only, or read/write, respectively.

In addition, zero or more file creation flags and file status flags can be bitwise-or'd in flags. The file creation flags are O_CREAT, O_TRUNC. The file status flags are all of the remaining flags listed below. The distinction between these two groups of flags is that the file status flags can be retrieved and (in some cases) modified using fcntl(2). The full list of file creation flags and file status flags is as follows:

* `O_APPEND`: The file is opened in append mode. Before each write(2), the file offset is positioned at the end of the file, as if with lseek(2). 

* (**NOSUPPORT**) `O_ASYNC`: Enable signal-driven I/O: generate a signal (SIGIO by default, but this can be changed via fcntl(2)) when input or output becomes possible on this file descriptor. This feature is only available for terminals, pseudoterminals, sockets, and (since Linux 2.6) pipes and FIFOs. See fcntl(2) for further details.

* (**No plan to support**) `O_CLOEXEC` (Since Linux 2.6.23): Enable the close-on-exec flag for the new file descriptor. Specifying this flag permits a program to avoid additional fcntl(2) F_SETFD operations to set the FD_CLOEXEC flag. Additionally, use of this flag is essential in some multithreaded programs since using a separate fcntl(2) F_SETFD operation to set the FD_CLOEXEC flag does not suffice to avoid race conditions where one thread opens a file descriptor at the same time as another thread does a fork(2) plus execve(2).

* `O_CREAT`: If the file does not exist it will be created. The owner (user ID) of the file is set to the effective user ID of the process. The group ownership (group ID) is set either to the effective group ID of the process.

* `O_TRUNC`: If the file already exists and the open mode allows writing (i.e., is O_RDWR or O_WRONLY) it will be truncated to length 0. 

## Return value:

On success it returns the new file descriptor, or -1 if an error occurred (in which case, errno is set appropriately).

## Errors

* EACCES: The requested access to the file is not allowed, or search permission is denied for one of the directories in the path prefix of pathname, or the file did not exist yet and write access to the parent directory is not allowed. 

* EDQUOT: Where O_CREAT is specified, the file does not exist, and the user's quota of disk blocks or inodes on the file system has been exhausted.

* EEXIST: pathname already exists and O_CREAT and O_EXCL were used.

* EMFILE
The process already has the maximum number of files open.

* ENAMETOOLONG: pathname was too long.

* ENFILE: The system limit on the total number of open files has been reached.

* ENOENT: O_CREAT is not set and the named file does not exist. Or, a directory component in pathname does not exist or is a dangling symbolic link.

* ENOMEM: Insufficient kernel memory was available.

## Notes

**This is simpler than the Linux open, which offers more complex interface that includes a more detailed `mode` flag.** If we find that we need to support `mode` we can add it later. 


# lfs_write <a name="lfs_write"> </a>

```C
int lfs_write(int fd, const void *buf, int count);
```

## Description

write() writes up to count bytes from the buffer pointed buf to the file referred to by the file descriptor fd. The number of bytes written may be less than count if there is insufficient space.

The writing takes place at the current file offset, and the file offset is incremented by the number of bytes actually written. If the file was open(2)ed with O_APPEND, the file offset is first set to the end of the file before writing. The adjustment of the file offset and the write operation are performed as an atomic step.

## Return Value
On success, the number of bytes written is returned (zero indicates nothing was written). On error, -1 is returned, and errno is set appropriately. 

## Errors
* EBADF: fd is not a valid file descriptor or is not open for writing.
* EFBIG: An attempt was made to write a file that exceeds the implementation-defined maximum file size or the process's file size limit, or to write at a position past the maximum allowed offset.

## **NOTE**:
If buf is inaccessible, then instead of returning EFAULT as in the OS, it will simply crash.

# lfs_read <a name="lfs_read"> </a>

```C
int read(int fd, void *buf, int count);
```

## Description

`read()` attempts to read up to count bytes from file descriptor `fd` into the buffer starting at buf. The read operation commences at the current file offset, and the file offset is incremented by the number of bytes read. If the current file offset is at or past the end of file, no bytes are read, and read() returns zero.

## Return Value
On success, the number of bytes read is returned (zero indicates end of file), and the file position is advanced by this number. It is not an error if this number is smaller than the number of bytes requested; this may happen for example because fewer bytes are actually available right now (maybe because we were close to end-of-file, or because we are reading from a pipe, or from a terminal), or because read() was interrupted by a signal. On error, -1 is returned, and errno is set appropriately. In this case it is left unspecified whether the file position (if any) changes.

## Errors
* EBADF: fd is not a valid file descriptor or is not open for reading.
* EISDIR: fd refers to a directory.

# lfs_link <a name="lfs_link"> </a>

```C
int lfs_link(const char *oldpath, const char *newpath);
```

## Description
Creates a new link (also known as a hard link) to an existing file.

If newpath exists, it will not be overwritten.

This new name may be used exactly as the old one for any operation; both names refer to the same file (and so have the same permissions and ownership) and it is impossible to tell which name was the "original".

## RETURN VALUE        
On success, zero is returned.  On error, -1 is returned, and errno is set appropriately.

## ERRORS
* LFS_EACCES Write access to the directory containing newpath is denied, or search permission is denied for one of the directories in the path prefix of oldpath or newpath.
* LFS_EPERM  oldpath is a directory.  
* LFS_EEXIST newpath already exists.
* LFS_EMLINK The file referred to by oldpath already has the maximum number of links to it.  
* LFS_ENAMETOOLONG oldpath or newpath was too long.
* LFS_ENOENT A directory component in oldpath or newpath does not exist 
* LFS_ENOSPC The device containing the file has no room for the new directory entry.
* LFS_ENOTDIR A component used as a directory in oldpath or newpath is not, in fact, a directory.

# lfs_unlink <a name="lfs_unlink"> </a>

```C
int lfs_unlink(const char *pathname)
```

lfs_unlink() deletes a name from the file system. If that name was the last link to a file and no processes have the file open the file is deleted and the space it was using is made available for reuse. If the name was the last link to a file but any processes still have the file open the file will remain in existence until the last file descriptor referring to it is closed.

## Return Value
On success, zero is returned. On error, -1 is returned, and errno is set appropriately.

## Errors
* LFS_EACCES: Write access to the directory containing pathname is not allowed for the process's effective UID, or one of the directories in pathname did not allow search permission. (See also path_resolution(7).)

* LFS_EISDIR: pathname refers to a directory. 

* LFS_ENAMETOOLONG: pathname was too long.

* LFS_ENOENT: A component in pathname does not exist or is a dangling symbolic link, or pathname is empty.

* LFS_ENOTDIR: A component used as a directory in pathname is not, in fact, a directory.

* LFS_EPERM: Does not allow unlink.

# lfs_rename <a name="lfs_rename"> </a>

```C
int lfs_rename(const char *oldname, const char *newname);
```

The lfs_rename function renames the file oldname to newname. The file formerly accessible under the name oldname is afterwards accessible as newname instead. (If the file had any other names aside from oldname, it continues to have those names.)

If newpath already exists, it will be atomically replaced, so that there is no point at which another process attempting to access newpath will find it missing.  However, there will probably be a window in which both oldpath and newpath refer to the file being renamed.

If oldpath and newpath are existing hard links referring to the same file, then rename() does nothing, and returns a success status.

If newpath exists but the operation fails for some reason, rename() guarantees to leave an instance of newpath in place.

oldpath can specify a directory.  In this case, newpath must either not exist, or it must specify an empty directory.

## RETURN VALUE        
On success, zero is returned.  On error, -1 is returned, and errno is set appropriately.

## ERRORS        
* LFS_EACCES Write permission is denied for the directory containing oldpath or newpath, or, search permission is denied for one of the directories in the path prefix of oldpath or newpath, or oldpath is a directory and does not allow write permission.  

* LFS_EINVAL The new pathname contained a path prefix of the old, or, more generally, an attempt was made to make a directory a subdirectory of itself.

* LFS_EISDIR newpath is an existing directory, but oldpath is not a directory.

* LFS_EMLINK oldpath already has the maximum number of links to it, or it was a directory and the directory containing newpath has the maximum number of links.

* LFS_ENAMETOOLONG: oldpath or newpath was too long.

* LFS_ENOENT The link named by oldpath does not exist; or, a directory component in newpath does not exist; or, oldpath or newpath is an empty string.

* LFS_ENOMEM Insufficient kernel memory was available.

* LFS_ENOTDIR A component used as a directory in oldpath or newpath is not, in fact, a directory.  Or, oldpath is a directory, and newpath exists but is not a directory.

* LFS_ENOTEMPTY newpath is a nonempty directory, that is, contains entries other than "." and "..".

# lfs_readdir <a name="lfs_readdir"> </a>

```C
int lfs_readdir (int fd, struct dirent *dp)
```

The readdir() function returns a pointer (through dp) to a dirent structure representing the next directory entry in the directory stream pointed to by fd. (The return value of [lfs_opendir](lfs_opendir). It returns -1 (with error code LFS_EENDDIR) on reaching the end of the directory stream or other error occurred.

The dirent structure is defined as follows:

struct dirent {
    uint16_t i_number;
    char name[LFS_NAMELEN];
};

Note that while this is different from Linux's readdir, but the dirent is POSIX compatible.

# lfs_chdir <a name="lfs_chdir"> </a>

```C
int lfs_chdir(const char *path);
```

## Description
Changes the current working directory of the calling process to the directory specified in path.

Note: currently we require that path is an absolute path (remove the constraint later)!

## RETURN VALUE        
On success, zero is returned.  On error, -1 is returned, and lfs_error is set appropriately.

## ERRORS
* LFS_NOTABS: If the pathname is not an absolute pathname
* LFS_ENAMETOOLONG: if the pathname is too long (>256)
* LFS_ENOENT: no such entry
* LFS_ENOTDIR: a component in path should be dir but it is not
* LFS_ENOEXEC: cannot cd into the directory b/c it lacks X permission

# lfs_getcwd <a name="lfs_getcwd"> </a>

```C
char *lfs_getcwd(char *buf, int size);
char *lfs_getwd(char *buf)
```

## Description

These functions return a null-terminated string containing an absolute pathname that is the current working directory of the calling process. The pathname is returned as the function result and via the argument buf, if present.

The getcwd() function copies an absolute pathname of the current working directory to the array pointed to by buf, which is of length size.

If the length of the absolute pathname of the current working directory, including the terminating null byte, exceeds size bytes, NULL is returned, and errno is set to ERANGE; an application should check for this error, and allocate a larger buffer if necessary.

getwd() does not malloc(3) any memory. The buf argument should be a pointer to an array at least 256 bytes long. For portability and security reasons, use of getwd() is deprecated.

## RETURN VALUE        
On success, these functions return a pointer to a string containing the pathname of the current working directory. In the case getcwd() and getwd() this is the same value as buf.

On failure, these functions return NULL, and errno is set to indicate the error. The contents of the array pointed to by buf are undefined on error.

## ERRORS

# lfs_lseek <a name="lfs_lseek"> </a>

```C
int lfs_lseek(int fd, int offset, int whence);
```

## Description
The lseek() function repositions the offset of the open file associated with the file descriptor fd to the argument offset according to the directive whence as follows:
 *   SEEK_SET: The offset is set to offset bytes.
 *   SEEK_CUR: The offset is set to its current location plus offset bytes.
 *   SEEK_END: The offset is set to the size of the file plus offset bytes.


## Return Value:
Upon successful completion, lseek() returns the resulting offset location as measured in bytes from the beginning of the file. On error, the value (off_t) -1 is returned and lfs_error is set to indicate the error

## ERRORS
 * LFS_EBADF:     fd is not an open file descriptor.
 * LFS_EINVAL:    whence is not valid.
 * LFS_EOVERFLOW: The resulting file offset cannot be represented in an off_t, or it's beyond file size.
 
# lfs_stat and lfs_lstat <a name="lfs_stat"> </a>
 
 ```C
int  lfs_stat (const char *pathname, struct lfs_stat *buf);
int  lfs_fstat (int fd, struct lfs_stat *buf);
int  lfs_lstat (const char *pathname, struct lfs_stat *buf);
```

## Description
These functions return information about a file. 

lfs_stat() stats the file pointed to by path and fills in buf.

lstat() is identical to stat(); there is supposed to be a difference when path is a symbolic link, but libfs currently does not support symbolic link.

fstat() is identical to stat(), except that the file to be stat-ed is specified by the file descriptor fd.

All of these system calls return a stat structure, which contains the following fields:
struct lfs_stat {
    // dev_t     st_dev;     /* ID of device containing file */
    uint16_t  st_ino;     /* inode number */
    uint16_t  st_mode;    /* protection */
    uint16_t  st_nlink;   /* number of hard links */
    uid_t     st_uid;     /* user ID of owner */
    gid_t     st_gid;     /* group ID of owner */
    uint32_t  st_size;    /* total size, in bytes */
    //blkcnt_t  st_blocks;  /* number of 512B blocks allocated */
    //time_t    st_atime;   /* time of last access */
    time_t    st_modtime;   /* time of last modification */
    //time_t    st_ctime;   /* time of last status change */
};

## RETURN VALUE        
On success, zero is returned. On error, -1 is returned, and errno is set appropriately.

## ERRORS

# lfs_access <a name="lfs_access"> </a>
```C
int lfs_access(const char *path, int mode);
```

## Description
access() checks whether the calling process can access the file pathname. The mode specifies the accessibility check(s) to be performed, and is either the value LFS_F_OK, or a mask consisting of the bitwise OR of one or more of LFS_R_OK, LFS_W_OK, and LFS_X_OK. LFS_F_OK tests for the existence of the file. LFS_R_OK, LFS_W_OK, and LFS_X_OK test whether the file exists and grants read, write, and execute permissions, respectively.

Note: currently we are largely ignoring permission checks; basically only check for existence.

## RETURN VALUE        
On success, zero is returned.  On error, -1 is returned, and lfs_error is set appropriately.

## ERRORS
* LFS_ENOENT: no such entry
* LFS_ENOTDIR: a component in path should be dir but it is not
* LFS_ENOEXEC: cannot cd into the directory b/c it lacks X permission
