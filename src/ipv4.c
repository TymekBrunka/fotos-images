// #include <cstdlib>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <netdb.h>
// #include <stdio.h>
#include "ipv4.h"

i_pp get_ipv4() {
    char hostname[1024];
    struct addrinfo hints, *res, *p;
    int status;
    char ipstr[INET_ADDRSTRLEN];

    // Get the hostname
    gethostname(hostname, sizeof(hostname));

    // Set up hints for getaddrinfo
    memset(&hints, 0, sizeof hints);
    hints.ai_family = AF_INET; // Use IPv4
    hints.ai_socktype = SOCK_STREAM; // TCP

    // Get address info
    if ((status = getaddrinfo(hostname, NULL, &hints, &res)) != 0) {
        fprintf(stderr, "getaddrinfo error: %s\n", gai_strerror(status));
        return (i_pp){0, ""};
    }

    // Loop through all the results and get the first valid IP address
    for (p = res; p != NULL; p = p->ai_next) {
        struct sockaddr_in *ipv4 = (struct sockaddr_in *)p->ai_addr;
        inet_ntop(p->ai_family, &(ipv4->sin_addr), ipstr, sizeof ipstr);
        break; // We only want the first one
    }

    freeaddrinfo(res); // Free the linked list
    char* g = (char*)malloc(strlen(ipstr));
    for (int i = 0; i < strlen(ipstr); i++){
        g[i] = ipstr[i];
    }
    return (i_pp){strlen(ipstr), g};
    // }
}
