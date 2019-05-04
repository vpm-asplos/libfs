#CFLAGS=-O3 -Wall -DNDEBUG -DUSER_ALLOCATE_SPACE
CFLAGS=-O3 -Wall -DUSER_ALLOCATE_SPACE

.PHONY: default
default: libfs.a test main mainram;

libfs.a: lfs.o lfs_error.o bitmap.o inode.o sync.o file.o test.o
	ar cru libfs.a lfs.o lfs_error.o bitmap.o inode.o sync.o file.o test.o

main: main.o measure-time.o
	echo "Compiling main"
	gcc $(CFLAGS) -o main main.o measure-time.o libfs.a

mainram: mainram.o measure-time.o
	echo "Compiling mainram"
	gcc $(CFLAGS) -o mainram mainram.o measure-time.o libfs.a

lfs.o: lfs.c libfs.h lfs.h lfs_error.h inode.h file.h sync.h
	gcc -c $(CFLAGS) lfs.c -o lfs.o

lfs_error.o: lfs_error.c lfs_error.h
	gcc -c $(CFLAGS) lfs_error.c -o lfs_error.o

bitmap.o: bitmap.c bitmap.h
	gcc -c $(CFLAGS) bitmap.c -o bitmap.o

inode.o: inode.c inode.h lfs.h sync.h lfs_error.h bitmap.h
	gcc -c $(CFLAGS) inode.c -o inode.o

sync.o: sync.c sync.h
	gcc -c $(CFLAGS) sync.c -o sync.o

test.o: test.c  
	gcc -c $(CFLAGS) test.c -o test.o

file.o: file.c file.h
	gcc -c $(CFLAGS) file.c -o file.o

measure-time.o: measure-time.c measure-time.h
	gcc -c $(CFLAGS) measure-time.c -o measure-time.o

main.o: main.c
	gcc -c $(CFLAGS) -D ENABLE_NOFS main.c -o main.o 

mainram.o: main.c
	gcc -c $(CLAGS) main.c -o mainram.o

test: 
	cd tests && $(MAKE)	

clean:
	rm -r *.o *.a ./tests/test_main ./tests/test_multiprocess ./tests/test_linux ./tests/test_child
