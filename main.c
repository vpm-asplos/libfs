#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "libfs.h"
#include <dirent.h>
#include <stdbool.h>
#include "lfs_error.h"
#include <linux/kernel.h>
#include <sys/syscall.h>
#include <assert.h>
#include "measure-time.h"

#define PBRKSTART 0x2a0002000000
#define PCREATE 1
#define PSHARE 2
#define PBRKSIZE 0x010000000

/*
void calc_diff(struct timespec *smaller, struct timespec *bigger, struct timespec *diff)
{
    if (smaller->tv_nsec > bigger->tv_nsec)
    {
        diff->tv_nsec = 1000000000 + bigger->tv_nsec - smaller->tv_nsec;
        diff->tv_sec = bigger->tv_sec - 1 - smaller->tv_sec;
    }
    else 
    {
        diff->tv_nsec = bigger->tv_nsec - smaller->tv_nsec;
        diff->tv_sec = bigger->tv_sec - smaller->tv_sec;
    }
}*/

void check_file(const char *name)
{
    char buf[150];
    int ret;
    int fd = lfs_open(name, LFS_O_RDONLY);
    if (fd == -1)
    {
        printf("****check error! Failed to open: %s\n", name);
        exit(1);
    }
    else
    {
        ret = lfs_read(fd, buf, 1);
        if (ret != 1)
        {
            printf("****check error! Failed to read: %s\n", name);
            lfs_close(fd);
            exit(1);
        }
        lfs_close(fd);
    }
}

// Non recursively load directory
void loaddir(const char *name, int indent, int remaining)
{
    if (!remaining)
        return;
    bool dot;
    if (strcmp(name, ".") == 0)
        dot = true;
    else if (name[0] == '.' && name[1] == '/') {
      dot = true;
    } else
      dot = false;
    DIR *dir;
    struct dirent *entry;

    if (!(dir = opendir(name)))
        return;

    while ((entry = readdir(dir)) != NULL)
    {
        char path[1024];
        snprintf(path, sizeof(path), "%s/%s", name, entry->d_name);
        if (entry->d_type == DT_DIR)
        {
            if (strcmp(entry->d_name, ".") == 0
		|| strcmp(entry->d_name, "..") == 0
		|| strcmp(entry->d_name, ".git") == 0)
                continue;

            printf("Creating directory: %s ... ",dot ? &path[1] : path);
            if (lfs_mkdir(dot ? &path[1] : path, 0)) {
	      printf("Failed! Error code: %d\n", lfs_error);
	    } else {
                printf("Success\n");
	    }
            // loaddir(path, indent + 2, remaining - 1);
        } else if(entry->d_type == DT_LNK) {
		continue;
	}else {

            FILE *f = fopen(path, "r");
            if (!f)
                continue;

	    printf("Creating file: %s ... ", dot ? &path[1] : path);
            int fd = lfs_creat(dot ? &path[1] : path, (IRUSR | IWUSR | IRGRP | IROTH)); //(IRUSR|IWUSR|IRGRP)
            if (fd == -1) {
                printf("Failed! Error code: %d \n", lfs_error);
                continue;
            }
            //printf("created: %s\n",dot ? &path[1] : path);
            char buff[1024];
            unsigned got;
            while ((got = fread(&buff[0], 1, 1024, f)))
            {
                lfs_write(fd, &buff[0], got);
            }
            fclose(f);
            lfs_close(fd);
	    printf("Success!\n");
            //printf("close: %s\n", path);
            //printf("%*s- %s\n", indent, "", entry->d_name);
        }
    }
    closedir(dir);
}

int load_file(const char * name) {
	printf("Creating file: %s ... ", name);
	FILE *f = fopen(name, "r");
	int fd = lfs_creat(name, (IRUSR | IWUSR | IRGRP | IROTH));
	if(fd == -1) {
		printf("Failed! error code : %d\n", lfs_error);
		return -1;
	}
	char buff[1024];
	unsigned got;
	while((got = fread(&buff[0], 1, 1024, f))) {
		lfs_write(fd, &buff[0], got);
	}
	fclose(f);
	lfs_close(fd);
	printf("Success!\n");
	return 0;
}

void load_include() {
  if (lfs_mkdir("/usr", 0))
    printf("Failed to create directory: /usr\n");
  if (lfs_mkdir("/usr/include", 0))
    printf("Failed to create directory: /usr/include\n");
  if (lfs_mkdir("/usr/local", 0))
    printf("Failed to create directory: /usr/local\n");
  if (lfs_mkdir("/usr/local/include", 0))
    printf("Failed to create directory: /usr/local/include\n");
  loaddir("/usr/include", 0, 1);
  loaddir("/usr/include/bits", 0, 100);

  loaddir("/usr/include/bits/types", 0, 100);
  if(lfs_mkdir("/usr/include/linux", 0))
	  printf("Failed to create directory: /usr/include/linux");
  load_file("/usr/include/linux/errno.h");
  loaddir("/usr/include/gnu", 0, 100);
  loaddir("/usr/include/sys", 0, 100);

  loaddir("/usr/include/asm", 0, 100);

  loaddir("/usr/include/asm-generic", 0, 100);
  loaddir("/usr/local/include", 0, 100);
  // if (lfs_mkdir("/usr/include/x86_64-linux-gnu", 0))
  //     printf("failed to create directory: /usr/include/x86_64-linux-gnu\n");
  //loaddir("/usr/include/x86_64-linux-gnu", 0, 100);
  // loaddir("/usr/include/linux", 0, 100);
  // if (lfs_mkdir("/usr/include/asm", 0))
  //     printf("failed to create directory: /usr/include/asm\n");
  // loaddir("/usr/include/asm", 0, 100);
}


