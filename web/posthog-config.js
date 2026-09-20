// 部署配置：只放可以公开的项目采集 token，不要写任何管理密钥或 Netlify 凭证。
// 这份文件会随 export/web 一起上传；export/web/* 已被 .gitignore 排除，
// 填好的线上副本不会进仓库。
//
// host：PostHog 项目所在区域的 ingest 域名，例如
//   美国区 https://us.i.posthog.com
//   欧盟区 https://eu.i.posthog.com
// apiKey：项目设置里的 Project API Key（phc_ 开头）。
//
// apiKey 留空时统计整体静默停用，游戏照常运行，不会报错、不会阻塞启动。
window.CLUCK_POSTHOG = {
  host: "https://us.i.posthog.com",
  apiKey: "",
  // 内部调试流量标记。建议内部测试另开一个 PostHog project；
  // 若必须共用，把这里设为 true，事件会带 test_env=true 以便在报表里排除。
  debug: false,
};
