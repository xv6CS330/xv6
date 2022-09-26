#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(){
    
    ps();
    // -----------waitpid() test function -----------------
    // int pid = fork();
    // int* ptr = (int*)malloc(sizeof(int));


    // if(pid == 0){
    //     // while(1);
    //     printf("Child %d\n", getpid());
    // }
    // else{
    //     int p = fork();
    //     if(p == 0){
    //         while(1);
    //         printf("Child %d\n", getpid());
    //     }
    //     else{
    //         printf("%d", wait(ptr));
    //         printf("%d", waitpid(p, ptr));
    //         printf("%d", pid);
    //         printf("Hey i am in Parent");
    //     }
    // }
    // -----------getpa() test function -----------------
    // int a = 0;
    // int b = 0;
    // printf("%p\n", getpa(&a));
    // printf("%p\n", getpa(&b));

    // ------getppid() test function -----------------
    // int* ptr = (int*)malloc(sizeof(int));
    // printf("My Parent Pid: %d\n", getppid());
    // printf("Parent Pid: %d\n", getpid());
    // if(fork()==0){
    //     sleep(5);
    //     printf("My Pid: %d\n", getpid());
    //     printf("My parent Pid: %d\n", getppid());
    // }
    // wait(ptr);
    exit(0);
}