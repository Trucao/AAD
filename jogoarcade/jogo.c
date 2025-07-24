#include "address_map_arm.h"

void video_text(int, int, char *);
void video_box(int, int, int, int, short);

void my_srand(unsigned int seed);
unsigned int my_rand(void);
void format_score(char* buf, int score_val);

#define SCREEN_WIDTH 320
#define SCREEN_HEIGHT 240

#define BLACK 0x0000
#define WHITE 0xFFFF
#define YELLOW 0xFFE0
#define GREEN 0x07E0
#define SKY_BLUE 0x5CF9

#define BIRD_WIDTH 10
#define BIRD_HEIGHT 10
#define PIPE_WIDTH 20
#define PIPE_GAP 90

#define GRAVITY 1
#define JUMP_STRENGTH -5

typedef struct {
    int x;
    int y;
    int vy;
} Bird;

typedef struct {
    int x;
    int gap_y;
    int scored;
} Pipe;

volatile int * KEY_ptr = (int *)KEY_BASE;
volatile int * SW_ptr = (int *)SW_BASE;
volatile int * pixel_ctrl_ptr = (int *)PIXEL_BUF_CTRL_BASE;
int pixel_buffer_start;
Bird bird;
Pipe pipes[2];
int score;
int game_over;
static unsigned int random_seed;

void setup();
void loop();
void initialize_game();
void draw_bird();
void erase_bird();
void update_bird();
void initialize_pipes();
void draw_pipes();
void erase_pipes();
void update_pipes();
void check_collision();
void wait_for_vsync();
void clear_screen();
void draw_score();
void clear_text();

int main(void) {
    setup();
    while (1) {
        loop();
    }
    return 0;
}

void setup() {
    my_srand(*SW_ptr);

    *(pixel_ctrl_ptr + 1) = FPGA_PIXEL_BUF_BASE;
    wait_for_vsync();
    pixel_buffer_start = *pixel_ctrl_ptr;
    clear_screen();

    *(pixel_ctrl_ptr + 1) = FPGA_PIXEL_BUF_BASE;
    pixel_buffer_start = *(pixel_ctrl_ptr + 1);
    clear_screen();

    initialize_game();
}

void loop() {
    int prev_bird_y = bird.y;

    if ((*KEY_ptr & 0b0001) != 0) {
        if (!game_over) {
            bird.vy = JUMP_STRENGTH;
        }
    }

    if ((*KEY_ptr & 0b1000) != 0) {
        if (game_over) {
            initialize_game();
        }
    }

    if (!game_over) {
        erase_bird(prev_bird_y);
        erase_pipes();

        update_bird();
        update_pipes();
        check_collision();

        draw_pipes();
        draw_bird();
        draw_score();
    } else {
        char final_score_text[20];
        video_text(35, 29, "Game Over");
        format_score(final_score_text, score);
        video_text(35, 31, final_score_text);
        video_text(28, 33, "Press KEY3 to restart");
    }

    wait_for_vsync();
    pixel_buffer_start = *(pixel_ctrl_ptr + 1);
}

void my_srand(unsigned int seed) {
    random_seed = seed;
}

unsigned int my_rand(void) {
    random_seed = 1664525 * random_seed + 1013904223;
    return random_seed;
}


char* int_to_str(int n, char* buf) {
    char temp_buf[10]; 
    int i = 0;

    if (n == 0) {
        *buf++ = '0';
        *buf = '\0';
        return buf;
    }

    while (n > 0) {
        temp_buf[i++] = (n % 10) + '0';
        n /= 10;
    }

    while (i > 0) {
        *buf++ = temp_buf[--i];
    }
    *buf = '\0';
    return buf;
}

void format_score(char* buf, int score_val) {
    char* prefix = "Score: ";
    while (*prefix) {
        *buf++ = *prefix++;
    }

    int_to_str(score_val, buf);
}

void initialize_game() {
    clear_screen();
    bird.x = 50;
    bird.y = SCREEN_HEIGHT / 2;
    bird.vy = JUMP_STRENGTH;
    score = 0;
    game_over = 0;
    initialize_pipes();
}

void draw_bird() {
    video_box(bird.x, bird.y, bird.x + BIRD_WIDTH - 1, bird.y + BIRD_HEIGHT - 1, YELLOW);
}

void erase_bird(int y) {
    video_box(bird.x, y, bird.x + BIRD_WIDTH - 1, y + BIRD_HEIGHT - 1, SKY_BLUE);
}

