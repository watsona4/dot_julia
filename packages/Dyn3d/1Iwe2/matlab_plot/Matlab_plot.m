% This file plots body chain position in figure or movie
clc;clear;

system = load('verts_i.mat');

% plot using artic_movie_3d
artic_movie_3d(system, 2, 'savemovie', 'movie.avi');
