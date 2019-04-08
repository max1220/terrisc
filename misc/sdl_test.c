

#include <stdio.h>
#include <stdlib.h>
#include <SDL2/SDL.h>


void main() {
	SDL_Window *window;
	SDL_Surface *screen;
	SDL_Rect rect;
	SDL_Event event;

	uint run = 1;

	rect.w = 100;
	rect.h = 100;

	SDL_Init(SDL_INIT_VIDEO);

	window = SDL_CreateWindow("hello world!",0, 0, 800, 600, 0);

	screen = SDL_GetWindowSurface(window);

	while (run) {

		rect.x = rand() % 700;
		rect.y = rand() % 500;

		SDL_FillRect(screen, &rect, rand());

		SDL_UpdateWindowSurface(window);

		while (SDL_PollEvent(&event)) {
			if (event.type == SDL_QUIT){
				run = 0;
			}
		}

	}

}

