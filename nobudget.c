#include "nobudget.h"

int lenght = 0;
int longest = 0;

char title[] = "Definitely Not a Cloud";
char domain[] = "angrycow.ru";
char footer[] = "nobudget v0.0 alpha";
int left_column_length = 28;
struct menu_ui start_menu;
char *choices[] = {
	"N E W   G U E S T",
        "M A N A G E   G U E S T S",
        "S U P P O R T",
	"Q U I T"};

int n_choices = sizeof(choices) / sizeof(char *);

int menu_is_active = 1;

int main()
{
	int highlight = 1;
	int choice = 0;
	int c;

	initscr();

	// debug mode allows ^C ^Z
	cbreak();
	//raw();

	keypad(stdscr, TRUE);
	noecho();
	curs_set(0);

	int i;
	for (i = 0; i < n_choices; ++i)
	{
		lenght = strlen(choices[i]);
		if (lenght > longest)
			longest = lenght;
	}

	print_menu(highlight);
	while (menu_is_active)
	{
		c = getch();
		switch (c)
		{
		case KEY_UP:
			if (highlight > 1)
				--highlight;
			break;
		case KEY_DOWN:
			if (highlight < n_choices)
				++highlight;
			break;
		// ascii code for ENTER
		case 10:
		{
			choice = highlight;
			break;
		}
		// ascii code for ESC
		case 27:
		{
			menu_is_active = 0;
			break;
		}
		}
		print_menu(highlight);
		menu_handler(choice);
		choice = 0;
		// if(choice != 0)	/* User did a choice come out of the infinite loop */
		// 	break;
	}
	// restore initial terminal settings
	endwin();
	return 0;
}

void print_menu(int highlight)
{
	int x, y, i;

	erase();

	attron(A_BOLD);
	mvprintw(0, (COLS - strlen(title)) / 2 - 2, "%s", title);
	attroff(A_BOLD);

	x = (COLS - longest) / 2 - 2;
	y = (LINES - n_choices) / 2 - 1 ;
	for (i = 0; i < n_choices; ++i)
	{
		if (highlight == i + 1) /* High light the present choice */
		{
			attron(A_REVERSE);
			mvprintw(y, x, "%s", choices[i]);
			attroff(A_REVERSE);
		}
		else
		{
			mvprintw(y, x, "%s", choices[i]);
		}
		// we want an empty line between the menu entries
		++y;
		++y;
	}

	mvprintw(LINES - 1, 1, "%s", domain);
	mvprintw(LINES - 1, COLS - strlen(footer) - 1, "%s", footer);

	refresh();
}

void menu_handler(int selected_item)
{
	/* Processes user's menu item choice

	Called in:
		nobudget.c : main()
	Args:
		selected_item(int): a number of menu item selected
	Returns:
		None
	*/
	switch (selected_item)
	{
	case 1:
	{
		// NEW GUEST
		endwin();
		system("/home/xen/nobudget/newguest.bash");
		exit(0);
	}
	case 2:
	{
		// MANAGE GUESTS
		endwin();
		system("/home/xen/nobudget/manage-guests.bash");
		exit(0);
	}
	case 3:
	{
		// SUPPORT
		display_text("support.txt");
		break;
	}
	case 4:
	{
		// QUIT
		endwin();
		exit(0);
	}
	default:
	{
		// IDLING
		break;
	}
	}
}

void display_text(char *support_file_path)
{
	/* Displays content of support file on screen

	Called in:
		nobudget.c : menu_handler()
	Args:
		support_file_path(char *): a path to text file
	Returns:
		None
	*/

	// open a file
	FILE *fp;
	char *line = NULL;
	size_t len = 0;
	ssize_t read;
	fp = fopen(support_file_path, "r");

	// handle an exceprion when file cannot be opened
	if (fp == NULL)
	{
		exit(EXIT_FAILURE);
	}

	// clear screen before printing output
	erase();

	// output the text line by line
	int current_line = 1;
	while ((read = getline(&line, &len, fp)) != -1)
	{
		mvprintw(current_line, 1, line);
		++current_line;
	}
	fclose(fp);
}
