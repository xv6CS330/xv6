#include "kernel/types.h"
#include "user/user.h"

int g (int x)
{
   return x*x;
}

int f (void)
{
   int x = 10;

   fprintf(2, "Hello world! %d\n", g(x));
   return 5;
}

int
main(void)
{
  int x = forkf(f);
  if (x < 0) {
    sleep(10);
     fprintf(2, "Error: cannot fork\nAborting...\n");
     exit(0);
  }
  else if (x > 0) {
     sleep(5);
     fprintf(1, "%d: Parent.\n", getpid());
     wait(0);
  }
  else {
     fprintf(1, "%d: Child.\n", getpid());
  }

  exit(0);
}
// // #include "kernel/types.h"
// // #include "kernel/procstat.h"
// // #include "user/user.h"

// // int
// // main(void)
// // {
// //   struct procstat pstat;

// //   int x = fork();
// //   if (x < 0) {
// //      fprintf(2, "Error: cannot fork\nAborting...\n");
// //      exit(0);
// //   }
// //   else if (x > 0) {
// //      sleep(5);
// //      fprintf(1, "%d: Parent.\n", getpid());
// //      if (pinfo(-1, &pstat) < 0) fprintf(1, "Cannot get pinfo\n");
// //      else fprintf(1, "pid=%d, ppid=%d, state=%s, cmd=%s, ctime=%d, stime=%d, etime=%d, size=%p\n",
// //          pstat.pid, pstat.ppid, pstat.state, pstat.command, pstat.ctime, pstat.stime, pstat.etime, pstat.size);
// //      if (pinfo(x, &pstat) < 0) fprintf(1, "Cannot get pinfo\n");
// //      else fprintf(1, "pid=%d, ppid=%d, state=%s, cmd=%s, ctime=%d, stime=%d, etime=%d, size=%p\n\n",
// //          pstat.pid, pstat.ppid, pstat.state, pstat.command, pstat.ctime, pstat.stime, pstat.etime, pstat.size);
// //      fprintf(1, "Return value of waitpid=%d\n", waitpid(x, 0));
// //   }
// //   else {
// //      fprintf(1, "%d: Child.\n", getpid());
// //      if (pinfo(-1, &pstat) < 0) fprintf(1, "Cannot get pinfo\n");
// //      else fprintf(1, "pid=%d, ppid=%d, state=%s, cmd=%s, ctime=%d, stime=%d, etime=%d, size=%p\n\n",
// //          pstat.pid, pstat.ppid, pstat.state, pstat.command, pstat.ctime, pstat.stime, pstat.etime, pstat.size);
// //   }

// //   exit(0);
// // }

// // // #include "kernel/types.h"
// // // #include "kernel/stat.h"
// // // #include "user/user.h"
// // // #include "kernel/procstat.h"

// // // int main(){

// // //     struct procstat pstat;

// // //     if (pinfo(-1, &pstat) < 0) fprintf(1, "Cannot get pinfo\n");
// // //     else fprintf(1, "pid=%d, ppid=%d, state=%s, cmd=%s, ctime=%d, stime=%d, etime=%d, size=%p\n",
// // //          pstat.pid, pstat.ppid, pstat.state, pstat.command, pstat.ctime, pstat.stime, pstat.etime, pstat.size);
// // //     // int i=0;
// // //     // while(i<100000)i++;
// // //     // if(fork()!=0){
// // //     //     sleep(10);
        
// // //     //     ps();
// // //     // }
// // //     // else{
// // //     //     sleep(10);
// // //     // }
    
// // //     // -----------waitpid() test function -----------------
// // //     // int pid = fork();
// // //     // int* ptr = (int*)malloc(sizeof(int));


// // //     // if(pid == 0){
// // //     //     // while(1);
// // //     //     printf("Child %d\n", getpid());
// // //     // }
// // //     // else{
// // //     //     int p = fork();
// // //     //     if(p == 0){
// // //     //         while(1);
// // //     //         printf("Child %d\n", getpid());
// // //     //     }
// // //     //     else{
// // //     //         printf("%d", wait(ptr));
// // //     //         printf("%d", waitpid(p, ptr));
// // //     //         printf("%d", pid);
// // //     //         printf("Hey i am in Parent");
// // //     //     }
// // //     // }


// // //     // -----------getpa() test function -----------------
// // //     // int a = 0;
// // //     // int b = 0;
// // //     // printf("VA:%p PA:%p\n", &a, getpa(&a));
// // //     // printf("VA:%p PA:%p\n", &b, getpa(&b));

// // //     // ------getppid() test function -----------------
// // //     // int* ptr = (int*)malloc(sizeof(int));
// // //     // printf("My Parent Pid: %d\n", getppid());
// // //     // printf("Parent Pid: %d\n", getpid());
// // //     // if(fork()==0){
// // //     //     sleep(5);
// // //     //     printf("My Pid: %d\n", getpid());
// // //     //     printf("My parent Pid: %d\n", getppid());
// // //     // }
// // //     // wait(ptr);
// // //     exit(0);
// // // }