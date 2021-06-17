// JavaScript Document
jQuery(function ()
{
    var width = 120, height = 100, death = 80, speed = 60;
    var interval = null, newborn = {}, rect;
    var mouseX = 0, mouseY = 0, mouseState = 3, keyAvaliable = true;
    var speedList = [4096, 3943, 3793, 3647, 3505, 3367, 3232, 3101, 2974, 2850, 2730, 2613, 2499, 2389,
                     2282, 2178, 2077, 1980, 1885, 1794, 1705, 1620, 1537, 1457, 1380, 1306, 1234, 1165,
                     1098, 1034, 973, 914, 857, 803, 751, 701, 654, 608, 565, 523, 484, 447, 411, 378, 346,
                     316, 287, 260, 235, 212, 190, 169, 150, 132, 115, 100, 86, 73, 61, 50, 40, 31, 23, 16]
    function update()
    // making an update
    {
        var r = 0;
        for(var i = width;i > 0;--i)
        {
            for(var j = height;j > 0;--j)
            {
                if(newborn.live[newborn.data[i % width * height + j % height]])
                {
                    newborn.tempX[r] = i;
                    newborn.tempY[r] = j;
                    ++r;
                }
            }
        }
        while(--r >= 0)
        {
            newborn.blockChange(newborn.tempX[r],newborn.tempY[r]);
        }
    }
    function between(min, value, max)
    // return integer value between max and min
    {
        return Math.max(min, Math.min(Math.floor(value), max));
    }
    function get(name)
    // get value from URL
    {
        var r = location.search.substr(1).match(new RegExp('(^|&)' + name + '=([^&]*)(&|$)', 'i'));
        return (r != null) ? unescape(r[2]) : null;
    }
    function control()
    // start or stop updating
    {
        return interval ? stop() : start();
    }
    function start()
    // start updating
    {
        if(!interval)
        {
            interval = setInterval(update, speedList[speed - 1]);
        }
    }
    function stop()
    // stop updating
    {
        if(interval)
        {
            clearInterval(interval);
            interval = null;
        }
    }
    function randomize()
    // randomize a new graph
    {
        for(var i = newborn.width;i > 0;--i)
        {
            for(var j = newborn.height;j > 0;--j)
            {
                if(100 * Math.random() > death ^ newborn.blockState(i, j))
                {
                    newborn.blockChange(i, j);
                }
            }
        }
    }
    function clean()
    // clean graph
    {
        for(var i = newborn.width;i > 0;--i)
        {
            for(var j = newborn.height;j > 0;--j)
            {
                if(newborn.blockState(i, j))
                {
                    newborn.blockChange(i, j);
                }
            }
        }
    }
    function resize()
    {
        $('#container').height($(document.body).height() - $('#panel').height() - $('#wrapper h3').height() - 40);
    }
    // initialization
    var x = Number(get('x')), y = Number(get('y')), d = Number(get('d')), s = Number(get('s'));
    !x || (width = between(2, x, 1024)), $('#x').val(width);
    !y || (height = between(2, y, 1024)), $('#y').val(height);
    !d || (death = between(0, d, 100)), $('#d').val(death);
    !s || (speed = between(1, s, 64)), $('#s').val(speed);
    life.call(newborn, 'container', width, height);
    randomize();
    if(!newborn)
    {
        document.getElementById('container').innerHTML = '<strong>æ‚¨çš„æµè§ˆå™¨ä¸æ”¯æŒæ­¤æ¸¸æˆï¼</strong>';
    }
    $(document).keydown(function (event)
            {
                if(keyAvaliable)
                {
                    switch(event.which)
                    {
                    case 13:
                    case 108:
                        if(event.ctrlKey)
                        {
                            start();
                        }
                        else if(event.shiftKey)
                        {
                            stop();
                        }
                        else
                        {
                            control();
                        }
                        break;
                    case 32:
                        stop();
                        update();
                        break;
                    case 82:
                        stop();
                        randomize();
                        break;
                    case 67:
                        stop();
                        clean();
                        break;
                    }
                }
            });
    $(newborn.canvas).mousedown(function (event)
            {
                var rect = newborn.canvas.getBoundingClientRect();
                mouseX = between(1, (event.clientX - 4 - ((8 + newborn.canvas.width) / rect.width) * rect.left) / newborn.directSize + 1, newborn.width);
                mouseY = between(1, (event.clientY - 4 - ((8 + newborn.canvas.height) / rect.height) * rect.top) / newborn.directSize + 1, newborn.height);
                newborn.mouseState = mouseState;
                newborn.onblockchange(mouseX, mouseY);
            }).mouseup(function (event)
            {
                newborn.mouseState = mouseX = mouseY = 0;
            }).mousemove(function (event)
            {
                var rect = newborn.canvas.getBoundingClientRect();
                var x = between(1, (event.clientX - 4 - ((8 + newborn.canvas.width) / rect.width) * rect.left) / newborn.directSize + 1, newborn.width);
                var y = between(1, (event.clientY - 4 - ((8 + newborn.canvas.height) / rect.height) * rect.top) / newborn.directSize + 1, newborn.height);
                if(x != mouseX || y != mouseY)
                {
                    newborn.onblockchange(mouseX = x, mouseY = y);
                }
            }).mouseout(function (event)
            {
               newborn.mouseState = mouseX = mouseY = 0;
            });
    $('#default').click(function (event)
            {
                $('#x').attr('disabled','disabled');
                $('#y').attr('disabled','disabled');
                $('#d').attr('disabled','disabled');
                $('#s').attr('disabled','disabled');
            });
    $('#clear').click(function (event)
            {
                stop();
                clean();
                $(this).blur();
            });
    $('#step').click(function (event)
            {
                stop();
                update();
                $(this).blur();
            });
    $('#start').click(function (event)
            {
                start();
                $(this).blur();
            });
    $('#stop').click(function (event)
            {
                stop();
                $(this).blur();
            });
    $('#random').click(function (event)
            {
                stop();
                randomize();
                $(this).blur();
            });
    $(window).resize(resize);
    $('#panel').accordion({active:2,collapsible:true,heightStyle:'content'}).on('accordionactivate', resize).accordion('option', 'active', 0);
    $('#options *, #panel h3:last').focus(function (event)
            {
                keyAvaliable = false;
            }).blur(function (event)
                {
                    keyAvaliable = true;
                });
    $('#wrapper').accordion({heightStyle:'fill'});
    $('input[type=submit], button').css('margin', '0.2em 0').button();
    $('#x-slider').slider({min:2,max:1024,value:width,slide:function (event, ui)
        {
            $('#x').val(ui.value);
        }});
    $('#y-slider').slider({min:2,max:1024,value:height,slide:function (event, ui)
        {
            $('#y').val(ui.value);
        }});
    $('#d-slider').slider({min:0,max:100,value:death,slide:function (event, ui)
        {
            $('#d').val(ui.value);
        }});
    $('#s-slider').slider({min:1,max:64,value:speed,slide:function (event, ui)
        {
            $('#s').val(ui.value);
        }});
    $('#x').spinner({min:2,max:1024,start:width}).bind('input propertychange spin', function (event, ui)
            {
                $('#x-slider').slider('value', ui.value);
            });
    $('#y').spinner({min:2,max:1024,start:height}).bind('input propertychange spin', function (event, ui)
            {
                $('#y-slider').slider('value', ui.value);
            });
    $('#d').spinner({min:0,max:100,start:death}).bind('input propertychange spin', function (event, ui)
            {
                $('#d-slider').slider('value', ui.value);
            });
    $('#s').spinner({min:1,max:64,start:speed}).bind('input propertychange spin', function (event, ui)
            {
                $('#s-slider').slider('value', ui.value);
            });
});