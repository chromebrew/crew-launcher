#include <stdio.h>
#include <sys/inotify.h>

int main(int argc, char **argv) {
  char buf[sizeof(struct inotify_event)];
  struct inotify_event *event;
  int fd = inotify_init();
  int wd = inotify_add_watch(fd, "/home/chronos", IN_ACCESS);

  while (1) {
    int len = read(fd, buf, sizeof(buf));
  
  }
  return 0;
}