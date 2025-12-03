// 花有重开日，人无再少年。
function main(config) {

  const ENABLED_CONDITIONAL_GROUPS = {
  //  ======= 策略组生成控制 =========
  //    - true: 创建策略组，并将策略组名称添加到 PROXY。
  //    - false: 跳过策略组创建，将该组的原始节点直接添加到 PROXY，确保节点可用性。
      HK: false,
      SG: false,
      JP: true,
      TW: true,
      US: false,
  };

  const rawProxies = Array.isArray(config.proxies) ? config.proxies : [];

  for (const key of Object.keys(config)) {
    delete config[key];
  }

  config.proxies = rawProxies;

  const PROMO_KEYWORDS = ["群", "邀请", "返利", "循环", "官网", "客服", "网站", "网址", "获取", "重置", "到期", "订阅", "流量", "到期", "机场", "下次", "版本", "官址", "备用", "过期", "已用", "联系", "邮箱", "工单", "贩卖", "通知", "倒卖", "防止", "国内", "地址", "无法", "说明", "使用", "提示", "特别", "访问", "支持", "教程", "关注", "更新", "作者", "加入", "节点", "\\bUSE\\b", "\\bUSED\\b", "\\bTOTAL\\b", "\\bEXPIRE\\b", "\\bEMAIL\\b", "\\bPanel\\b", "\\bChannel\\b", "\\bAuthor\\b"];

  const filterPromotionalProxies = (proxies) => {
    const promoRegex = new RegExp(
      PROMO_KEYWORDS.join("|") +
      "|\\b\\d{4}-\\d{2}-\\d{2}\\b" +
      "|\\b\\d+\\s*[GgTt]\\s*\\b",
      "gi"
    );
    const filteredProxies = proxies.filter(proxy => !promoRegex.test(proxy.name));
    return filteredProxies;
  };
  config.proxies = filterPromotionalProxies(config.proxies);

  const getProxyRateInfo = (name) => {
    const match = name.match(/(([\d\.]+)\s*(x|倍率)\s*)$/i);
    if (match) {
      return { rateStr: match[1].trim(), rateValue: parseFloat(match[2]) };
    }
    return { rateStr: "", rateValue: 1.0 };
  };

  const regionMap = {
    HK: { emoji: "🇭🇰", keywords: ["🇭🇰", "HK", "香港", "HONGKONG", "XIANGGANG"] },
    SG: { emoji: "🇸🇬", keywords: ["🇸🇬", "SG", "新加坡", "SINGAPORE"] },
    US: { emoji: "🇺🇸", keywords: ["🇺🇸", "US", "美国", "MEI", "AMERICA", "UNITEDSTATES"] },
    JP: { emoji: "🇯🇵", keywords: ["🇯🇵", "JP", "日本", "TOKYO", "JAPAN"] },
    TW: { emoji: "🇹🇼", keywords: ["🇹🇼", "TW", "台湾", "TAIWAN"] },
    KR: { emoji: "🇰🇷", keywords: ["🇰🇷", "KR", "韩国", "KOREA", "SEOUL"] },
    DE: { emoji: "🇩🇪", keywords: ["🇩🇪", "DE", "德国", "GERMANY"] },
    UK: { emoji: "🇬🇧", keywords: ["🇬🇧", "UK", "英国", "UNITEDKINGDOM"] },
    FR: { emoji: "🇫🇷", keywords: ["🇫🇷", "FR", "法国", "FRANCE"] },
    NL: { emoji: "🇳🇱", keywords: ["🇳🇱", "NL", "荷兰", "NETHERLANDS"] },
    MO: { emoji: "🇲🇴", keywords: ["🇲🇴", "MO", "澳门", "MACAO"] },
    RU: { emoji: "🇷🇺", keywords: ["🇷🇺", "RU", "俄罗斯", "RUSSIA"] },
    TH: { emoji: "🇹🇭", keywords: ["🇹🇭", "TH", "泰国", "THAILAND"] },
    VN: { emoji: "🇻🇳", keywords: ["🇻🇳", "VN", "越南", "VIETNAM"] },
    PH: { emoji: "🇵🇭", keywords: ["🇵🇭", "PH", "菲律宾", "PHILIPPINES"] },
  };
  const regionCodes = Object.keys(regionMap);
  
  const renameProxies = (proxies) => {
    const regionCounters = {};
    const emojiRegex = /^([^\w\s\d]+)/;
    const processedProxies = proxies.map(proxy => {
      let regionCode = "UNKNOW "; 
      let isClassified = false;
      const { rateStr, rateValue } = getProxyRateInfo(proxy.name);
      
      const cleanName = proxy.name.toUpperCase().replace(/[\s\-_]/g, '');

      const prefixMatch = proxy.name.match(emojiRegex);
      const originalPrefix = prefixMatch ? prefixMatch[1] : '';

      for (const code of regionCodes) {
        const keywords = regionMap[code].keywords.map(k => k.toUpperCase().replace(/[\s\-_]/g, ''));
        if (keywords.some(keyword => cleanName.includes(keyword))) {
          regionCode = code;
          isClassified = regionMap[code].emoji && (code === 'HK' || code === 'SG' || code === 'US' || code === 'JP' || code === 'TW');
          break;
        }
      }
      
      if (!isClassified && regionCode === "UNKNOW ") { 
        const unclassifiedCodeMatch = cleanName.match(/[A-Z]{2}/);
        if (unclassifiedCodeMatch) {
          regionCode = unclassifiedCodeMatch[0];
        } else {
          regionCode = "UNKNOW ";
        }
      }
      const counterKey = regionCode;
      if (!regionCounters[counterKey]) {
        regionCounters[counterKey] = 0;
      }
      regionCounters[counterKey]++;
      return {
        ...proxy,
        regionCode,
        isClassified,
        rateValue,
        rateStr,
        originalPrefix,
        originalName: proxy.name
      };
    });
    const newCounters = {};
    for (const code of Object.keys(regionCounters)) {
      newCounters[code] = 0;
    }
    processedProxies.forEach(p => {
      newCounters[p.regionCode]++;
      const index = String(newCounters[p.regionCode]).padStart(2, '0');

      const baseCode = p.regionCode; 

      let prefix = '';
      const regionInfo = regionMap[p.regionCode];

      if (regionInfo && regionInfo.emoji) {
        prefix = regionInfo.emoji;
      } else if (p.regionCode !== 'UNKNOW ') {
        prefix = p.originalPrefix || ''; 
      }
      
      let finalName = `${prefix}${baseCode}${index}${p.rateStr ? ' ' + p.rateStr : ''}`;
      
      finalName = finalName.replace(/[\u4e00-\u9fa5]/g, '');

      p.name = finalName;
    });

    return processedProxies;
  };

  config.proxies = renameProxies(config.proxies);

  const allProxies = config.proxies;
  const highRateProxies = allProxies
    .filter(p => p.rateValue > 1.0)
    .map(p => p.name)
    .sort();
  const lowRateProxies = allProxies
    .filter(p => p.rateValue < 1.0)
    .map(p => p.name)
    .sort();
  const normalRateProxiesObjects = allProxies
    .filter(p => p.rateValue === 1.0);
  const normalRateNames = normalRateProxiesObjects.map(p => p.name);
  const hkProxies = normalRateProxiesObjects.filter(p => p.regionCode === 'HK').map(p => p.name).sort();
  const sgProxies = normalRateProxiesObjects.filter(p => p.regionCode === 'SG').map(p => p.name).sort();
  const usProxies = normalRateProxiesObjects.filter(p => p.regionCode === 'US').map(p => p.name).sort();

  const jpProxies = normalRateProxiesObjects.filter(p => p.regionCode === 'JP').map(p => p.name).sort();
  const twProxies = normalRateProxiesObjects.filter(p => p.regionCode === 'TW').map(p => p.name).sort();

  const classifiedNormalNames = new Set([...hkProxies, ...sgProxies, ...usProxies, ...jpProxies, ...twProxies]);
  const unclassifiedProxies = normalRateNames.filter(name => name.startsWith("UNKNOW ")).sort();


  config.proxies.forEach(proxy => {
    delete proxy.regionCode;
    delete proxy.isClassified;
    delete proxy.rateValue;
    delete proxy.rateStr;
    delete proxy.originalPrefix;
    delete proxy.originalName;
  });


  config['mixed-port'] = 7890;
  config['allow-lan'] = true;
  config['bind-address'] = '*';
  config['find-process-mode'] = 'always';
  config.mode = 'rule';
  config['global-ua'] = 'clash.meta';
  config['etag-support'] = true;
  config['log-level'] = 'info';
  config.ipv6 = true;
  config['unified-delay'] = true;
  config['external-controller'] = '127.0.0.1:9090';
  config.secret = 'dlwlrma';
  config['tcp-concurrent'] = true;
  config['external-ui'] = 'ui';
  config['external-ui-url'] = 'https://github.com/Zephyruso/zashboard/releases/latest/download/dist.zip';
  config['global-client-fingerprint'] = 'chrome';

  config.profile = { 'store-selected': true, 'store-fake-ip': true };

  config.sniffer = { enable: true, "force-dns-mapping": true, "parse-pure-ip": true, "override-destination": true, sniff: { HTTP: { ports: [80, "8080-8880"], "override-destination": true }, TLS: { ports: [443, 8443] }, QUIC: { ports: [443, 8443] } }, "skip-src-address": ["192.168.0.3/32"], "skip-dst-address": ["192.168.0.3/32"], "skip-domain": ["RULE-SET:private", "Mijia Cloud", "+.push.apple.com"] };

  config.tun = { enable: true, device: "utun0", stack: "mixed", "auto-route": true, "auto-redirect": false, "auto-detect-interface": true, "dns-hijack": ["any:53", "tcp://any:53"], "strict-route": true, "route-exclude-address": ["192.168.0.0/16", "fc00::/7"] };

  config.dns = { enable: true, "cache-algorithm": "arc", "prefer-h3": false, "use-hosts": true, "use-system-hosts": true, "respect-rules": true, listen: "0.0.0.0:1053", ipv6: true, "ipv6-timeout": 600, "default-nameserver": ["https://223.5.5.5/dns-query", "https://120.53.53.53/dns-query"], "enhanced-mode": "fake-ip", "fake-ip-range": "198.18.0.0/15", "fake-ip-filter-mode": "blacklist", "fake-ip-filter": ["RULE-SET:private"], "nameserver-policy": { "+.arpa": "10.0.0.1", "RULE-SET:cn,private": ["https://223.5.5.5/dns-query", "https://120.53.53.53/dns-query"] }, nameserver: ["https://1.1.1.1/dns-query", "https://8.8.8.8/dns-query"], "direct-nameserver": ["https://223.5.5.5/dns-query", "https://120.53.53.53/dns-query"], "proxy-server-nameserver": ["https://223.5.5.5/dns-query", "https://120.53.53.53/dns-query"] };


  const ruleIPDefaults = { type: 'http', format: 'mrs', interval: 86400, behavior: 'ipcidr' };
  const ruleDomainDefaults = { type: 'http', format: 'mrs', interval: 86400, behavior: 'domain' };

  config['rule-providers'] = {
    adblock: { ...ruleDomainDefaults, url: 'https://raw.githubusercontent.com/217heidai/adblockfilters/main/rules/adblockmihomo.mrs' },
    emby: { ...ruleDomainDefaults, url: 'https://raw.githubusercontent.com/L-strawberry/ACL4SSR_Copy/main/Clash/emby.mrs' },
    emby_ip: { ...ruleIPDefaults, url: 'https://raw.githubusercontent.com/L-strawberry/ACL4SSR_Copy/main/Clash/emby_ip.mrs' },
    private: { ...ruleDomainDefaults, url: 'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/private.mrs' },
    private_ip: { ...ruleIPDefaults, url: 'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geoip/private.mrs' },
    telegram_ip: { ...ruleIPDefaults, url: 'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geoip/telegram.mrs' },
    telegram: { ...ruleDomainDefaults, url: 'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/telegram.mrs' },
    cn_ip: { ...ruleIPDefaults, url: 'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geoip/cn.mrs' },
    cn: { ...ruleDomainDefaults, url: 'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/cn.mrs' },
    youtube: { ...ruleDomainDefaults, url: 'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo-lite/geosite/youtube.mrs' },
    Gemini: { ...ruleDomainDefaults, url: 'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/google-gemini.mrs' },
    openai: { ...ruleDomainDefaults, url: 'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/openai.mrs' },
    cloudflare_ip: { ...ruleIPDefaults, url: 'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo-lite/geoip/cloudflare.mrs' },
    cloudflare: { ...ruleDomainDefaults, url: 'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo-lite/geosite/cloudflare.mrs' },
    google_ip: { ...ruleIPDefaults, url: 'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo-lite/geoip/google.mrs' },
    google: { ...ruleDomainDefaults, url: 'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo-lite/geosite/google.mrs' },
    github: { ...ruleDomainDefaults, url: 'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo-lite/geosite/github.mrs' },
    googlefcm: { ...ruleDomainDefaults, url: 'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/googlefcm.mrs' }
  };


  const urlSelectDefaults = { type: "select", url: 'https://www.gstatic.com/generate_204', interval: 300, lazy: false };

  const createdGroupNames = [];
  const otherConditionalGroups = [];
  const directNodesForPROXY = [];

  const regionGroupDefinitions = [
    { name: "TW", proxies: twProxies, icon: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/icon/qure/color/Taiwan.png" },
    { name: "JP", proxies: jpProxies, icon: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/icon/qure/color/Japan.png" },
    { name: "HK", proxies: hkProxies, icon: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/icon/qure/color/Hong_Kong.png" },
    { name: "SG", proxies: sgProxies, icon: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/icon/qure/color/Singapore" },
    { name: "US", proxies: usProxies, icon: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/icon/qure/color/United_States.png" },
  ];

  for (const def of regionGroupDefinitions) {
    const isEnabled = ENABLED_CONDITIONAL_GROUPS[def.name];
    const hasProxies = def.proxies.length > 0;

    if (isEnabled && hasProxies) {
      otherConditionalGroups.push({
        name: def.name,
        ...urlSelectDefaults,
        proxies: def.proxies,
        icon: def.icon
      });
      createdGroupNames.push(def.name);
    } else if (!isEnabled && hasProxies) {
      directNodesForPROXY.push(...def.proxies);
    } else {
    }
  }

  const rateGroupDefinitions = [
    { name: "RATE_HIGH", proxies: highRateProxies, icon: "https://raw.githubusercontent.com/lige47/QuanX-icon-rule/main/icon/Drunk.png" },
    { name: "LOW_RATE", proxies: lowRateProxies, icon: "https://raw.githubusercontent.com/fmz200/wool_scripts/main/icons/apps/HeartRate.png" },
  ];

  for (const def of rateGroupDefinitions) {
    if (def.proxies.length > 0) {
      otherConditionalGroups.push({
        name: def.name,
        ...urlSelectDefaults,
        proxies: def.proxies,
        icon: def.icon
      });
      createdGroupNames.push(def.name);
    } else {
    }
  }

  const finalGroups = [];

  const PROXYName = "PROXY";
  const PROXYProxies = [
    ...createdGroupNames,
    ...directNodesForPROXY,
    ...unclassifiedProxies,
    "DIRECT"
  ];

  const PROXYGroup = { name: PROXYName, ...urlSelectDefaults, proxies: PROXYProxies, icon: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/icon/qure/color/Auto.png" };
  finalGroups.push(PROXYGroup);


  const embyGroupProxies = [
    ...(createdGroupNames.includes("LOW_RATE") ? ["LOW_RATE"] : []),
    ...(createdGroupNames.includes("SG") ? ["SG"] : []),
    PROXYName,
    "DIRECT"
  ];
  const uniqueEmbyProxies = [...new Set(embyGroupProxies)];

  const embyGroup = { name: "EMBY", ...urlSelectDefaults, proxies: uniqueEmbyProxies, icon: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/icon/qure/color/Emby.png" };
  finalGroups.push(embyGroup);

  const adkillGroup = { name: "ADBLOCK", ...urlSelectDefaults, proxies: ["REJECT", PROXYName, "DIRECT"], icon: "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/icon/qure/color/Advertising.png" };


  finalGroups.push(...otherConditionalGroups);
  finalGroups.push(adkillGroup);

  config['proxy-groups'] = finalGroups;

  let telegramGroup = PROXYName;

  if (createdGroupNames.includes("JP")) {
    telegramGroup = "JP";
  } else if (createdGroupNames.includes("SG")) {
    telegramGroup = "SG";
  } else if (createdGroupNames.includes("HK")) {
    telegramGroup = "HK";
  }

  const allRules = [
    'RULE-SET,private_ip,DIRECT,no-resolve',
    'OR,((RULE-SET,private),(RULE-SET,googlefcm),(DOMAIN-KEYWORD,cauenvao)),DIRECT',
    'RULE-SET,adblock,ADBLOCK',
    `OR,((RULE-SET,telegram_ip),(RULE-SET,telegram),(RULE-SET,openai),(RULE-SET,Gemini)),${telegramGroup}`,
    'OR,((DOMAIN-KEYWORD,emby),(RULE-SET,emby_ip),(RULE-SET,emby)),EMBY',
    `OR,((RULE-SET,youtube),(RULE-SET,cloudflare_ip),(RULE-SET,google_ip),(RULE-SET,cloudflare),(RULE-SET,google)),${PROXYName}`,
    'OR,((RULE-SET,cn_ip),(RULE-SET,cn)),DIRECT',
    `MATCH,${PROXYName}`
  ];

  config.rules = allRules;

  return config;
}