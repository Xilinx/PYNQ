/*
Simple program to convert a dat file created with phoenix edid designer to 
a .txt file that can be used to define the contents of an EEPROM implemented in HDL
*/

#include <iostream>
#include <fstream>
#include <cstring>
#include <cstdlib>
#include <bitset>
using namespace std;

#define INPUT_DAT_LOC "C:\\Change_me.dat"
#define OUTPUT_TXT_LOC "C:\\Change_me.txt"

#define MAX_LINE_CNT 256

int main( int argc, char* argv[] )
{
	char lineBuf[MAX_LINE_CNT];
	char *token; 
	long int value;
	ifstream input_dat;
	ofstream output_txt;
	output_txt.open (OUTPUT_TXT_LOC);
	input_dat.open (INPUT_DAT_LOC);

	if (output_txt.fail()) 
	{	
		printf("\nfail\n");
		return 1;
	}
	if (input_dat.fail())
	{	
		printf("\nfail\n");
		return 1;
	}
	
	//Skip header
	input_dat.getline(lineBuf, MAX_LINE_CNT);
	input_dat.getline(lineBuf, MAX_LINE_CNT);
	input_dat.getline(lineBuf, MAX_LINE_CNT);

	for( int j=0 ; j < 8 ; j++)
	{

		input_dat.getline(lineBuf, MAX_LINE_CNT);

		//Discard address and "|" 
		token = strtok(lineBuf, " \n\r");
		token = strtok(NULL, " \n\r");
		for (int i=0 ; i < 16 ; i++)
		{
			token = strtok(NULL, " \n\r");
			if (token == NULL)
			{
				printf("error\n");
				return 1;
			}
			value = strtol(token, NULL, 16);
			output_txt << std::bitset<8>(value) << '\n';
		}
	}

	output_txt.close();
	input_dat.close();

	return 0;
}
