'use strict';

const Figures = (function () {

    let figures = {};

    function Figure(id,style) {
        if (id in figures) {
            return figures[id];
        } else {
            const figure = d3.select('body').append('div')

            Object.keys(style).forEach(key => {
                figure.style(key,style[key])
            })

            figure.on('mousedown', function() {
                figure.node().parentNode.appendChild(figure.node())
            })

            const menubar = figure.append('div')
                .style('position','absolute')
                .style('height',"30px")
                .style('width',style.width)

            let clicks = 0, delay = 400
            menubar.on('mousedown', function() {
                d3.event.preventDefault();
                clicks++;

                setTimeout(function() {
                    clicks = 0;
                }, delay)

                if (clicks === 2) {                    
                    close(id);
                    clicks = 0;
                    return;
                } else {
                    figure.node().parentNode.appendChild(figure.node());
                }
            })
    
            menubar.call(d3.drag()
                .subject(function() { 
                    let x0 = menubar.style('left');
                    let y0 = menubar.style('top');
                    return {x: x0.substring(0,x0.length-2)*1, y: y0.substring(0,y0.length-2)*1};
                })
                .on('drag', function() {
                    let mx = menubar.style('left');
                    let my = menubar.style('top');
                    mx = mx.substring(0,mx.length-2)*1.0;
                    my = my.substring(0,my.length-2)*1.0;

                    let fx = figure.style('left');
                    let fy = figure.style('top');
                    fx = fx.substring(0,fx.length-2)*1.0;
                    fy = fy.substring(0,fy.length-2)*1.0;

                    d3.event.sourceEvent.stopPropagation();
                    figure.style('left', (fx+d3.event.x-mx)+'px')
                    figure.style('top', (fy+d3.event.y-my)+'px')
                })
            );
            
            const plot = figure.append('div').attr('id',id)
            plot
                .style('position','relative')
                .style('top','30px')

            figures[id] = figure;
            return figure;
        }
    }

    function closeall() {
        Object.keys(figures).forEach(id => {
            figures[id].remove();
            delete figures[id];
        })
    }

    function close(id) {
        figures[id].remove();
        delete figures[id];
    }

	const addget = function (c, name) {
		Object.defineProperty(c, name, {
			get: function () { return eval(name); },
			enumerable: true,
			configurable: true
		});
		return c;
	};

    let c = {};
    c = addget(c, 'figures');
    c = addget(c, 'Figure');
    c = addget(c, 'closeall');
    c = addget(c, 'close');
	return c;
})();
