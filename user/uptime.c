#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char *argv[]){
    printf("Uptime:%d\n", uptime());
    exit(0);
}