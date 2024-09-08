#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <netdb.h>

int main() {
    struct addrinfo hints, *res, *p;
    char ipstr[INET_ADDRSTRLEN];
    int status;

    // Set up the hints structure
    memset(&hints, 0, sizeof hints);
    hints.ai_family = AF_INET; // Use IPv4
    hints.ai_socktype = SOCK_STREAM; // TCP

    // Get the local hostname
    char hostname[256];
    gethostname(hostname, sizeof(hostname));

    // Get the address info
    if ((status = getaddrinfo(hostname, NULL, &hints, &res)) != 0) {
        fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(status));
        return 1;
    }

    // Loop through all the results and print the first valid IP address
    for (p = res; p != NULL; p = p->ai_next) {
        void *addr;
        // Get the pointer to the address itself
        struct sockaddr_in *ipv4 = (struct sockaddr_in *)p->ai_addr;
        addr = &(ipv4->sin_addr);

        // Convert the IP to a string and print it
        inet_ntop(p->ai_family, addr, ipstr, sizeof ipstr);
        printf("Local IPv4 Address: %s\n", ipstr);
        break; // Print only the first address
    }

    freeaddrinfo(res); // Free the linked list
    return 0;
}

