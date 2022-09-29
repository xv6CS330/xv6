#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int primes[]={2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61,67,71,73,79,83,89,97};

int main(int argc, char *argv[]){
    int fd[2];
    int* ptr = (int*)malloc(sizeof(int));

    if(argc!=2){
        printf("Error: Enter value of n\n");
        exit(1);
    }

    int n = atoi(argv[1]);
    if(n<2 || n>100){
        printf("Error: n value should be between 2 to 100\n");
        exit(2);
    }

    if(pipe(fd)<0){
        printf("Error in opening the pipe\n");
        exit(3);
    }

    int index = 0;
    int buffer[2];
    int receivBuf[2];

    while(n>1){
        int t = fork();
        if(t==0){
            close(fd[1]);

            read(fd[0], receivBuf, sizeof(receivBuf));
            n = receivBuf[0];
            index = receivBuf[1];

            close(fd[0]);
            pipe(fd);
        }
        else{
            close(fd[0]);
            int flag=0;
            if(n%primes[index]==0)flag = 1;

            while(n%primes[index]==0){
                printf("%d, ",primes[index]);
                n /= primes[index];
            }
            if(flag==1) printf("[%d]\n", getpid());

            buffer[0] = n;
            buffer[1] = index+1;
            write(fd[1], buffer, sizeof(buffer));

            close(fd[1]);
            wait(ptr);
            break;
        }
    }

    exit(0);
}