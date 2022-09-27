#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char *argv[]){

    int* ptr = (int*)malloc(sizeof(int));

    if(argc!=3){
        printf("Error: Program requires to enter both the values of m and n\n");
        exit(0);
    }

    int m = atoi(argv[1]);
    int n = atoi(argv[2]);

    if(m<=0){
        printf("Error: Enter positive value of m\n");
        exit(0);
    }

    if(n!=0 && n!=1){
        printf("Error: n should be 0 or 1\n");
        exit(0);
    }

    int p = fork();

    if(n==0){
        if(p==0){
            sleep(m);
            printf("%d: Child.\n",getpid());
        }
        else{
            printf("%d: Parent.\n",getpid());
            wait(ptr);
        }
    }
    else if(n==1){
        if(p==0){
            printf("%d: Child.\n",getpid());
        }
        else{
            sleep(m);
            printf("%d: Parent.\n",getpid());
        }
    }

    exit(0);
}

