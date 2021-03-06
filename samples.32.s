/* defines.h */

SYS_exit		= 1
SYS_fork		= 2
SYS_write		= 4
SYS_open		= 5
SYS_close		= 6
SYS_execve 		= 11
SYS_lseek		= 19
SYS_dup2		= 63
SYS_mmap 		= 90
SYS_munmap		= 91
SYS_socketcall		= 102
SYS_socketcall_socket	= 1
SYS_socketcall_bind	= 2
SYS_socketcall_listen	= 4
SYS_socketcall_accept	= 5

SEEK_END		= 2
PROT_READ		= 1
MAP_SHARED		= 1

AF_INET			= 2
SOCK_STREAM		= 1
IPPROTO_TCP		= 6

STDOUT			= 1

# #####################################################
/* args.s */
# #####################################################

.text
.globl _start
_start:
	popl	%ecx		// argc
lewp:
	popl	%ecx		// argv
	test 	%ecx,%ecx
	jz	exit

	movl	%ecx,%ebx
	xorl	%edx,%edx
strlen:
	movb	(%ebx),%al
	inc	%edx
	inc	%ebx
	test	%al,%al
	jnz	strlen
	movb	$10,-1(%ebx)

// 	write(1,argv[i],strlen(argv[i]));
	movl	$SYS_write,%eax
	movl	$STDOUT,%ebx
	int	$0x80

	jmp	lewp
exit:
	movl	$SYS_exit,%eax
	xorl	%ebx,%ebx
	int 	$0x80
		
	ret

# #####################################################
/* daemon.s */
# #####################################################

BIND_PORT	= 0xff00	// 255

.data
SOCK:	.long 	0x0
LEN:	.long	0x10
SHELL:	.string "/bin/sh"

.text
.globl _start
_start:
	subl	$0x20,%esp 

//	socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);

	movl	$SYS_socketcall,%eax
	movl	$SYS_socketcall_socket,%ebx
	movl	$AF_INET,(%esp)
	movl	$SOCK_STREAM,0x4(%esp)
	movl 	$IPPROTO_TCP,0x8(%esp)
	movl	%esp,%ecx
	int	$0x80

// 	save sockfd
	movl	%eax,SOCK

	xorl	%edx,%edx
//	bind(%eax, %esp+0xc, 0x10);
	movw	$AF_INET,0xc(%esp)
	movw	$BIND_PORT,0xe(%esp)
	movl	%edx,0x10(%esp)
	movl	%eax,(%esp)
	leal	0xc(%esp),%ebx
	movl	%ebx,0x4(%esp)
	movl	$0x10,0x8(%esp)
	movl	$SYS_socketcall,%eax
	movl	$SYS_socketcall_bind,%ebx
	int 	$0x80

	movl	SOCK,%eax	

//	listen(%eax, 0x1);
	movl	%eax,(%esp)
	movl	$0x1,0x4(%esp)
	movl	$SYS_socketcall,%eax
	movl	$SYS_socketcall_listen,%ebx
	int 	$0x80

	movl	SOCK,%eax

//	accept(%eax, %esp+0xc, LEN);
	movl	%eax,(%esp)
	leal	0xc(%esp),%ebx
	movl	%ebx,0x4(%esp)
	movl	$LEN,0x8(%esp)
	movl	$SYS_socketcall,%eax
	movl	$SYS_socketcall_accept,%ebx
	int	$0x80

//	for(i=2;i>-1;;i--) dup2(%eax,i)
	movl	$0x2,%ecx
DUP2LOOP:
	pushl	%eax
	movl	%eax,%ebx
	movl	$SYS_dup2,%eax
	int	$0x80
	dec	%ecx
	popl	%eax
	jns	DUP2LOOP

//	execve(SHELL, { SHELL, NULL }, NULL );
	movl	$SYS_execve,%eax
	movl	$SHELL,%ebx
	movl	%ebx,(%esp)
	movl	%edx,0x4(%esp)
	movl	%esp,%ecx
	int	$0x80

//	_exit(0)
	movl	$SYS_exit,%eax
	movl	%edx,%ebx
	int	$0x80

	ret

# #####################################################
/* mmap.s */
# #####################################################

.data
fd:
	.long 	0
fdlen:
	.long 	0
mappedptr:
	.long 	0

.text
.globl _start
_start:
	subl	$24,%esp

//	open(file, O_RDONLY);
	movl	$SYS_open,%eax
	movl	32(%esp),%ebx	// argv[1] is at %esp+8+24
	xorl	%ecx,%ecx	// set %ecx to O_RDONLY, which = 0
	int 	$0x80

	test	%eax,%eax	// if return value < 0, exit
	js	exit

	movl	%eax,fd		// save fd

//	lseek(fd,0,SEEK_END);
	movl	%eax,%ebx
	xorl	%ecx,%ecx	// set offset to 0
	movl	$SEEK_END,%edx
	movl	$SYS_lseek,%eax
	int	$0x80

	movl	%eax,fdlen	// save file length

	xorl	%edx,%edx

//	mmap(NULL,fdlen,PROT_READ,MAP_SHARED,fd,0);
	movl	%edx,(%esp)
	movl	%eax,4(%esp)
	movl	$PROT_READ,8(%esp)
	movl	$MAP_SHARED,12(%esp)
	movl	fd,%eax
	movl	%eax,16(%esp)
	movl	%edx,20(%esp) 

	movl	$SYS_mmap,%eax
	movl	%esp,%ebx
	int	$0x80

	movl	%eax,mappedptr	// save ptr
		
// 	write(STDOUT, mappedptr, fdlen);
	movl	$STDOUT,%ebx
	movl	%eax,%ecx
	movl	fdlen,%edx
	movl	$SYS_write,%eax
	int	$0x80

//	munmap(mappedptr, fdlen);
	movl	mappedptr,%ebx
	movl	fdlen,%ecx
	movl	$SYS_munmap,%eax
	int	$0x80

//	close(fd);
	movl	fd,%ebx		// load file descriptor
	movl	$SYS_close,%eax
	int	$0x80
exit:
//	exit(0);
	movl	$SYS_exit,%eax
	xorl	%ebx,%ebx
	int	$0x80

	ret

# #####################################################
/* socket.s */
# #####################################################

.text
.globl	_start
_start:
	sub	$12,%esp

//	socket(AF_INET,SOCK_STREAM,IPPROTO_TCP);
	movl	$AF_INET,(%esp)
	movl	$SOCK_STREAM,4(%esp)
	movl	$IPPROTO_TCP,8(%esp)

	movl	$SYS_socketcall,%eax
	movl	$SYS_socketcall_socket,%ebx
	movl	%esp,%ecx
	int	$0x80

	movl 	$SYS_exit,%eax
	xorl 	%ebx,%ebx
	int 	$0x80
	ret

# #####################################################
/* write.s */
# #####################################################

.data
hello:
	.string "hello world\n"
.text
.globl _start
_start:
	movl	$SYS_write,%eax	// SYS_write = 4
	movl	$STDOUT,%ebx	// fd = fileno(stdio)
	movl	$hello,%ecx	// buf = str
	movl	$12,%edx	// count = 0x6
	int	$0x80

	movl	$SYS_exit,%eax
	xorl	%ebx,%ebx
	int	$0x80
	ret

/* fini */

