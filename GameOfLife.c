// #ifndef UNICODE
// #define UNICODE
// #endif

#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define GET_X_LPARAM(lp) ((int)(short)LOWORD(lp))
#define GET_Y_LPARAM(lp) ((int)(short)HIWORD(lp))
LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);

void FillSolidRect(HDC hDC, LPCRECT lpRect, COLORREF clr)
{
    SetBkColor(hDC, clr);
    ExtTextOut(hDC, 0, 0, ETO_OPAQUE, lpRect, NULL, 0, NULL);
}

HWND hwnd;

#define TIMER_ID 42

int blockSize, directSize, eraseSize;
int width, height;
int death;
// position for temp
int *tempX, *tempY;
// data for blocks and their neighbors
int *data;
// judgement for whether to survive
int live[1 << 9];

void clearRect(HDC hDC, int x, int y, int w, int h)
{
    RECT rect;
    rect.left = x;
    rect.top = y;
    rect.right = x + w;
    rect.bottom = y + h;
    FillSolidRect(hDC, &rect, RGB(255, 255, 255));
}
void fillRect(HDC hDC, int x, int y, int w, int h)
{
    RECT rect;
    rect.left = x;
    rect.top = y;
    rect.right = x + w;
    rect.bottom = y + h;
    FillSolidRect(hDC, &rect, RGB(0, 0, 0));
}

void init()
{
    char path[512];
    GetCurrentDirectory(sizeof(path), path);
    strcat(path, "/GameOfLife.ini");
    death = GetPrivateProfileInt("GameOfLife", "Death", 80, path);
    width = GetPrivateProfileInt("GameOfLife", "Width", 120, path);
    height = GetPrivateProfileInt("GameOfLife", "Height", 100, path);
    blockSize = GetPrivateProfileInt("GameOfLife", "BlockSize", 5, path);
    directSize = 1 + blockSize;
    eraseSize = 1 + directSize;
    tempX = VirtualAlloc(NULL, sizeof(int) * width * height, MEM_COMMIT, PAGE_READWRITE);
    tempY = VirtualAlloc(NULL, sizeof(int) * width * height, MEM_COMMIT, PAGE_READWRITE);
    data = VirtualAlloc(NULL, sizeof(int) * width * height, MEM_COMMIT, PAGE_READWRITE);
    for (int n = 0, m = 0, l = 0; n < 1 << 9; m = 0)
    {
        m += n >> 8 & 1;
        m += n >> 7 & 1;
        m += n >> 6 & 1;
        m += n >> 5 & 1;
        m += n >> 4 & 1;
        m += n >> 3 & 1;
        m += n >> 2 & 1;
        m += n >> 1 & 1;
        live[n] = m == 3 && l == 0 || m != 2 && m != 3 && l == 1;
        l = ++n & 1;
    }
    for (int i = width * height - 1; i >= 0; --i)
    {
        data[i] = 0;
        tempX[i] = tempY[i] = 0;
    }
}

// get block value (true or false), and x and y must be positive numbers(1, 2, ...)
int blockState(int x, int y)
{
    return data[x % width * height + y % height] & 1;
}

void draw(HDC hDC)
{
    for (int x = 0; x < width; x++)
    {
        for (int y = 0; y < height; y++)
        {
            if (blockState(x, y))
            {
                fillRect(hDC, 1 + x * directSize, 1 + y * directSize, blockSize, blockSize);
            }
            else
            {
                clearRect(hDC, x * directSize, y * directSize, eraseSize, eraseSize);
            }
        }
    }
}

// change block value, and x and y must be positive numbers(1, 2, ...)
void blockChange(int x, int y)
{
    x--, y--;
    data[x % width * height + y % height] ^= 256;
    data[++x % width * height + y % height] ^= 128;
    data[++x % width * height + y % height] ^= 64;
    data[x % width * height + ++y % height] ^= 32;
    data[x % width * height + ++y % height] ^= 16;
    data[--x % width * height + y % height] ^= 8;
    data[--x % width * height + y % height] ^= 4;
    data[x % width * height + --y % height] ^= 2;
    data[++x % width * height + y % height] ^= 1;
}

// randomize a new graph
void randomize()
{
    for (int i = width; i > 0; --i)
    {
        for (int j = height; j > 0; --j)
        {
            if (rand() % 100 > death ^ blockState(i, j))
            {
                blockChange(i, j);
            }
        }
    }
    InvalidateRect(hwnd, NULL, TRUE);
}
void clean()
// clean graph
{
    for (int i = width; i > 0; --i)
    {
        for (int j = height; j > 0; --j)
        {
            if (blockState(i, j))
            {
                blockChange(i, j);
            }
        }
    }
    InvalidateRect(hwnd, NULL, TRUE);
}

