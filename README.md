# cocoapods-lhj-bin
pod 插件用法

## 1.安装pod插件
```
gem install cocoapods-aomi-bin
```

### 1.1初始化仓库与OSS等信息，命令行执行
```
pod bin init --bin-url=http://aomi-ios-repo.oss-cn-shenzhen.aliyuncs.com/bin_dev.yml
```
## 2.提取项目中源码的中文字符串，并生成中英文对照csv文件
### 2.1定位到项目根目录，执行pod bin fetch --file-name=xxx，在当前目录生成中英文对照csv，在此cvs上添加英文翻译，修改自定义key值，删掉不需转换的行
```
pod bin fetch --file-name=MacauLife_cn_en
```


## 3.同步csv文件到云端
### 3.1编辑完转换csv文件后，使用同步命令pod bin local upload --upload-file=MacauLife_cn_en, 同步文档到云端
```
pod bin local upload --upload-file=MacauLife_cn_en
```

### 3.2查看oss列表

## 4.根据中英文对照csv文件，生成国际化配置、批量更新源码 
### 4.1下载云端cvs文件(支持多个文件)，执行pod bin local --download-csv=MacauLife_cn_en，生成国际化文件

### 4.2 在4.1功能基础上，批量更新源码国际化key值 
```
pod bin local --download-csv=MacauLife_cn_en --modify-source
```

### 4.3 国际化默认替换字符串为NSLocalizedString(%s, @"")，其中%s为国际化key所对应的占位符，可通过参数设置 --modify-format-string=NSLocalizedString(%s, @"")
 
## 5.微服务改名(aomi-xxx改成ott-xxx)
### 5.1 命令行定位到项目根目录的Code文件下(与service_map.csv在同一目录)，执行
```
pod bin service
```

## 6.自动化生成模型，传入接口url，生成oc模型源码


# --model-pre 参数指定生成模型对象的前缀，若不指定则默认为ML
```shell
pod bin model --model-pre=TO http://yapi.miguatech.com/mock/178/service/interface/bbeActivity/storeList
```

## 7.简繁转换工具
### 7.1定位需要转换文件夹下，执行
#### 转繁体
```
pod bin trans
```

##### 转简体
```
pod bin trans --zh-cn
```

#### 指定转换文件的类型,默认类型m,h,pch,xib
```shell
pod bin trans --file-type=m,h
```
