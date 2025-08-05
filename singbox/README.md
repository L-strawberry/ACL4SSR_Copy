# sing-box 配置及 Sub-Store 脚本

此仓库包含适配 sing-box v1.12 版本的配置文件，并提供了搭配 Sub-Store 使用的脚本操作。

## 配置文件

- **sing-box v1.12 配置**:

https://raw.githubusercontent.com/L-strawberry/ACL4SSR_Copy/refs/heads/main/singbox/sing-box.json

## Sub-Store 脚本操作

搭配 Sub-Store 使用的脚本，用于出站代理规则的配置。

- **Sub-Store 脚本**:

https://raw.githubusercontent.com/L-strawberry/ACL4SSR_Copy/refs/heads/main/singbox/tample.js#type=1&name=all&outbound=🕳Proxy|Emby|Final🕳ℹ️HongKong🏷ℹ️港|hk|hongkong|kong kong|🇭🇰🕳ℹ️Taiwan🏷ℹ️台|tw|taiwan|🇹🇼🕳ℹ️Japan🏷ℹ️日本|jp|japan|🇯🇵🕳ℹ️Telegram|Singapore🏷ℹ️^(?!.(?:us)).(新|sg|singapore|🇸🇬)🕳ℹ️United States🏷ℹ️美|us|unitedstates|united states|🇺🇸

### 脚本说明

此脚本定义了多个出站代理组，用于根据地理位置和特定服务进行流量分流。

**出站规则示例**:

* **🕳Proxy|Emby|Final🕳**: 默认代理、Emby 服务及最终回退规则。
* **ℹ️HongKong🏷ℹ️港|hk|hongkong|kong kong|🇭🇰**: 香港节点。
* **ℹ️Taiwan🏷ℹ️台|tw|taiwan|🇹🇼**: 台湾节点。
* **ℹ️Japan🏷ℹ️日本|jp|japan|🇯🇵**: 日本节点。
* **ℹ️Telegram|Singapore🏷ℹ️^(?!.*(?:us)).*(新|sg|singapore|🇸🇬)**: 新加坡节点。
* **ℹ️United States🏷ℹ️美|us|unitedstates|united states|🇺🇸**: 美国节点。

### 脚本参数说明

以下是 Sub-Store 脚本中可能使用的参数说明：

* **`type`**: 用于指定订阅类型。
  * `type=1`: 读取组合订阅中的节点（单订阅不需要设置此参数）。
* **`name`**: 用于指定订阅名称。
  * `name=all`: 读取组合订阅名称all内所有节点。
* **`outbound`**: 定义出站规则和节点筛选逻辑。
  * **语法**: `🕳<outbound_name>|<fallback_name>|...ℹ️<filter_regex>🏷ℹ️<node_match_regex>`
      * `🕳<outbound_name>|...`: `<outbound_name>` 是出站代理组的名称。可以有多个名称用 `|` 分隔，例如 `Proxy|Emby|Final`。
      * `ℹ️`: 表示后续的正则表达式忽略大小写。
      * `🏷`: 用于分隔出站名称和节点筛选规则。
      * `ℹ️<node_match_regex>`: 用于匹配节点名称的正则表达式。例如 `/港|hk|hongkong|kong kong|🇭🇰/i`。
      * `不筛选节点不需要给 🏷`: 如果不需要对节点进行筛选，则无需在 `outbound` 参数中提供 `🏷` 及其后面的内容。
  * **示例**:
      * `outbound=🕳Proxy|Emby|Final`: 将所有节点插入匹配 `Proxy,Emby,Final` 的 outbound 中（跟在 `🕳` 后面，不筛选节点不需要给 `🏷`）。
      * `outbound=🕳ℹ️HongKong🏷ℹ️港|hk|hongkong|kong kong|🇭🇰`: 将匹配 `/港|hk|hongkong|kong kong|🇭🇰/i` 的节点（跟在 `🏷` 后面，`ℹ️` 表示忽略大小写）插入匹配 `ℹ️HongKong` 的 outbound 中。
* **`includeUnsupportedProxy`**: 可选参数，用于包含官方/商店版不支持的协议（如 SSR）。
  * 用法: `&includeUnsupportedProxy=true`
* **`url`**: 支持传入订阅 URL。请记住 `url` 需要进行 `encodeURIComponent` 编码。
  * 示例: `http://a.com?token=123` 应使用 `url=http%3A%2F%2Fa.com%3Ftoken%3D123`

**重要提示**: 如果 `outbounds` 为空，脚本会自动创建 `COMPATIBLE(direct)` 以防止报错。


---

