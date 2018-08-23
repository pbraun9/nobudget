#include <stdio.h>
#include <ncurses.h>
#include <string.h> //strlen

int lenght = 0;
int longest = 0;

char title[]="SNE Cloud - Innopolis University";
char footer[]="powered by XEN ";

char *choices[] = { 
			"NEW GUEST",
			"OPERATE GUESTS",
			"SUPPORT",
			"QUIT",
		  };
int n_choices = sizeof(choices) / sizeof(char *);
void print_menu(int highlight);

int main()
{
	int highlight = 1;
	int choice = 0;
	int c;

	initscr();
	cbreak();
	//raw();
	keypad(stdscr, TRUE);
	noecho();
	curs_set(0);

	int i;
	for(i = 0; i < n_choices; ++i)
	{
	        lenght = strlen(choices[i]);
	        if (lenght > longest)
	                longest = lenght;
	}

	print_menu(highlight);
	while(1)
	{	c = getch();
		switch(c)
		{	case KEY_UP:
				if(highlight > 1)
					--highlight;
				break;
			case KEY_DOWN:
				if(highlight < n_choices)
					++highlight;
				break;
			case 10:
				choice = highlight;
				break;
		}
		print_menu(highlight);
		if(choice != 0)	/* User did a choice come out of the infinite loop */
			break;
	}	
	endwin();
	return 0;
}


void print_menu(int highlight)
{
	int x, y, i;	

	erase();

        attron(A_BOLD);
        mvprintw(0, (COLS - strlen(title)) / 2, "%s", title);
        attroff(A_BOLD);

        x = (COLS - longest) / 2;
        y = (LINES - n_choices) / 2;
	for(i = 0; i < n_choices; ++i)
	{	if(highlight == i + 1) /* High light the present choice */
		{	attron(A_REVERSE); 
			mvprintw(y, x, "%s", choices[i]);
			attroff(A_REVERSE);
		}
		else
			mvprintw(y, x, "%s", choices[i]);
		++y;
	}

	mvprintw(LINES - 1, COLS - strlen(footer), "%s", footer);

	refresh();
}
