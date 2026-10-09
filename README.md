# 摄影风格 iOS App（Shalielie）

把 iPhone 旧机型照片"移植"上新摄影风格调色板（含 iOS 27 质感/颗粒）的原生 App。
选照片 → 发到你电脑上的本地服务器处理 → 自动存回相册。

> 本工程编译出**未签名 .ipa**，需要用爱思助手 + 你的 Apple ID 免费签名安装（7 天有效，到期一键续签）。
> 这是 Apple 允许的免费签名通道，不需要付费开发者账号。

---

## 目录结构

```
Shalielie-iOS/
├── Shalielie/                  # App 源码
│   ├── ShalielieApp.swift      # 全部逻辑（选照片/上传/保存）
│   ├── Info.plist              # 权限与配置
│   └── Assets.xcassets/        # App 图标
├── project.yml                 # XcodeGen 工程定义
└── .github/workflows/build.yml # GitHub Actions 一键构建脚本
```

## 步骤一：用 GitHub 免费构建 .ipa（一次，约 10 分钟）

1. 注册/登录 [GitHub](https://github.com)（免费）。
2. 点右上角 **+ → New repository**，名字随意（如 `shalielie-ios`），选 **Public**，创建。
3. 在仓库页面点 **Add file → Upload files**，把本文件夹里**除 README 外的全部内容**拖进去上传（保留目录结构：`Shalielie/`、`project.yml`、`.github/workflows/build.yml`）。
4. 打开仓库的 **Actions** 页 → 左侧选中 **Build Shalielie IPA** → 右侧 **Run workflow** → 绿色按钮确认。
5. 等 5–8 分钟构建完成（黄灯转绿灯），点进该次运行 → 底部 **Artifacts** → 下载 **Shalielie-ipa**，解压得到 `Shalielie.ipa`。

> 构建失败就把 Actions 里的红色日志发我，我来修。常见原因是 Xcode 版本差异导致的编译报错。

## 步骤二：爱思助手签名安装（一次，约 5 分钟）

1. 电脑装 [爱思助手](https://www.i4.cn/)（Windows 版）。
2. iPhone 用数据线连电脑，手机上点"信任此电脑"。
3. 爱思助手 → 左侧 **工具箱** → **IPA 签名**。
4. **添加 IPA 文件** → 选 `Shalielie.ipa`。
5. 勾选该 IPA → 选择 **使用 Apple ID 签名** → **添加 Apple ID** → 填你的 Apple ID（可用 QQ 邮箱等任意 Apple ID）和密码 → 确认。
6. 点 **开始签名**，完成后点 **安装**，App 就会装到你 iPhone 上。
7. 手机上 设置 → 通用 → VPN 与设备管理 → 信任 你的 Apple ID 开发者证书。

## 步骤三：使用

1. 电脑上先启动服务器（`Shalielie-快捷指令版` 里的 `Start Shalielie Server.cmd`），窗口会显示 IP 和端口。
2. 打开 iPhone 上的 **摄影风格** App：
   - 服务器地址填：`http://<电脑IP>:8765/patch`（状态页显示的地址）
   - 点 **从相册选择照片**，选一张 iPhone 拍的 HEIC 原片
3. 处理完自动保存回相册，去照片编辑里就能看到摄影风格调色板。

## 注意事项

- **只支持 iPhone 拍摄的 HEIC**：JPEG/PNG 等其他格式无法套用（工具技术边界），App 会显示服务器返回的中文原因。
- **Apple ID 免费签名 7 天过期**：到期后 App 打不开，用爱思助手重新签名安装即可（设置里保存了 Apple ID，一键续签）。重装会清掉 App 里填的服务器地址，重填一次。
- **服务器要开着**：App 处理照片依赖你电脑上运行的本地服务器，手机和电脑要在同一 Wi-Fi。
- **隐私**：照片只发到你自己的电脑，不要填别人服务器地址。
