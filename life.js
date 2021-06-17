// JavaScript Document
// no use for jQuery
function life(container, width, height) {
    this.width = width;
    this.height = height;
    // width and height
    this.blockSize = 1 + Math.ceil(64 / Math.sqrt(Math.sqrt(width * height)));
    this.directSize = 1 + this.blockSize;
    this.eraseSize = 1 + this.directSize;
    // size for filling, locating, and erasing
    this.tempX = new Array(width * height);
    this.tempY = new Array(width * height);
    // position for temp
    this.data = new Array(width * height);
    // data for blocks and their neighbors
    this.live = new Array(1 << 9);
    // judgement for whether to survive
    this.mouseX = 0;
    this.mouseY = 0;
    this.mouseState = 0;
    // state of the mouse pointer(0: mouseout, 1:fill, 2:erase, 3:reverse)
    this.canvas = document.createElement('canvas');
    // canvas
    try {
        this.ctx = this.canvas.getContext('2d');
    }
    catch (e) {
        return null;
    }
    // canvas context
    this.blockState = function (x, y)
    // get block value (true or false), and x and y must be positive numbers(1, 2, ...)
    {
        return Boolean(this.data[x % width * height + y % height] & 1);
    }
    this.blockChange = function (x, y)
    // change block value, and x and y must be positive numbers(1, 2, ...)
    {
        if (this.blockState(x--, y--)) {
            this.ctx.clearRect(x * this.directSize, y * this.directSize, this.eraseSize, this.eraseSize);
        }
        else {
            this.ctx.fillRect(1 + x * this.directSize, 1 + y * this.directSize, this.blockSize, this.blockSize);
        }
        this.data[x % width * height + y % height] ^= 256;
        this.data[++x % width * height + y % height] ^= 128;
        this.data[++x % width * height + y % height] ^= 64;
        this.data[x % width * height + ++y % height] ^= 32;
        this.data[x % width * height + ++y % height] ^= 16;
        this.data[--x % width * height + y % height] ^= 8;
        this.data[--x % width * height + y % height] ^= 4;
        this.data[x % width * height + --y % height] ^= 2;
        this.data[++x % width * height + y % height] ^= 1;
    }
    this.onblockchange = function (x, y)
    // judging whether block should be changed
    {
        if (x > 0 && y > 0 && x <= width && y <= width) {
            if (this.blockState(x, y) && (this.mouseState & 2) || !this.blockState(x, y) && (this.mouseState & 1)) {
                this.blockChange(x, y);
            }
        }
    }
    // initialization
    this.canvas.width = width * this.directSize + 1;
    this.canvas.height = height * this.directSize + 1;
    this.canvas.style.border = 'solid 4px #ccc';
    this.canvas.style.cursor = 'crosshair';
    this.ctx.fillStyle = '#000';
    document.getElementById(container).innerHTML = '';
    document.getElementById(container).appendChild(this.canvas);
    for (var n = 0, m = 0, l = 0; n < 1 << 9; m = 0) {
        m += n >> 8 & 1;
        m += n >> 7 & 1;
        m += n >> 6 & 1;
        m += n >> 5 & 1;
        m += n >> 4 & 1;
        m += n >> 3 & 1;
        m += n >> 2 & 1;
        m += n >> 1 & 1;
        this.live[n] = m == 3 && l == 0 || m != 2 && m != 3 && l == 1;
        l = ++n & 1;
    }
    for (var i = width * height - 1; i >= 0; --i) {
        this.data[i] = 0;
        this.tempX[i] = this.tempY[i] = 0;
    }
}
