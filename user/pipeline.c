#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char *argv[]){
    int fd[2];
    int* ptr = (int*)malloc(sizeof(int));

    if(argc!=3){
        printf("Error: Enter both the values n and x\n");
        exit(0);
    }

    if(pipe(fd)<0){
        printf("Error in opening the pipe\n");
        exit(0);
    }

    int n = atoi(argv[1]);
    if(n<=0){
        printf("n must be a positive integer\n");
        exit(0);
    }
    int x = atoi(argv[2]);

    while(n--){
        int t = fork();
        if(n>1 && t==0){
            read(fd[0], &x, sizeof(int));
            close(fd[0]);
            close(fd[1]);
            pipe(fd);
        }
        else{
            int currPid = getpid();
            printf("%d: %d\n", getpid(), x+currPid);
            x += currPid;
            write(fd[1], &x, sizeof(int));
            close(fd[0]);
            close(fd[1]);
            wait(ptr);
            break;
        }
    }
    exit(0);
}