/// 工具函数集合

/// 判断是否为网络地址
bool isNetworkUrl(String url) {
  return url.startsWith('http://') || url.startsWith('https://');
}
