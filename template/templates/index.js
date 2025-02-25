const { app, BrowserWindow, Tray, Menu } = require('electron');
const path = require('path');
const package = require('./package.json');
const fs = require('fs');

let tray = null;
let win = null;

// 标记是否正在退出应用
app.isExiting = false;

const createWindow = () => {
    const isChinese = ['zh', 'zh-CN', 'zh-HK', 'zh-TW'].indexOf(app.getLocale()) >= 0;
    win = new BrowserWindow({
        autoHideMenuBar: true,
        icon: './icon.png',
        title: isChinese ? package.title_cn : package.title
    });
    win.loadURL(package.homepage);
    win.webContents.on('did-finish-load', function () {
        if (fs.existsSync("./userscripts") && fs.statSync("./userscripts").isDirectory()) {
            fs.readdirSync("./userscripts").forEach(path => {
                const inject_source_code = fs.readFileSync(`./userscripts/${path}`).toString();
                win.webContents.executeJavaScript(inject_source_code);
            });
        }
    });

    // 窗口关闭事件处理
    win.on('close', (event) => {
        if (!app.isExiting) {
            // 非退出情况下隐藏窗口
            event.preventDefault();
            win.hide();
        }
        // 退出时由 before-quit 事件处理
    });
};

const createTray = () => {
    tray = new Tray(path.join(__dirname, 'icon.png')); 
    const contextMenu = Menu.buildFromTemplate([
        {
            label: '打开主窗口',
            click: () => {
                if (win) {
                    win.show();
                } else {
                    createWindow(); // 如果窗口被销毁，重新创建
                }
            }
        },
        {
            label: '退出',
            click: () => {
                app.isExiting = true;
                // 关闭所有窗口（触发 close 事件）
                BrowserWindow.getAllWindows().forEach(window => {
                    window.destroy();
                });
                app.quit();
            }
        }
    ]);
    tray.setToolTip(package.name);
    tray.setContextMenu(contextMenu);

    // 左键点击托盘图标：切换窗口显示/隐藏
    tray.on('click', () => {
        if (win) {
            if (win.isVisible()) {
                win.hide();
            } else {
                win.show();
            }
        } else {
            createWindow(); // 如果窗口不存在则创建
        }
    });
};

app.whenReady().then(() => {
    createWindow();
    createTray();

    app.on('activate', () => {
        if (BrowserWindow.getAllWindows().length === 0) {
            createWindow();
        }
    });
});

// 在应用退出前标记状态
app.on('before-quit', () => {
    app.isExiting = true;
});

// 处理所有窗口关闭事件（仅限非macOS）
app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') {
        app.quit();
    }
});

app.setName(package.name);