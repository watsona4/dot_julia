function [] = artic_movie_3d(varargin)
%ARTIC_MOVIE_3D Show movie of articulated body dynamics
%
% DESCRIPTION
%   ARTIC_MOVIE_3D(system) shows a movie of the articulated body
%   motion, as described in the solution structure system.soln. The system
%   data is contained in system. The solution array is interpolated onto a
%   uniform time grid of the same duration and length.
%
%   ARTIC_MOVIE_3D(system,nskip) skips over nskip time steps between movie
%   frames.
%
%   ARTIC_MOVIE_3D(t,system) displays the system at time t (assuming that t
%   falls inside the solution range).
%
%   ARTIC_MOVIE_3D(....,'savemovie',filename) saves the movie to an avi file
%   with the specified name
%
%   Modified from script by Prof. Eldredge

% Set some defaults for plot labeling
set(0,'defaulttextinterpreter','latex')
set(0,'DefaultTextFontname', 'CMU Serif')
set(0,'DefaultAxesFontName', 'CMU Serif')

%% Parse the inputs
snapshot = false;
savemovie = false;
nskip = 1;
argnum = 1;
if isnumeric(varargin{argnum})
    % The first argument is time
    tsnap = varargin{argnum};
    snapshot = true;
    argnum = argnum + 1;
end
if isstruct(varargin{argnum})
    system = varargin{argnum};
    argnum = argnum + 1;
else
    error('myApp:argChk', 'Invalid argument');
end
if argnum <= nargin
    % Check if nskip is present
    if isnumeric(varargin{argnum})
        nskip = varargin{argnum};
        argnum = argnum + 1;
    end
end
while argnum <= nargin
    % Check the remaining arguments
    nrem = nargin-argnum+1;
    if (mod(nrem,2)~=0)
         error('myApp:argChk', 'Wrong number of input arguments');
    end
    chgtag = varargin{argnum};
    chgval = varargin{argnum+1};
    switch lower(chgtag)
        case {'savemovie'}
            if ~ischar(chgval)
                error('myApp:argChk', 'Invalid file name');
            end
            moviefile = chgval;
            vp = VideoWriter(moviefile);
            open(vp);
            savemovie = true;
            argnum = argnum + 2;
        otherwise
            error('myApp:argChk', 'Unknown parameter');
    end
end

% Set up the figure
figure(1)
clf
axis equal

attach = 0;
center = 0;

%% Assign the system structure at the first time level

if system.ndim == 2
    % Get vertices in plane
    for k = 1:system.nbody
        hl(k) = line(system.verts{1,1}(k,2:3,1),system.verts{1,1}(k,2:3,2), ...
            'Color','r','LineWidth',2);
    end

    if attach == true
        % record movement of the first joint
        vert_ini = squeeze(system.verts{1,1}(1,:,:));
        h2(1) = line([vert_ini(2,1);vert_ini(2,1)], ...
                     [vert_ini(2,2);vert_ini(2,2)], ...
                'Color','b','LineWidth',1);
        for k = 2:system.nbody
            h2(k) = line([system.verts{1,1}(k,2,1);system.verts{1,1}(k-1,3,1)], ...
                         [system.verts{1,1}(k,2,2);system.verts{1,1}(k-1,3,2)], ...
                'Color','b','LineWidth',1);
        end
    end
    
    if center == true
        % plot center of mass
        x_c = 0.5*(system.verts{1,1}(1,2:3,1) + system.verts{1,1}(2,2:3,1));
        y_c = 0.5*(system.verts{1,1}(1,2:3,2) + system.verts{1,1}(2,2:3,2));
        h3 = line(x_c, y_c, 'Color','k','LineWidth',1);
        h4 = line([sum(x_c)/2 system.verts{1,1}(1,3,1)], ...
            [sum(y_c)/2 system.verts{1,1}(1,3,2)], ...
            'Color','k','LineWidth',1);
    end
    
    axis([-2 2 -1 1])
    xlabel('$x$'); ylabel('$y$')

else
    % Gather vertex and face data from system
    nverts = 0;
    for k = 1:system.nbody
        for jv = 1:system.nverts
            nverts = nverts + 1;
            verts(nverts,:) = system.verts{1,1}(k,jv,[3 1 2]);
            faces(k,jv) = nverts;
        end
    end
    h = patch('Faces',faces,'Vertices',verts,'FaceColor','c');

    axis([-2 2 -2 2 -1 1])
    xlabel('$z$'); ylabel('$x$'); zlabel('$y$');
    view(112,34)
%    view(122.5,14)
%    view(90,0)
%    view(0,90)
%    view(-27.5,30)
    grid on
    light
    lighting gouraud
end
set(gca,'FontName','Times','FontSize',14)

if savemovie
    currframe = getframe;
    writeVideo(vp,currframe);
end

%% Update the system structure at the rest time levels
for j = 2:floor(length(system.t)/nskip)

    jj = 1 + nskip*(j-1);
    % Update the system structure at this time level

    if system.ndim == 2
        % Get vertices in plane
        for k = 1:system.nbody
            hl(k).XData = system.verts{jj,1}(k,2:3,1);
            hl(k).YData = system.verts{jj,1}(k,2:3,2);
        end
        
        if attach == true
            % update movement of the first joint
            h2(1).XData = [vert_ini(2,1);system.verts{jj,1}(1,2,1)];
            h2(1).YData = [vert_ini(2,2);system.verts{jj,1}(1,2,2)];
            for k = 2:system.nbody
                h2(k).XData = [system.verts{jj,1}(k,2,1);system.verts{jj,1}(k-1,3,1)];
                h2(k).YData = [system.verts{jj,1}(k,2,2);system.verts{jj,1}(k-1,3,2)];
            end
        end
        
        if center == true
            h3.XData = 0.5*(system.verts{jj,1}(1,2:3,1) + system.verts{jj,1}(2,2:3,1));
            h3.YData = 0.5*(system.verts{jj,1}(1,2:3,2) + system.verts{jj,1}(2,2:3,2));
            h4.XData = [sum(h3.XData)/2 system.verts{jj,1}(1,3,1)];
            h4.YData = [sum(h3.YData)/2 system.verts{jj,1}(1,3,2)];
        end
     
    else
        % Gather the vertex coordinates at this time and replace the patch
        % vertex data
        nverts = 0;
        for k = 1:system.nbody
            for jv = 1:system.nverts
                nverts = nverts + 1;
                verts(nverts,:) = system.verts{jj,1}(k,jv,[3 1 2]);
                faces(k,jv) = nverts;
            end
        end
        h.Vertices = verts;
    end

    % Draw to the screen
    drawnow

    if savemovie
        currframe = getframe;
        writeVideo(vp,currframe);
    end

    %pause(0.1)
end

if savemovie
    close(vp);
end
