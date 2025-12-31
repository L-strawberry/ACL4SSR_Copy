# 📑使用 Sub-Store 生成 sing-box配置

利用Sub-Store文件页面生成适配 sing-box 的配置文件。

## 配置文件
填入Sub-Store远程订阅链接。

- **sing-box 配置:**
```
***
```
## Sub-Store 脚本操作

搭配 Sub-Store 使用的脚本，用于出站代理规则的配置。

- **Sub-Store 脚本**:
```
https://raw.githubusercontent.com/L-strawberry/ACL4SSR_Copy/refs/heads/main/singbox/tample.js#type=组合订阅&name=all&outbound=🕳ℹ️PROXY🏷ℹ️^(?!.*(EMBY|TW|Taiwan|台湾|JP|Japan|日本|HK|Hong Kong|港|US|United States|美|SG|Singapore|新|ADBLOCK|低倍率|low|0\.[0-9]0x)).*$🕳ℹ️EMBY🏷ℹ️低倍率|LOW|0\.[0-9]0x🕳ℹ️TW🏷ℹ️🇹🇼|台湾|taiwan|TW|tw|twn|台北|taipei|高雄|kaohsiung|台中|taichung|新北|new\s?taipei🕳ℹ️JP🏷ℹ️🇯🇵|日本|大版|JP|Japan🕳ℹ️HK🏷ℹ️🇭🇰|港|HK|Hong🕳ℹ️US🏷ℹ️🇺🇸|美|US|United?States|America🕳ℹ️SG🏷ℹ️🇸🇬|新加坡|坡|狮城|SG|Singapore🕳ℹ️ADBLOCK🏷ℹ️ADBLOCK
```
### 脚本参数说明

该脚本通过 URL 中 # 后的参数来传递配置信息。
| 参数 | 含义 | 示例值 |
|------|---------|-----------|
| **type** | 订阅类型：组合订阅或 subscription (单订阅) | 组合订阅 |
| **name** | 订阅在 Sub-Store 中的名称 | all |
| **outbound** | 核心参数，定义策略组名称及其节点筛选规则 | 见下文详解 |

### outbound 参数结构详解
`&outbound=🕳<策略组名称1><ℹ️>🏷<节点筛选正则1><ℹ️>🕳<策略组名称2><ℹ️>🏷<节点筛选正则2><ℹ️>...`

  `🕳 (分隔符)`： 用于分隔不同的策略组定义。每个策略组定义都以它开始。

<策略组名称><ℹ️>： 目标策略组的名称。ℹ️ 表示匹配该策略组时不区分大小写。

`🏷 (分隔符)`： 用于分隔策略组名称和其后的节点筛选正则表达式。

`<节点筛选正则><ℹ️>`： 用于匹配节点标签的正则表达式。ℹ️ 表示匹配该节点时不区分大小写。


**‼️重要提示**: 如果 `outbounds` 为空，脚本会自动创建 `COMPATIBLE(direct)` 以防止报错。


---

