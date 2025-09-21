## TGS1000

网络游戏《千年-炎黄新章》TGS服务端源码，仅供学习参考。

推荐使用 [Delphi7](https://winworldpc.com/product/delphi/70) 编译。

### 项目结构

```
TGS1000/
├── *.pas              # 主程序源码文件
├── *.dfm              # 窗体设计文件
├── tgs1000.dpr        # 项目主文件
├── tgs1000.cfg.example # 编译器配置示例文件
├── build.bat          # 一键编译脚本
├── bin/               # 输出目录（已创建）
│   ├── tgs1000.exe    # 编译后的可执行文件
│   ├── game.ini       # 游戏配置文件
│   ├── Setting/       # 游戏设置
│   ├── Script/        # 游戏脚本
│   └── LOG/           # 运行日志
├── dcu/               # 编译单元文件（已创建）
├── Kor/               # 第三方库和组件
│   ├── 1000ydef/      # 游戏定义文件
│   ├── Common/        # 公共工具类
│   └── FastNet/       # 网络通信库
└── README.md
```

### 编译要求

- **开发工具**: [Delphi 7](https://winworldpc.com/product/delphi/70) 完整版
- **系统要求**: Windows XP/7/10/11
- **依赖**: BDE数据库引擎（随Delphi7安装）

### 编译方法

#### 🚀 一键编译（推荐）

使用提供的一键编译脚本，自动完成配置文件复制和编译：

```bash
# Windows下双击运行或在命令行执行
build.bat
```

脚本会自动：
- 检查并复制配置文件
- 创建必要的目录结构
- 执行编译过程
- 显示编译结果和错误信息

#### 1. 获取源码
```bash
git clone --recurse-submodules https://github.com/oiuv/TGS1000.git
git submodule update --init
```

#### 2. 手动编译

**方法1：Delphi7 IDE**
1. 启动Delphi7
2. 打开 `tgs1000.dpr`
3. Project → Build tgs1000 (Ctrl+F9)

**方法2：命令行**
```bash
# 复制配置文件
cp tgs1000.cfg.example tgs1000.cfg

# 直接编译（自动使用tgs1000.cfg）
dcc32 -B tgs1000.dpr
```

#### 3. 编译配置

**发布版本**（默认tgs1000.cfg）：
- 启用优化，关闭调试检查
- 输出：`bin\tgs1000.exe`
- 关键参数：
  - `-$O+` 启用代码优化
  - `-$D-` 关闭调试信息
  - `-$C-` 关闭断言检查
  - `-$R-` 关闭范围检查
  - `-$Q-` 关闭溢出检查
  - `-$A1` 1字节内存对齐
  - `-U".\Kor\..."` 单元搜索路径（.pas文件）
  - `-O".\Kor\..."` 对象文件搜索路径（.obj文件）
  - `-I".\Kor\..."` Include文件搜索路径（.inc文件）
  - `-R".\Kor\..."` 资源文件搜索路径（.res文件）
  - `-E"bin"` 可执行文件输出目录
  - `-N"dcu"` 编译单元输出目录
  - `-D_CHINA` 条件编译（中国简体版）

**调试版本**（可选）：
创建 `tgs1000.debug.cfg` 文件，推荐参数：
- `-$O-` 关闭代码优化（便于调试）
- `-$D+` 启用调试信息（生成调试符号）
- `-$C+` 启用断言检查（检查逻辑错误）
- `-$R+` 启用范围检查（检测数组越界）
- `-$Q+` 启用溢出检查（检测数值溢出）
- `-$T+` 启用类型检查（严格类型检查）
- `-vt` 显示详细编译信息

```bash
# 使用调试配置编译
dcc32 -B -@tgs1000.debug.cfg tgs1000.dpr
```

### 常见问题

- **缺少BDE**: 安装Delphi7时会自动安装
- **找不到单元**: 检查 `tgs1000.cfg` 中的路径配置
- **权限错误**: 以管理员身份运行编译器

### 相关项目

- [TGS1000y](https://github.com/oiuv/TGS1000y)
- [1000yTGS](https://github.com/oiuv/1000yTGS)
- [1000yPascal](https://github.com/oiuv/1000yPascal)