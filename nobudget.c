#include "nobudget.h"

int lenght = 0;
int longest = 0;

char title[] = "SNE Cloud - Innopolis University";
char footer[] = "powered by XEN ";
int left_column_length = 28;
struct menu_ui start_menu;
char *choices[] = {
	"NEW GUEST",
	"OPERATE GUESTS",
	"SUPPORT",
	"QUIT"};

int n_choices = sizeof(choices) / sizeof(char *);

int menu_is_active = 1;

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
		case 10:
		{
			// 10 is ENTER key ascii code
			choice = highlight;
			break;
		}
		case 27:
		{
			// 27 is ESC key ascii code
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
	for (i = 0; i < n_choices; ++i)
	{
		if (highlight == i + 1) /* High light the present choice */
		{
			attron(A_REVERSE);
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
		//"NEW GUEST"
		break;
	}
	case 2:
	{
		//"OPERATE GUESTS"
		syscall_output_example("ls -lh /home","last_console_output.txt");
		break;
	}
	case 3:
	{
		//"SUPPORT"
		// system("cat support.txt");
		display_support("support.txt");
		break;
	}
	case 4:
	{
		//"QUIT"
		exit(0);
		break;
	}
	default:
	{
		break;
	}
	}
}

void display_support(char *support_file_path)
{
	/* Displays content of support file on screen

	Called in:
		nobudget.c : menu_handler()
	Args:
		support_file_path(char *): a path to text file
	Returns:
		None
	*/

	//open a file
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

	// output the text line by line
	int current_line = 1;
	while ((read = getline(&line, &len, fp)) != -1)
	{
		mvprintw(current_line, 1, line);
		++current_line;
	}
	fclose(fp);
}

void syscall_output_example(char *command, char *temp_log_storage)
{

	FILE *fp; // stream of console std output
	FILE *log_file; // file you temporarily store output
	
	char line_in_console[1035];

	// Open file for writing
	log_file = fopen(temp_log_storage, "w");
	if (log_file == NULL)
	{
		exit(EXIT_FAILURE);
	}

	/* Open the command for reading. */
	fp = popen(command, "r");
	if (fp == NULL)
	{
		exit(EXIT_FAILURE);
	}

	/* Read the output a line at a time - output it. */
	while (fgets(line_in_console, sizeof(line_in_console) - 1, fp) != NULL)
	{
		fprintf(log_file, "%s", line_in_console);
	}

	/* close */
	pclose(fp);
	fclose(log_file);

	display_support(temp_log_storage);
}