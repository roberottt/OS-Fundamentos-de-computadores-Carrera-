
//-------------------------------------------------------------------
void write_uart(unsigned int);

//-------------------------------------------------------------------
typedef unsigned int fix4_28;
void itoa(char *buf, unsigned int val)
{
    fix4_28 const f1_10000 = (1 << 28) / 10000;
    fix4_28 tmplo, tmphi;
    unsigned int i;

    unsigned int lo = val % 100000;
    unsigned int hi = val / 100000;

    tmplo = lo * (f1_10000 + 1) - (lo / 4);
    tmphi = hi * (f1_10000 + 1) - (hi / 4);

    for(i = 0; i < 5; i++)
    {
        buf[i + 0] = '0' + (char)(tmphi >> 28);
        buf[i + 5] = '0' + (char)(tmplo >> 28);
        tmphi = (tmphi & 0x0fffffff) * 10;
        tmplo = (tmplo & 0x0fffffff) * 10;
    }
    buf[10] = '\0';
}

//-------------------------------------------------------------------
void printString(char *str)
{
	while(*str != '\0')
		write_uart(*str++);
}

//-------------------------------------------------------------------
void printInt(unsigned int val)
{
	char str[11];
	itoa(str, val);
	printString(str);
}

//----------------------------------------------------------------------
int atoi(char *p) {
    int k = 0;
    while ( (*p - '0' >= 0) && (*p -'0' <= 9)) {
        k = (k << 3) + (k << 1) + (*p) - '0';
        p++;
     }
     return k;
}

//-----------------------------------------------------------------------
// Function to implement a variant of strncpy() function
char* strncpy(char* destination, const char* source, int num)
{
	// return if no memory is allocated to the destination
	if (destination == 0)
		return 0;

	// take a pointer pointing to the beginning of destination string
	char* ptr = destination;

	// copy first num characters of C-string pointed by source
	// into the array pointed by destination
	while (*source && num--)
	{
		*destination = *source;
		destination++;
		source++;
	}

	// null terminate destination string
	*destination = '\0';

	// destination is returned by standard strncpy()
	return ptr;
}

//-----------------------------------------------------------------------
// Compara dos cadenas
int strcmp(const char *c1, const char *c2) {
    char ret = *c1-*c2;
    while (ret == 0 && *c1 != 0) {
        c1 ++; c2++;
        ret = *c1 - *c2;
    }
    return ret;
}

//-----------------------------------------------------------------------
// Devuelve la longitud de una cadena
int strlen(const char *s) {
    int cont=0;
    while (*s != 0) {
        cont++;
        s++;
    }
    return cont;
}

//-----------------------------------------------------------------------
// Busca un caracter en una cadena. Devuelve la posicion de la primera ocurrencia
int find(const char c, char *s) {
    int cont = 0;
    while (*(s+cont)!= 0 && c != *(s+cont)) {
        cont++;
    }
    
    if (c != *(s+cont))
        return -1;
    
    return cont;
}

