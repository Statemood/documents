# How to Create a Bootable Install Drive for macOS High Sierra
# 制作 macOS High Sierra USB 安装盘

#### 1. Download macOS High Sierra from AppStore

#### 2. Create Bootable Install Drive

```shell
sudo /Applications/Install\ macOS\ High\ Sierra.app/Contents/Resources/createinstallmedia \
     --volume             \
     /Volumes/USB         \
     --applicationpath    \
     /Applications/Install\ macOS\ High\ Sierra.app
```

  - /Volumes/USB
    - USB Flash

