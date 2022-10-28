#include <stdio.h>
#include <dirent.h>

int main(int argc, char** argv)
{
    struct dirent* dir = nullptr;
    DIR* dp = nullptr;

    dp = opendir(argc >= 2 ? argv[1] : "/");

    if (dp != nullptr) {
        while ( (dir = readdir(dp)) )
            if (strcmp(dir->d_name, ".") && strcmp(dir->d_name, "."))
                printf("ok");
    }

    closedir(dp);

    return 0;
}
