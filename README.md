# FluxTime - 基于UCEVI评分系统的时间管理APP

## 项目简介

FluxTime是一款基于UCEVI评分系统的「时间-精力-待办」三位一体管理应用，帮助用户科学管理时间、优化精力分配、高效完成任务。

### 核心功能

1. **待办/目标管理模块**
   - 支持添加任务名称、所属目标、截止日期、预估耗时
   - UCEVI五维评分：紧急度(Urgent)、花费(Cost)、努力(Effort)、价值(Value)、影响(Impact)
   - 支持编辑、删除、标记完成

2. **UCEVI智能评分模块**
   - 自动计算综合评分：`UCEVI = (U×0.25 + C×0.15 + E×0.15 + V×0.25 + I×0.20) × 10`
   - 按评分高低排序展示
   - 支持筛选高优先级任务

3. **时间记录模块**
   - 手动记录时间戳+事件描述
   - 6大分类：主要工作、日常生活、自我提升、健康、人际关系、休息
   - 生成时间分布饼图

4. **精力管理模块**
   - 按5分钟时段标记精力高低
   - 自动生成多日平均精力曲线
   - 推荐高精力时段匹配高评分任务

5. **每日推荐模块**
   - 基于UCEVI评分和精力曲线智能推荐
   - 自动匹配最优待办安排

---

## 环境配置

### 1. 安装Flutter SDK

#### Windows系统

1. 下载Flutter SDK：
   ```bash
   # 访问官网下载最新稳定版
   https://docs.flutter.dev/get-started/install/windows
   
   # 或使用Git克隆
   git clone https://github.com/flutter/flutter.git -b stable
   ```

2. 配置环境变量：
   - 将Flutter的`bin`目录添加到系统PATH
   - 例如：`C:\flutter\bin`

3. 验证安装：
   ```bash
   flutter doctor
   ```

### 2. 安装Android Studio

1. 下载并安装Android Studio：https://developer.android.com/studio

2. 安装必要组件：
   - Android SDK
   - Android SDK Command-line Tools
   - Android SDK Build-Tools
   - Android Emulator（可选，用于测试）

3. 配置Flutter与Android Studio：
   ```bash
   flutter config --android-studio-dir="C:\Program Files\Android\Android Studio"
   flutter doctor --android-licenses
   ```

### 3. 验证环境

运行以下命令检查环境配置：
```bash
flutter doctor -v
```

确保所有项目都显示绿色勾号（✓）。

---

## 项目导入与运行

### 1. 导入项目

#### 方法一：使用Android Studio
1. 打开Android Studio
2. 选择 `File` -> `Open`
3. 选择项目目录 `fluxtime`
4. 等待Gradle同步完成

#### 方法二：使用VS Code
1. 安装Flutter和Dart插件
2. 打开项目文件夹 `fluxtime`
3. 按 `F5` 运行

### 2. 安装依赖

```bash
cd fluxtime
flutter pub get
```

### 3. 运行项目

#### 连接真机
1. 开启手机开发者模式和USB调试
2. 连接手机到电脑
3. 运行：
   ```bash
   flutter run
   ```

#### 使用模拟器
1. 创建Android模拟器：
   ```bash
   flutter emulators --create --name fluxtime_emulator
   ```
2. 启动模拟器：
   ```bash
   flutter emulators --launch fluxtime_emulator
   ```
3. 运行应用：
   ```bash
   flutter run
   ```

---

## 打包生成APK

### 方法一：命令行打包（推荐）

#### 1. 生成Release版APK

```bash
cd fluxtime
flutter build apk --release
```

生成的APK位于：
```
build/app/outputs/flutter-apk/app-release.apk
```

#### 2. 生成分架构APK（体积更小）

```bash
flutter build apk --split-per-abi --release
```

生成的APK：
- `app-armeabi-v7a-release.apk` - 32位ARM设备
- `app-arm64-v8a-release.apk` - 64位ARM设备（推荐）
- `app-x86_64-release.apk` - x86设备

### 方法二：Android Studio打包

1. 打开Android Studio
2. 选择 `Build` -> `Generate Signed Bundle/APK`
3. 选择 `APK` -> `Next`
4. 创建或选择密钥库（Keystore）
5. 选择 `release` 构建变体
6. 点击 `Finish`，等待构建完成

### 方法三：Gradle命令打包

```bash
cd fluxtime/android
./gradlew assembleRelease
```

APK输出位置：
```
app/build/outputs/apk/release/app-release.apk
```

