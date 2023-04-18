#include <stdio.h>
#include <curses.h> // that is for netbsd - use ncurses.h on gnu/linux
#include <string.h> //strlen()
#include <stdlib.h> //system()

void print_menu(int highlight);

void menu_handler(int selected_item);
void display_text(char* support_file_path);

struct menu_ui {
    char *choices;
    int upper_left_point_x;
    int upper_left_point_y;
};
