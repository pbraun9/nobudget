#include <stdio.h>
#include <ncurses.h>
#include <string.h> //strlen()
#include <stdlib.h> //system()


void print_menu(int highlight);



void menu_handler(int selected_item);
void display_support(char* support_file_path);
void syscall_output_example(char* command, char* temp_log_storage);

struct menu_ui {
    char *choices;
    int upper_left_point_x;
    int upper_left_point_y;
};