// making an update
void update()
{
    int r = 0;
    for (int i = width; i > 0; --i)
    {
        for (int j = height; j > 0; --j)
        {
            if (live[data[i % width * height + j % height]])
            {
                tempX[r] = i;
                tempY[r] = j;
                ++r;
            }
        }
    }
    while (--r >= 0)
    {
        blockChange(tempX[r], tempY[r]);
    }
    InvalidateRect(hwnd, NULL, TRUE);
}

void CALLBACK do_update(HWND h, UINT m, UINT_PTR p, DWORD d)
{
    update();
    // InvalidateRect(hwnd, NULL, TRUE);
}
int updateflag;
void autoupdate()
{
    if (!updateflag)
    {
        SetTimer(hwnd, TIMER_ID, 100, do_update);
        updateflag = 1;
    }
}

void stopautoupdate()
{
    // printf("stop\n");
    if (updateflag)
    {
        KillTimer(hwnd, TIMER_ID);
        updateflag = 0;
    }
}

void onleftclick(int x, int y)
{
    blockChange(x, y);
    InvalidateRect(hwnd, NULL, TRUE);
}

// int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PWSTR pCmdLine, int nCmdShow)
int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
    init();
    // randomize();
    // Register the window class.
    const char CLASS_NAME[] = "Sample Window Class";
    WNDCLASS wc = {};
    wc.hCursor = LoadCursor(NULL, MAKEINTRESOURCE(IDC_ARROW));
    wc.lpfnWndProc = WindowProc;
    wc.hInstance = hInstance;
    wc.lpszClassName = CLASS_NAME;
    RegisterClass(&wc);

    // Create the window.
    hwnd = CreateWindowEx(
        0,                          // Optional window styles.
        CLASS_NAME,                 // Window class
        "Learn to Program Windows", // Window text
        WS_OVERLAPPEDWINDOW,        // Window style
        // Size and position
        CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,
        NULL,      // Parent window
        NULL,      // Menu
        hInstance, // Instance handle
        NULL       // Additional application data
    );

    if (hwnd == NULL)
    {
        return 0;
    }

    ShowWindow(hwnd, nCmdShow);

    // Run the message loop.
    MSG msg = {};
    while (GetMessage(&msg, NULL, 0, 0))
    {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    return 0;
}
int mousedownflag = 0;
POINT lastpt;
LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
    POINT pt;
    switch (uMsg)
    {
    case WM_LBUTTONDOWN:
        pt.x = GET_X_LPARAM(lParam) / directSize;
        pt.y = GET_Y_LPARAM(lParam) / directSize;
        lastpt = pt;
        mousedownflag = 1;
        onleftclick(pt.x, pt.y);
        break;

    case WM_LBUTTONUP:
        lastpt.x = lastpt.y = 0;
        mousedownflag = 0;
        break;

    case WM_MOUSEMOVE:
        pt.x = GET_X_LPARAM(lParam) / directSize;
        pt.y = GET_Y_LPARAM(lParam) / directSize;
        if (mousedownflag && lastpt.x != pt.x && lastpt.y != pt.y)
        {
            lastpt = pt;
            onleftclick(pt.x, pt.y);
        }
        break;

    case WM_KEYDOWN:
        switch (wParam)
        {
        case VK_CONTROL:
            autoupdate();
            break;
        case VK_ESCAPE:
            stopautoupdate();
            break;
        // 清空
        case 'C':
            stopautoupdate();
            clean();
            break;
        // 重置
        case 'R':
            stopautoupdate();
            randomize();
            break;
        // 单步
        case VK_SPACE:
            stopautoupdate();
            update();
            break;
        }
        break;

    case WM_DESTROY:
        PostQuitMessage(0);
        break;

    case WM_PAINT:
    {
        PAINTSTRUCT ps;
        HDC hdc = BeginPaint(hwnd, &ps);
        int w = ps.rcPaint.right - ps.rcPaint.left;
        int h = ps.rcPaint.bottom - ps.rcPaint.top;
        HDC memdc = CreateCompatibleDC(hdc);
        HBITMAP membmp = CreateCompatibleBitmap(hdc, w, h);
        SelectObject(memdc, membmp);
        FillRect(memdc, &ps.rcPaint, (HBRUSH)(COLOR_WINDOW + 1));
        draw(memdc);
        BitBlt(hdc, ps.rcPaint.left, ps.rcPaint.top, w, h, memdc, 0, 0, SRCCOPY);
        DeleteDC(memdc);
        DeleteObject(membmp);
        // All painting occurs here, between BeginPaint and EndPaint.
        EndPaint(hwnd, &ps);
    }
    break;

    default:
        return DefWindowProc(hwnd, uMsg, wParam, lParam);
    }
    return 0;
}