---

## 签名配置（正式发布）

### 1. 创建密钥库

```bash
keytool -genkey -v -keystore fluxtime-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias fluxtime
```

### 2. 配置签名

在 `android/key.properties` 文件中添加：
```properties
storePassword=你的密钥库密码
keyPassword=你的密钥密码
keyAlias=fluxtime
storeFile=../fluxtime-release.jks
```

在 `android/app/build.gradle` 中添加签名配置：
```gradle
android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

---

## 测试说明

### 功能测试清单

#### 1. 待办管理测试
- [ ] 添加新任务，填写所有字段
- [ ] 编辑已有任务，修改UCEVI评分
- [ ] 标记任务完成/取消完成
- [ ] 删除任务
- [ ] 按评分/日期/名称排序
- [ ] 验证UCEVI评分计算正确

#### 2. 时间记录测试
- [ ] 添加时间记录
- [ ] 选择不同分类
- [ ] 设置时长
- [ ] 查看时间分布图表
- [ ] 删除时间记录

#### 3. 精力管理测试
- [ ] 标记精力时段（高/低）
- [ ] 查看今日精力曲线
- [ ] 查看多日平均曲线
- [ ] 使用快速填充功能
- [ ] 验证高精力时段推荐

#### 4. 每日推荐测试
- [ ] 查看推荐任务列表
- [ ] 验证推荐时间与精力曲线匹配
- [ ] 验证高评分任务优先推荐

#### 5. 统计分析测试
- [ ] 查看任务概览
- [ ] 查看UCEVI评分分布
- [ ] 查看时间使用统计
- [ ] 查看精力趋势
- [ ] 查看效率分析评分

### 运行单元测试

```bash
flutter test
```

### 运行集成测试

```bash
flutter test integration_test/
```

---

## 项目结构

```
fluxtime/
├── android/                 # Android原生配置
│   ├── app/
│   │   ├── build.gradle     # 应用级Gradle配置
│   │   └── src/main/
│   │       ├── AndroidManifest.xml
│   │       └── kotlin/      # Kotlin原生代码
│   ├── build.gradle         # 项目级Gradle配置
│   └── settings.gradle
├── lib/                     # Flutter源代码
│   ├── main.dart           # 应用入口
│   ├── models/             # 数据模型
│   │   ├── task.dart
│   │   ├── time_record.dart
│   │   └── energy_level.dart
│   ├── providers/          # 状态管理
│   │   ├── task_provider.dart
│   │   ├── time_record_provider.dart
│   │   └── energy_provider.dart
│   ├── screens/            # 页面
│   │   ├── home_screen.dart
│   │   ├── todo_screen.dart
│   │   ├── task_edit_screen.dart
│   │   ├── time_record_screen.dart
│   │   ├── energy_screen.dart
│   │   └── stats_screen.dart
│   ├── services/           # 服务层
│   │   ├── database_service.dart
│   │   └── ucevi_service.dart
│   └── widgets/            # 公共组件
│       ├── daily_recommendation.dart
│       ├── quick_stats.dart
│       └── time_distribution_chart.dart
├── pubspec.yaml            # 依赖配置
└── README.md               # 项目说明
```

---

## 依赖库

| 库名 | 版本 | 用途 |
|------|------|------|
| sqflite | ^2.3.0 | SQLite本地数据库 |
| provider | ^6.1.1 | 状态管理 |
| fl_chart | ^0.65.0 | 图表绘制 |
| intl | ^0.18.1 | 国际化日期格式 |
| uuid | ^4.2.1 | 唯一ID生成 |
| table_calendar | ^3.0.9 | 日历组件 |
| shared_preferences | ^2.2.2 | 本地存储 |

---

## 常见问题

### Q1: flutter pub get 失败
```bash
# 清理缓存后重试
flutter clean
flutter pub cache repair
flutter pub get
```

### Q2: Gradle构建失败
```bash
# 清理Gradle缓存
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### Q3: 签名APK安装失败
确保手机已开启"允许安装未知来源应用"。

### Q4: 模拟器启动失败
```bash
# 检查模拟器状态
flutter emulators
# 重启ADB服务
adb kill-server
adb start-server
```

---

## 技术支持

- Flutter官方文档：https://docs.flutter.dev
- Android开发文档：https://developer.android.com

---

## 版本历史

- v1.0.0 (2024)
  - 初始版本发布
  - 实现完整的UCEVI评分系统
  - 实现时间-精力-待办三位一体管理