void update_bird() {
    bird.vy += GRAVITY;
    if (bird.vy > 5) {
        bird.vy = 5;
    }

    bird.y += bird.vy;

    if (bird.y < 0) {
        bird.y = 0;
        bird.vy = 0;
    }
}

void initialize_pipes() {
    pipes[0].x = SCREEN_WIDTH;
    pipes[0].gap_y = (my_rand() % (SCREEN_HEIGHT - PIPE_GAP)) + PIPE_GAP / 2;
    pipes[0].scored = 0;

    pipes[1].x = SCREEN_WIDTH + (SCREEN_WIDTH / 2) + (PIPE_WIDTH / 2);
    pipes[1].gap_y = (my_rand() % (SCREEN_HEIGHT - PIPE_GAP)) + PIPE_GAP / 2;
    pipes[1].scored = 0;
}

void draw_pipes() {
    int i;
    for (i = 0; i < 2; ++i) {
        video_box(pipes[i].x, 0, pipes[i].x + PIPE_WIDTH - 1, pipes[i].gap_y - (PIPE_GAP / 2), GREEN);
        video_box(pipes[i].x, pipes[i].gap_y + (PIPE_GAP / 2), pipes[i].x + PIPE_WIDTH - 1, SCREEN_HEIGHT - 1, GREEN);
    }
}

void erase_pipes() {
    int i;
    for (i = 0; i < 2; ++i) {
        video_box(pipes[i].x, 0, pipes[i].x + PIPE_WIDTH - 1, pipes[i].gap_y - (PIPE_GAP / 2), SKY_BLUE);
        video_box(pipes[i].x, pipes[i].gap_y + (PIPE_GAP / 2), pipes[i].x + PIPE_WIDTH - 1, SCREEN_HEIGHT - 1, SKY_BLUE);
    }
}

void update_pipes() {
    int i;
    for (i = 0; i < 2; ++i) {
        pipes[i].x -= 1;

        if (pipes[i].x + PIPE_WIDTH < 0) {
            pipes[i].x = SCREEN_WIDTH;
            pipes[i].gap_y = (my_rand() % (SCREEN_HEIGHT - PIPE_GAP)) + PIPE_GAP / 2;
            pipes[i].scored = 0;
        }

        if (!pipes[i].scored && pipes[i].x + PIPE_WIDTH < bird.x) {
            score++;
            pipes[i].scored = 1;
        }
    }
}

void check_collision() {
    int i;
    if (bird.y + BIRD_HEIGHT > SCREEN_HEIGHT) {
        game_over = 1;
        return;
    }

    for (i = 0; i < 2; ++i) {
        if (bird.x + BIRD_WIDTH > pipes[i].x && bird.x < pipes[i].x + PIPE_WIDTH) {
            if (bird.y < pipes[i].gap_y - (PIPE_GAP / 2) || bird.y + BIRD_HEIGHT > pipes[i].gap_y + (PIPE_GAP / 2)) {
                game_over = 1;
                return;
            }
        }
    }
}

void wait_for_vsync() {
    *pixel_ctrl_ptr = 1;
    while ((*(pixel_ctrl_ptr + 3) & 1) != 0);
}

void video_box(int x1, int y1, int x2, int y2, short pixel_color) {
    int row, col;

    if (x1 < 0) x1 = 0;
    if (y1 < 0) y1 = 0;
    if (x2 >= SCREEN_WIDTH) x2 = SCREEN_WIDTH - 1;
    if (y2 >= SCREEN_HEIGHT) y2 = SCREEN_HEIGHT - 1;

    for (row = y1; row <= y2; row++) {
        for (col = x1; col <= x2; ++col) {
            volatile short *pixel_ptr = (short *)(pixel_buffer_start + (row << 10) + (col << 1));
            *pixel_ptr = pixel_color;
        }
    }
}

void clear_screen() {
    clear_text();
    video_box(0, 0, SCREEN_WIDTH - 1, SCREEN_HEIGHT - 1, SKY_BLUE);
}

void draw_score() {
    char score_text[15];
    format_score(score_text, score);
    video_text(2, 2, score_text);
}

void video_text(int x, int y, char * text_ptr) {
    int offset;
    volatile char * character_buffer = (char *)FPGA_CHAR_BASE;

    offset = (y << 7) + x;
    while (*(text_ptr)) {
        *(character_buffer + offset) = *(text_ptr);
        ++text_ptr;
        ++offset;
    }
}

void clear_text() {
    int x, y;
    for (x = 0; x < 80; x++) {
        for (y = 0; y < 60; y++) {
            video_text(x, y, " ");
        }
    }
}