int testwrite(const char* filename, unsigned int chunk_size, unsigned int total_size) {
    struct timespec st, et;

    char* buf = malloc(total_size);
    int fd = lfs_open(filename, LFS_O_RDWR | LFS_O_CREAT);
    if (fd < 0) {
        printf("Can't open file on write!!\n");
        exit(1);
    }

    clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &st);
    size_t chunkcnt = (total_size / chunk_size);
    for (size_t i = 0; i < chunkcnt; i++) {
        // printf("Writing to file, i = %d, chunkcnt = %d!\n", i, chunkcnt);
        int r = lfs_write(fd, buf + (i * chunk_size), chunk_size);
        if (r == -1) {
            printf("Write failed!\n"); exit(1);
        }
    }
    clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &et);
    lfs_close(fd);
    unsigned long sec = et.tv_sec - st.tv_sec;
    unsigned long nsec = et.tv_nsec - st.tv_nsec;
    free(buf);
    printf("Write time cost: %lu sec %lu nsec, total size: %u\n", sec, nsec, total_size);
    
    return 0;
}

int testread(const char* filename, unsigned int chunk_size) {
    struct timespec st, et;
    clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &st);
    int fd = lfs_open(filename, LFS_O_RDONLY);
    if (fd < 0) {
        printf("Can't open file, path: %s!\n", filename);
    }
    struct lfs_stat meta;
    int ret = lfs_fstat(fd, &meta);
    if (ret < 0) {
        printf("Can't validate fd, fd:%d!\n", fd);
        exit(1);
    }
    printf("File size: %u [END]\n", meta.st_size);
    char* buf = malloc(meta.st_size);
    size_t chunkcnt = (meta.st_size / chunk_size);
    for (size_t i = 0; i < chunkcnt; i++) {
        // printf("LFS reading !!!\n");
        lfs_read(fd, buf + (i * chunk_size), chunk_size);
    }
    free(buf);
    lfs_close(fd);
    clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &et);
    unsigned long sec = et.tv_sec - st.tv_sec;
    unsigned long nsec = et.tv_nsec - st.tv_nsec;
    printf("Read time cost: %lu sec, %lu nsec\n", sec, nsec);
    return 0;
}

int main(int arc, char **args)
{
    void *lfs_buf = NULL;
#ifdef ENABLE_NOFS
    long ret_t2_1 = syscall(334, "newm", 4, PCREATE);
    if (ret_t2_1 < 0)
    {
        printf("Cannot create region because of ID conflict. Trying to attach to existing pheap... \n");
        ret_t2_1 = syscall(334, "newm", 4, PSHARE);
        if (ret_t2_1 < 0) {
	  printf("Failed to attach to pheap newm. Now exiting!");
	  return 1;
	}
    }
    printf("Pheap attached. Now changing brk and zeroing. \n");
    long ret_t2_2 = syscall(333, PBRKSTART + PBRKSIZE);
    if(ret_t2_2 < 0) {
      printf("Failed to increase pheap size. Exiting.\n");
      return 1;
    }
    assert(!(PBRKSTART & 0xFFF)); // make sure PBRKSTART is aligned to 4K page
    memset((char*)PBRKSTART, 0, PBRKSIZE);
    lfs_buf = (void*)PBRKSTART;
#else
    uintptr_t chunk = (uintptr_t)malloc(PBRKSIZE);
    memset((void*)chunk, 0, PBRKSIZE);
    // make sure chunk is aligned to 4K page
    while(chunk & (uintptr_t) 0xFFF) {
      chunk += 1;
    }
    lfs_buf = (void*)chunk;
#endif
    lfs_init(lfs_buf, LFS_FORMAT, 512 * 1024 * 1024);
    /* loaddir(".", 0, 100); */
    /* loaddir("./test", 0, 100); */
    /* load_include(); */
    
#define TESTFILESIZE 136314880

    testwrite("./write.txt", 1, TESTFILESIZE);
    testwrite("./write.txt", 4 * 1024, TESTFILESIZE);

    testwrite("./write.txt", 2 * 1024 * 2024, TESTFILESIZE);
    /* testread("./write.txt", 1); */
    /* testread("./write.txt", 4 * 1024); */
    /* testread("./write.txt", 2 * 1024 * 2024); */

    lfs_detach();
    printf("end of loader!\n");
    return 0;
}
